# Compares one generated method pair with the compiled CLI and pinned Flay.
# :reek:RepeatedConditional
class DuplicationMethodPairContract
  # Values needed to generate two candidate methods.
  Input = Struct.new(:name, :left_body, :right_body, :parameters)
  # Captured output from one external analyzer process.
  ProcessResult = Struct.new(:status, :output, :error)
  # Input and both tool reports used by parity assertions.
  Comparison = Struct.new(:input, :path, :actual, :reference)

  # :reek:TooManyStatements
  def self.verify(input)
    comparison = run_pair(input)
    verify_reference(comparison)
    verify_status_and_group(comparison)
    verify_total_score(comparison)
    verify_coverage(comparison)
    remove_files(comparison.path)
  end

  # :reek:DuplicateMethodCall
  # :reek:TooManyStatements
  def self.run_pair(input)
    root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
    path = "#{root}/fleek-method-pair-#{input.name}.rb"
    comparison = Comparison.new(input, path, nil, nil)
    write_pair(comparison)
    comparison.actual = run(comparison.path, false)
    comparison.reference = run(comparison.path, true)
    comparison
  end

  def self.write_pair(comparison)
    input = comparison.input
    parameters = input.parameters
    source = "def transform#{parameters}\n  #{input.left_body}\nend\n\ndef transform#{parameters}\n  #{input.right_body}\nend\n"
    File.write(comparison.path, source)
  end

  # :reek:ControlParameter
  # :reek:TooManyStatements
  def self.run(path, reference)
    kind = reference ? "reference" : "actual"
    output = "#{path}.#{kind}.out"
    error = "#{path}.#{kind}.err"
    process_id = if reference
      Process.spawn("bundle", "exec", "flay", "--mass", "3", path, out: output, err: error)
    else
      Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", "3", path, out: output, err: error)
    end
    _, status = Process.waitpid2(process_id)
    ProcessResult.new(status.exitstatus, File.read(output), File.read(error))
  end

  def self.verify_reference(comparison)
    reference = comparison.reference
    raise "Flay #{comparison.input.name} reference failed: #{reference.output} #{reference.error}" unless reference.status == 0
  end

  # :reek:TooManyStatements
  def self.verify_status_and_group(comparison)
    actual = comparison.actual
    reference = comparison.reference
    reference_output = reference.output
    actual_output = actual.output
    reference_group = reference_output.lines.find { |line| line.include?("code found in :defn") }
    native_group = actual_output.lines.find { |line| line.include?('node="defn"') }
    verify_group_presence(comparison, native_group, reference_group)
    verify_group(comparison, native_group, reference_group) if reference_group
  end

  def self.verify_group_presence(comparison, native, reference)
    actual = comparison.actual
    expected_status = reference ? 2 : 0
    return if actual.status == expected_status && !!native == !!reference
    raise "Fleek #{comparison.input.name} status or grouping differed: #{actual.output} #{actual.error} / #{comparison.reference.output}"
  end

  def self.verify_group(comparison, native, reference)
    verify_kind(comparison, native, reference)
    verify_mass(comparison, native, reference)
    verify_group_score(comparison, native)
    verify_locations(comparison, native)
  end

  def self.verify_kind(comparison, native, reference)
    kind = reference.include?("IDENTICAL code") ? "identical" : "similar"
    raise "Fleek #{comparison.input.name} kind differed: #{native}" unless native.include?("kind=\"#{kind}\"")
  end

  def self.verify_mass(comparison, native, reference)
    mass = reference[/mass(?:\*2)? = (\d+)/, 1].to_i
    mass /= 2 if reference.include?("mass*2")
    raise "Fleek #{comparison.input.name} mass differed: #{native} / #{reference}" unless native[/ mass=(\d+)/, 1].to_i == mass
  end

  def self.verify_group_score(comparison, native)
    reference_score = comparison.reference.output[/Total score \(lower is better\) = (\d+)/, 1].to_i
    raise "Fleek #{comparison.input.name} score differed: #{native}" unless native[/ score=(\d+)/, 1].to_i == reference_score
  end

  def self.verify_locations(comparison, native)
    path = comparison.path
    expected = ["#{path}:1", "#{path}:5"].join(",")
    unless native.include?("locations=\"#{expected}\"") && native.index("#{path}:1") < native.index("#{path}:5")
      raise "Fleek #{comparison.input.name} locations differed: #{native}"
    end
  end

  def self.verify_total_score(comparison)
    actual_score = comparison.actual.output[/Total duplication score: (\d+)/, 1].to_i
    reference_score = comparison.reference.output[/Total score \(lower is better\) = (\d+)/, 1].to_i
    raise "Fleek #{comparison.input.name} total score differed" unless actual_score == reference_score
  end

  def self.verify_coverage(comparison)
    coverage = "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded"
    raise "Fleek #{comparison.input.name} coverage incomplete" unless comparison.actual.output.include?(coverage)
  end

  def self.remove_files(path)
    [path, "#{path}.actual.out", "#{path}.actual.err", "#{path}.reference.out", "#{path}.reference.err"].each do |file|
      File.delete(file) if File.exist?(file)
    end
  end
end
