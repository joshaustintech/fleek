require_relative "analysis_runner"

# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:LongParameterList
# :reek:TooManyStatements
# Checks public Fleek output against Flay for composed block groups.
class SimilarComposedBlockContract
  # Holds one generated pair and its expected duplication kind.
  Case = Struct.new(:name, :first_parameters, :second_parameters, :first_block_parameter, :second_block_parameter, :kind)
  CASES = [
    Case.new("renamed-default", "(required, optional = 1, *rest, mode:, strict: false, **options, &callback)",
      "(source, fallback = 3, *tail, state:, safe: true, **settings, &handler)", "value", "item", "similar"),
    Case.new("identical", "(required, optional = 1, *rest, mode:, strict: false, **options, &callback)",
      "(source, fallback = 3, *tail, state:, safe: true, **settings, &handler)", "value", "value", "identical")
  ].freeze

  def self.verify
    root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
    CASES.each { |item| verify_case(root, item) }
  end

  # :reek:TooManyStatements
  def self.verify_case(root, item)
    path = "#{root}/fleek-similar-composed-block-#{item.name}-#{Process.pid}.rb"
    actual_output = "#{path}.actual.out"
    actual_error = "#{path}.actual.err"
    reference_output = "#{path}.reference.out"
    reference_error = "#{path}.reference.err"
    File.write(path, source(item))
    actual_process = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", "3", path,
      out: actual_output, err: actual_error)
    reference_process = Process.spawn(ENV.fetch("BUNDLE", "bundle"), "exec", "flay", "--mass", "3", path,
      out: reference_output, err: reference_error)
    actual_status = run(actual_process)
    reference_status = run(reference_process)
    actual = File.read(actual_output)
    reference = File.read(reference_output)
    actual_err = File.read(actual_error)
    reference_err = File.read(reference_error)
    verify_streams(item, actual_err, reference_err)
    verify_reference(item, reference_status, reference)
    verify_parity(item, actual_status, actual, reference)
  ensure
    AnalysisRunner.cleanup_contract_outputs([path, actual_error, reference_output, reference_error], actual_output)
  end

  def self.source(item)
    if item.kind == "identical"
      first = "items.map do |value, entry = 2|\n    process(value, entry)\n  end\n  finish(:first)"
      second = "items.map do |value, entry = 2|\n    process(value, entry)\n  end\n  finish(:second)\n  complete"
      return "def transform#{item.first_parameters}\n  #{first}\nend\n\ndef transform#{item.second_parameters}\n  #{second}\nend\n"
    end

    left = "rows.map do |#{item.first_block_parameter}, fallback = 2|\n    callback.call(process(#{item.first_block_parameter}, optional))\n  end"
    right = "records.map do |#{item.second_block_parameter}, alternate = 4|\n    handler.call(process(#{item.second_block_parameter}, fallback))\n  end"
    "def transform#{item.first_parameters}\n  #{left}\nend\n\ndef transform#{item.second_parameters}\n  #{right}\nend\n"
  end

  def self.run(process_id)
    _, status = Process.waitpid2(process_id)
    status.exitstatus
  end

  def self.verify_streams(item, actual_error, reference_error)
    unless actual_error.empty? && reference_error.empty?
      raise "#{item.name} wrote to stderr: #{actual_error} #{reference_error}"
    end
  end

  def self.verify_reference(item, status, output)
    unless status == 0 && output.include?("code found in :iter")
      raise "Flay #{item.name} block group missing: #{output}"
    end
  end

  def self.verify_parity(item, status, actual, reference)
    reference_group = reference.lines.find { |line| line.include?("code found in :iter") }
    kind = reference_group.include?("IDENTICAL") ? "identical" : "similar"
    reported_mass = reference_group[/mass(?:\*2)? = (\d+)/, 1].to_i
    mass = reference_group.include?("mass*2") ? reported_mass / 2 : reported_mass
    score = reference[/Total score \(lower is better\) = (\d+)/, 1].to_i
    expected_status = 2
    actual_group = actual.lines.find { |line| line.include?('node="iter"') }
    unless status == expected_status && actual_group && kind == item.kind && actual_group.include?("kind=\"#{kind}\"") &&
        actual_group[/ mass=(\d+)/, 1].to_i == mass &&
        actual_group[/ score=(\d+)/, 1].to_i == score && actual.match?(/^Total duplication score: #{score}$/)
      raise "Fleek #{item.name} block group differed: expected #{item.kind} mass=#{mass}; #{actual}; Flay: #{reference}"
    end
    raise "Fleek #{item.name} coverage incomplete: #{actual}" unless actual.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
    reference_locations = reference.lines.drop_while { |line| !line.include?("code found in :iter") }.drop(1).take_while { |line| line.match?(/\.rb:\d+/) }.map { |line| line[/\.rb:\d+/] }
    actual_locations = actual_group[/locations=\"([^\"]+)/, 1].split(",").map { |location| location[/\.rb:\d+/] }
    raise "Fleek #{item.name} locations differed: #{actual_group}; Flay locations: #{reference_locations}" unless actual_locations == reference_locations
  end
end

SimilarComposedBlockContract.verify
