require_relative "analysis_runner"

# Public Flay parity contracts for composed candidates split across source files.
# :reek:IrresponsibleModule
class ComposedCrossFileContract
  ROOT = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
  TOP_FILES = [
    "test/fixtures/duplication_composed_cross_file_top_a.rb",
    "test/fixtures/duplication_composed_cross_file_top_b.rb"
  ]
  CLASS_FILES = [
    "test/fixtures/duplication_composed_cross_file_class_a.rb",
    "test/fixtures/duplication_composed_cross_file_class_b.rb"
  ]
  UNSUPPORTED_CLASS_FILES = [
    "test/fixtures/duplication_composed_cross_file_class_unsupported.rb",
    "test/fixtures/duplication_composed_cross_file_class_b.rb"
  ]

  # :reek:TooManyStatements
  def self.verify
    top_first = TOP_FILES[0]
    top_second = TOP_FILES[1]
    class_first = CLASS_FILES[0]
    class_second = CLASS_FILES[1]
    verify_case(TOP_FILES, "top", [
      "Group: check=\"flay:StructuralDuplication\" node=\"ensure\" kind=\"identical\" locations=\"#{top_first}:3,#{top_second}:3\" mass=32 score=64"
    ], expected_flay_record("IDENTICAL code found in :ensure (mass*2 = 64)", "#{top_first}:3", "#{top_second}:3"))
    verify_case(CLASS_FILES, "class", [
      "Group: check=\"flay:StructuralDuplication\" node=\"defn\" kind=\"similar\" locations=\"#{class_first}:2,#{class_second}:2\" mass=32 score=32",
      "Group: check=\"flay:StructuralDuplication\" node=\"defn\" kind=\"identical\" locations=\"#{class_first}:12,#{class_second}:12\" mass=6 score=12"
    ], expected_flay_record("Similar code found in :defn (mass = 32)", "#{class_first}:2", "#{class_second}:2") + "\n--group--\n" +
      expected_flay_record("IDENTICAL code found in :defn (mass*2 = 12)", "#{class_first}:12", "#{class_second}:12"))
    verify_same_file_pair_with_unrelated_source
    verify_unsupported_sibling
    puts "Composed cross-file contract: pass"
  end

  # :reek:LongParameterList
  # :reek:NestedIterators
  # :reek:TooManyStatements
  # :reek:ControlParameter
  def self.verify_case(paths, label, native_fields, expected_reference_groups)
    [paths, paths.reverse].each_with_index do |ordered_paths, order|
      [false, true].each do |liberal|
        suffix = "#{liberal ? 'liberal' : 'default'}-order-#{order}"
        actual_output = "#{ROOT}/composed-cross-file-#{label}-#{suffix}-actual.out"
        actual_error = "#{ROOT}/composed-cross-file-#{label}-#{suffix}-actual.err"
        reference_output = "#{ROOT}/composed-cross-file-#{label}-#{suffix}-reference.out"
        reference_error = "#{ROOT}/composed-cross-file-#{label}-#{suffix}-reference.err"
        actual_status = run_tool("fleek", ordered_paths, liberal, actual_output, actual_error)
        reference_status = run_tool("flay", ordered_paths, liberal, reference_output, reference_error)
        actual = File.read(actual_output)
        actual_diagnostic = File.read(actual_error)
        reference = File.read(reference_output)
        reference_diagnostic = File.read(reference_error)
        native_groups = actual.lines.grep(/  Group:/).map(&:strip)
        reference_groups = normalized_flay_groups(reference)
        expected_coverage = "Coverage: 2 selected; 2 analyzed; 0 failed; 0 excluded"
        expected_status = "Status: findings"
        raise "#{label} #{suffix} result differed: #{actual} #{actual_diagnostic}" unless actual_status == 2 &&
          native_groups == native_fields && actual.include?(expected_coverage) && actual.include?(expected_status) && actual_diagnostic.empty?
        raise "#{label} #{suffix} Flay reference differed: #{reference} #{reference_diagnostic}" unless reference_status.zero? &&
          expected_reference_groups == reference_groups && reference_diagnostic.empty?
        AnalysisRunner.cleanup_contract_outputs([actual_error, reference_output, reference_error], actual_output)
      end
    end
  end

  def self.expected_flay_record(header, first_location, second_location)
    "#{header}\n#{first_location}\n#{second_location}"
  end

  # :reek:TooManyStatements
  def self.normalized_flay_groups(output)
    groups = []
    output.lines.each do |line|
      if line.match?(/\A\d+\)/)
        groups << [line.sub(/\A\d+\) /, "").strip]
      elsif line.match?(/\A  [^ ]/)
        groups.last << line.strip if groups.any?
      end
    end
    groups.map { |group| group.join("\n") }.join("\n--group--\n")
  end

  # :reek:TooManyStatements
  def self.verify_same_file_pair_with_unrelated_source
    paths = ["test/fixtures/duplication_composed_exception_regexp_identical.rb",
      "test/fixtures/duplication_composed_cross_file_unrelated.rb"]
    actual_output = "#{ROOT}/composed-cross-file-same-file-actual.out"
    actual_error = "#{ROOT}/composed-cross-file-same-file-actual.err"
    reference_output = "#{ROOT}/composed-cross-file-same-file-reference.out"
    reference_error = "#{ROOT}/composed-cross-file-same-file-reference.err"
    actual_status = run_tool("fleek", paths, false, actual_output, actual_error)
    reference_status = run_tool("flay", paths, false, reference_output, reference_error)
    actual = File.read(actual_output)
    reference = File.read(reference_output)
    actual_diagnostic = File.read(actual_error)
    reference_diagnostic = File.read(reference_error)
    native_groups = actual.lines.grep(/  Group:/).map(&:strip)
    reference_groups = normalized_flay_groups(reference)
    expected_native = ["Group: check=\"flay:StructuralDuplication\" node=\"defn\" kind=\"identical\" locations=\"test/fixtures/duplication_composed_exception_regexp_identical.rb:1,test/fixtures/duplication_composed_exception_regexp_identical.rb:11\" mass=36 score=72"]
    raise "same-file pruning changed in a multi-file run: #{actual}" unless actual_status == 2 &&
      native_groups == expected_native && actual_diagnostic.empty?
    expected_reference = expected_flay_record("IDENTICAL code found in :defn (mass*2 = 72)",
      "test/fixtures/duplication_composed_exception_regexp_identical.rb:1",
      "test/fixtures/duplication_composed_exception_regexp_identical.rb:11")
    raise "same-file Flay reference changed: #{reference}" unless reference_status.zero? &&
      reference_groups == expected_reference && reference_diagnostic.empty?
  ensure
    AnalysisRunner.cleanup_contract_outputs([actual_error, reference_output, reference_error], actual_output)
  end

  # :reek:TooManyStatements
  def self.verify_unsupported_sibling
    paths = UNSUPPORTED_CLASS_FILES
    ordered_paths = paths.sort
    first_path = ordered_paths[0]
    second_path = ordered_paths[1]
    actual_output = "#{ROOT}/composed-cross-file-unsupported-actual.out"
    actual_error = "#{ROOT}/composed-cross-file-unsupported-actual.err"
    reference_output = "#{ROOT}/composed-cross-file-unsupported-reference.out"
    reference_error = "#{ROOT}/composed-cross-file-unsupported-reference.err"
    actual_status = run_tool("fleek", paths, false, actual_output, actual_error)
    reference_status = run_tool("flay", paths, false, reference_output, reference_error)
    actual = File.read(actual_output)
    diagnostic = File.read(actual_error)
    reference = File.read(reference_output)
    reference_diagnostic = File.read(reference_error)
    native_groups = actual.lines.grep(/  Group:/).map(&:strip)
    reference_groups = normalized_flay_groups(reference)
    fields = [
      "Group: check=\"flay:StructuralDuplication\" node=\"defn\" kind=\"similar\" locations=\"#{first_path}:2,#{second_path}:2\" mass=32 score=32",
      "Group: check=\"flay:StructuralDuplication\" node=\"defn\" kind=\"identical\" locations=\"#{first_path}:12,#{second_path}:12\" mass=6 score=12",
      "Coverage: 2 selected; 0 analyzed; 2 failed; 0 excluded", "Status: incomplete"
    ]
    reference_fields = "Similar code found in :defn (mass = 32)\n#{first_path}:2\n#{second_path}:2" +
      "\n--group--\nIDENTICAL code found in :defn (mass*2 = 12)\n#{first_path}:12\n#{second_path}:12"
    raise "unsupported sibling hid cross-file findings: #{actual} #{diagnostic}" unless actual_status == 1 &&
      native_groups == fields.take(2) && fields.drop(2).all? { |field| actual.include?(field) } && diagnostic.include?("Partial results") &&
      !actual.include?("Partial results")
    raise "unsupported sibling Flay reference changed: #{reference} #{reference_diagnostic}" unless reference_status.zero? &&
      reference_fields == reference_groups && reference_diagnostic.empty?
  ensure
    AnalysisRunner.cleanup_contract_outputs([actual_error, reference_output, reference_error], actual_output)
  end

  # :reek:ControlParameter
  # :reek:DuplicateMethodCall
  # :reek:LongParameterList
  # :reek:TooManyStatements
  def self.run_tool(tool, paths, liberal, output, error)
    first_path = paths[0]
    second_path = paths[1]
    process_id = if tool == "fleek" && liberal
      Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", "3", "--liberal", first_path, second_path, out: output, err: error)
    elsif tool == "fleek"
      Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", "3", first_path, second_path, out: output, err: error)
    elsif liberal
      Process.spawn("bundle", "exec", "flay", "--mass", "3", "--liberal", first_path, second_path, out: output, err: error)
    else
      Process.spawn("bundle", "exec", "flay", "--mass", "3", first_path, second_path, out: output, err: error)
    end
    _, status = Process.waitpid2(process_id)
    status.exitstatus
  end

end

ComposedCrossFileContract.verify
