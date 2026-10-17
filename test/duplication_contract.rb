require_relative "analysis_runner"

# Compares the first structural grouping slice with locked Flay output.
class DuplicationProcess
  # Describes one source invocation and its optional Fleek arguments.
  Input = Struct.new(:path, :tool, :option, :value)
  # Describes the expected output status and required fields.
  OutputExpectation = Struct.new(:status, :fields, :message)
  # Carries scalar paired CLI/reference expectations for class-method fixtures.
  ClassMethodExpectation = Struct.new(:kind, :score, :mass, :second_line, :reference_group, :message, :first_line)
  CLASS_METHOD_EXPECTATIONS = {
    rails_pair: ClassMethodExpectation.new("similar", 48, 48, 9, "Similar code found in :defn (mass = 48)", "Rails-shaped class method parity differed"),
    module_methods: ClassMethodExpectation.new("similar", 48, 48, 9, "Similar code found in :defn (mass = 48)", "module method parity differed"),
    required_parameters: ClassMethodExpectation.new("similar", 48, 48, 8, "Similar code found in :defn (mass = 48)", "required-parameter class method parity differed"),
    optional_parameters: ClassMethodExpectation.new("similar", 52, 52, 9, "Similar code found in :defn (mass = 52)", "optional-parameter class method parity differed"),
    optional_parameter_defaults: ClassMethodExpectation.new("similar", 52, 52, 9, "Similar code found in :defn (mass = 52)", "optional-parameter default parity differed"),
    optional_literal_defaults: ClassMethodExpectation.new("similar", 40, 40, 8, "Similar code found in :defn (mass = 40)", "optional literal default parity differed"),
    parameter_arity: ClassMethodExpectation.new("similar", 48, 48, 9, "Similar code found in :defn (mass = 48)", "parameter-arity class method parity differed"),
    parameter_names: ClassMethodExpectation.new("similar", 48, 48, 9, "Similar code found in :defn (mass = 48)", "parameter-name class method parity differed"),
    conditionals: ClassMethodExpectation.new("similar", 62, 62, 14, "Similar code found in :defn (mass = 62)", "conditional class method parity differed"),
    unless_branches: ClassMethodExpectation.new("similar", 62, 62, 14, "Similar code found in :defn (mass = 62)", "unless class method parity differed"),
    conditional_return: ClassMethodExpectation.new("similar", 44, 44, 10, "Similar code found in :defn (mass = 44)", "conditional return class method parity differed"),
    or_expression: ClassMethodExpectation.new("similar", 34, 34, 12, "Similar code found in :defn (mass = 34)", "class-method OR expression parity differed"),
    local_writes: ClassMethodExpectation.new("similar", 38, 38, 10, "Similar code found in :defn (mass = 38)", "local-write class method parity differed"),
    local_write_names: ClassMethodExpectation.new("similar", 42, 42, 20, "Similar code found in :defn (mass = 42)", "local-write identity parity differed"),
    candidate_capacity: ClassMethodExpectation.new("similar", 62, 62, 31, "Similar code found in :defn (mass = 62)", "class-method candidate capacity parity differed", 19),
    identical: ClassMethodExpectation.new("identical", 64, 32, 19, "IDENTICAL code found in :defn (mass*2 = 64)", "identical class method group changed")
  }

  def self.run(input)
    path, tool, option, value = input.to_a
    return run_fleek(path, option, value) if tool == "fleek"
    return run_flay_with_mass(path, value) if option == "--mass"
    run_flay(path)
  end

  def self.run_fleek(path, option, value)
    process_id = if option.empty?
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", path, out: "/tmp/fleek-duplication-out", err: "/tmp/fleek-duplication-err")
                 elsif option == "--mass"
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", value.to_s, path, out: "/tmp/fleek-duplication-out", err: "/tmp/fleek-duplication-err")
                 else
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", option, path, out: "/tmp/fleek-duplication-out", err: "/tmp/fleek-duplication-err")
                 end
    AnalysisRunner.observe(process_id, "/tmp/fleek-duplication-out", "/tmp/fleek-duplication-err")
  end

  def self.run_flay(path)
    bundle = ENV["BUNDLE"] || "bundle"
    process_id = Process.spawn(bundle, "exec", "flay", path, out: "/tmp/flay-duplication-out", err: "/tmp/flay-duplication-err")
    AnalysisRunner.observe(process_id, "/tmp/flay-duplication-out", "/tmp/flay-duplication-err")
  end

  def self.run_flay_with_mass(path, mass)
    bundle = ENV["BUNDLE"] || "bundle"
    process_id = Process.spawn(bundle, "exec", "flay", "--mass", mass.to_s, path, out: "/tmp/flay-duplication-out", err: "/tmp/flay-duplication-err")
    AnalysisRunner.observe(process_id, "/tmp/flay-duplication-out", "/tmp/flay-duplication-err")
  end

  def self.run_fleek_pair(first, second)
    run_fleek_sources(first, second, "")
  end

  def self.run_fleek_sources(first, second, third)
    process_id = if third.empty?
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", first, second, out: "/tmp/fleek-duplication-out", err: "/tmp/fleek-duplication-err")
                 else
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", first, second, third, out: "/tmp/fleek-duplication-out", err: "/tmp/fleek-duplication-err")
                 end
    AnalysisRunner.observe(process_id, "/tmp/fleek-duplication-out", "/tmp/fleek-duplication-err")
  end

  def self.run_flay_pair(first, second)
    bundle = ENV["BUNDLE"] || "bundle"
    process_id = Process.spawn(bundle, "exec", "flay", first, second, out: "/tmp/flay-duplication-out", err: "/tmp/flay-duplication-err")
    AnalysisRunner.observe(process_id, "/tmp/flay-duplication-out", "/tmp/flay-duplication-err")
  end

  def self.run_fleek_pair_with_missing(first, second, missing)
    run_fleek_sources(first, second, missing)
  end

  def self.run_fleek_with_nested(first, second, nested)
    run_fleek_sources(first, second, nested)
  end

  # :reek:ControlParameter
  def self.verify(condition, message)
    raise message unless condition
  end

  def self.includes_all?(output, fields)
    fields.all? { |field| output.include?(field) }
  end

  def self.verify_output(observation, expectation)
    message = expectation.message
    verify(observation[0] == expectation.status, "#{message}: exit status differed")
    expectation.fields.each { |field| verify(observation[1].include?(field), "#{message}: missing #{field}") }
  end

  def self.verify_class_method_pair(path, second_line, description)
    actual = run(Input.new(path, "fleek", ""))
    reference = run(Input.new(path, "flay", ""))
    verify_output(reference, OutputExpectation.new(0, ["Similar code found in :defn (mass = 32)", "#{path}:2", "#{path}:#{second_line}"], "#{description} Flay reference changed"))
    verify_output(actual, OutputExpectation.new(2, ["Status: findings", "#{path}:2,#{path}:#{second_line}", "mass=32 score=32"], "#{description} candidates were not analyzed"))
  end

  def self.class_method_actual_expectation(path, expectation)
    kind = expectation.kind
    score = expectation.score
    mass = expectation.mass
    line = expectation.second_line
    OutputExpectation.new(2, ["kind=\"#{kind}\"", "locations=\"#{path}:#{expectation.first_line || 2},#{path}:#{line}\"", "mass=#{mass} score=#{score}", "direct methods in one simple module", "literal-default optional positional parameters", "bounded if/else/unless branches", "boolean OR expressions", "return statements with supported values", "local-variable assignments", "Total duplication score: #{score}"], expectation.message)
  end

  def self.class_method_reference_expectation(path, expectation)
    line = expectation.second_line
    score = expectation.score
    fields = [expectation.reference_group, "#{path}:#{expectation.first_line || 2}", "#{path}:#{line}", "Total score (lower is better) = #{score}"]
    OutputExpectation.new(0, fields, expectation.message)
  end

  def self.verify_class_method_parity(path, expectation_name)
    expectation = CLASS_METHOD_EXPECTATIONS.fetch(expectation_name)
    actual = run(Input.new(path, "fleek", ""))
    reference = run(Input.new(path, "flay", ""))
    verify_output(actual, class_method_actual_expectation(path, expectation))
    verify_output(reference, class_method_reference_expectation(path, expectation))
  end

  def self.verify_class_method_no_group(path, description = "optional-parameter count mismatch was grouped")
    actual = run(Input.new(path, "fleek", ""))
    reference = run(Input.new(path, "flay", ""))
    verify_output(actual, OutputExpectation.new(0, ["Total duplication score: 0", "Status: complete"], description))
    verify_output(reference, OutputExpectation.new(0, ["Total score (lower is better) = 0"], "Flay grouped mismatched optional-parameter counts"))
  end
end

similar_path = "test/fixtures/duplication_methods.rb"
similar = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "fleek", ""))
reference = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "flay", ""))
reference_group = reference[1].include?("Similar code found in :defn (mass = 32)")
reference_locations = reference[1].include?("#{similar_path}:1") && reference[1].include?("#{similar_path}:18")
DuplicationProcess.verify(reference[0] == 0, "reference exit differed: #{reference[0]}")
DuplicationProcess.verify(reference_group && reference_locations && reference[1].include?("Total score (lower is better) = 32"), "reference did not select the expected similar method group")
similar_group = similar[1].include?("Group: check=\"flay:StructuralDuplication\" node=\"defn\" kind=\"similar\"")
similar_locations = similar[1].include?("locations=\"#{similar_path}:1,#{similar_path}:18\"")
similar_fields = similar[1].include?("mass=32 score=32") && similar[1].include?("Total duplication score: 32") && similar[1].include?("File duplication score: \"#{similar_path}\" score=32")
similar_state = similar[1].include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded") && similar[1].include?("Status: findings")
DuplicationProcess.verify(similar[0] == 2 && similar_group && similar_locations && similar_fields && similar_state && similar[2].empty?, "similar method group report differed")

different_path = "test/fixtures/duplication_different_shapes.rb"
different = DuplicationProcess.run(DuplicationProcess::Input.new(different_path, "fleek", ""))
different_reference = DuplicationProcess.run(DuplicationProcess::Input.new(different_path, "flay", ""))
different_reports_clean = different[0] == 0 && different[1].include?("Total duplication score: 0") && different[1].include?("File duplication score: \"#{different_path}\" score=0") && different[1].include?("Status: complete")
different_reference_clean = different_reference[0] == 0 && different_reference[1].include?("Total score (lower is better) = 0")
DuplicationProcess.verify(different_reports_clean && different_reference_clean, "different method shapes were grouped")

identical_path = "test/fixtures/duplication_identical.rb"
identical = DuplicationProcess.run(DuplicationProcess::Input.new(identical_path, "fleek", ""))
identical_reference = DuplicationProcess.run(DuplicationProcess::Input.new(identical_path, "flay", ""))
identical_reference_weighted = identical_reference[1].include?("IDENTICAL code found in :defn (mass*2 = 64)") && identical_reference[1].include?("Total score (lower is better) = 64")
identical_fields = ["kind=\"identical\"", "mass=32 score=64", "Total duplication score: 64", "File duplication score: \"#{identical_path}\" score=64"]
identical_report_weighted = identical_fields.all? { |field| identical[1].include?(field) }
DuplicationProcess.verify(identical[0] == 2 && identical_reference_weighted && identical_report_weighted, "identical group multiplier changed")

unsupported_path = "test/fixtures/duplication_unsupported.rb"
unsupported = DuplicationProcess.run(DuplicationProcess::Input.new(unsupported_path, "fleek", ""))
unsupported_state = unsupported[1].include?("Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded") && unsupported[1].include?("Status: incomplete")
DuplicationProcess.verify(unsupported[0] == 1 && unsupported_state && unsupported[2].include?("Partial results may omit Flay candidates"), "unsupported syntax implied complete analysis")

fuzzy = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "fleek", "--fuzzy"))
DuplicationProcess.verify(fuzzy[0] == 1 && fuzzy[2].include?("Unsupported Flay option: \"--fuzzy\""), "unsupported fuzzy request was accepted")

[[15, 2, 32], [16, 2, 32], [17, 0, 0]].each do |threshold, expected_status, expected_score|
  actual = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "fleek", "--mass", threshold))
  reference = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "flay", "--mass", threshold))
  actual_matches = actual[0] == expected_status && actual[1].include?("Total duplication score: #{expected_score}") && actual[1].include?("File duplication score: \"#{similar_path}\" score=#{expected_score}")
  reference_matches = reference[1].include?("Total score (lower is better) = #{expected_score}")
  DuplicationProcess.verify(actual_matches && reference_matches, "mass threshold #{threshold} differed")
end

invalid_mass_values = [nil, "0", "1", "2", "-1", "abc", "2147483648"]
invalid_mass_values.each do |value|
  invalid_mass = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "fleek", "--mass", value))
  DuplicationProcess.verify(invalid_mass[0] == 1 && invalid_mass[2].include?("--mass requires an integer from 3 through 2147483647"), "invalid mass setting was accepted: #{value}")
end

first_file = "test/fixtures/duplication_file_a.rb"
second_file = "test/fixtures/duplication_file_b.rb"
cross_file = DuplicationProcess.run_fleek_pair(second_file, first_file)
cross_reference = DuplicationProcess.run_flay_pair(second_file, first_file)
cross_locations = "locations=\"#{first_file}:1,#{second_file}:1\""
cross_reference_locations = ["#{first_file}:1", "#{second_file}:1"]
cross_reference_matches = cross_reference_locations.all? { |location| cross_reference[1].include?(location) } && cross_reference[1].index(cross_reference_locations[0]) < cross_reference[1].index(cross_reference_locations[1])
cross_file_matches = cross_file[0] == 2 && DuplicationProcess.includes_all?(cross_file[1], [cross_locations, "kind=\"identical\"", "Total duplication score: 64", "File duplication score: \"#{first_file}\" score=32", "File duplication score: \"#{second_file}\" score=32"])
DuplicationProcess.verify(cross_file_matches, "cross-file report differed")
DuplicationProcess.verify(cross_reference_matches && cross_file[1].include?(cross_locations), "cross-file locations or ordering differed from Flay")
cross_reference_expectation = DuplicationProcess::OutputExpectation.new(0, ["IDENTICAL code found in :defn (mass*2 = 64)", "Total score (lower is better) = 64"], "cross-file reference differed from Flay")
DuplicationProcess.verify_output(cross_reference, cross_reference_expectation)

partial = DuplicationProcess.run_fleek_pair_with_missing(first_file, second_file, "test/fixtures/missing_duplication.rb")
partial_report = partial[0] == 1 && DuplicationProcess.includes_all?(partial[1], [cross_locations, "test/fixtures/missing_duplication.rb\" scope=failed", "Coverage: 3 selected; 2 analyzed; 1 failed; 0 excluded", "Status: incomplete"])
DuplicationProcess.verify(partial_report, "failed requested file hid remaining cross-file group")

nested_path = "test/fixtures/duplication_nested_scope.rb"
nested = DuplicationProcess.run_fleek_with_nested(first_file, second_file, nested_path)
nested_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_path, "flay", ""))
nested_reference_expectation = DuplicationProcess::OutputExpectation.new(0, ["Similar code found in :defn (mass = 32)", "#{nested_path}:2", "#{nested_path}:19", "Total score (lower is better) = 32"], "nested Flay reference changed")
DuplicationProcess.verify_output(nested_reference, nested_reference_expectation)
nested_fleek_expectation = DuplicationProcess::OutputExpectation.new(1, ["Status: incomplete"], "nested Flay candidates were silently omitted")
DuplicationProcess.verify_output(nested, nested_fleek_expectation)
DuplicationProcess.verify(nested[2].include?("unsupported Flay candidate syntax"), "nested Flay candidates were silently omitted")

class_methods_path = "test/fixtures/duplication_class_methods.rb"
class_methods_with_helper_path = "test/fixtures/duplication_class_methods_with_helper.rb"

rails_pair_path = "test/fixtures/duplication_class_methods_rails_pair.rb"
DuplicationProcess.verify_class_method_parity(rails_pair_path, :rails_pair)

multiple_classes_path = "test/fixtures/duplication_class_methods_across_classes.rb"
multiple_classes_actual = DuplicationProcess.run(DuplicationProcess::Input.new(multiple_classes_path, "fleek", ""))
multiple_classes_reference = DuplicationProcess.run(DuplicationProcess::Input.new(multiple_classes_path, "flay", ""))
multiple_classes_fields = ["kind=\"similar\"", "locations=\"#{multiple_classes_path}:8,#{multiple_classes_path}:17\"", "mass=48 score=48", "Total duplication score: 48", "Status: findings"]
DuplicationProcess.verify_output(multiple_classes_actual, DuplicationProcess::OutputExpectation.new(2, multiple_classes_fields, "class methods across classes were not compared"))
multiple_classes_reference_fields = ["Similar code found in :defn (mass = 48)", "#{multiple_classes_path}:8", "#{multiple_classes_path}:17", "Total score (lower is better) = 48"]
DuplicationProcess.verify_output(multiple_classes_reference, DuplicationProcess::OutputExpectation.new(0, multiple_classes_reference_fields, "Flay class-method group across classes changed"))

cross_class_group_path = "test/fixtures/duplication_class_methods_cross_class_group.rb"
cross_class_group_actual = DuplicationProcess.run(DuplicationProcess::Input.new(cross_class_group_path, "fleek", ""))
cross_class_group_reference = DuplicationProcess.run(DuplicationProcess::Input.new(cross_class_group_path, "flay", ""))
cross_class_group_reference_fields = ["Similar code found in :class (mass = 50)", "#{cross_class_group_path}:1", "#{cross_class_group_path}:10", "Total score (lower is better) = 50"]
DuplicationProcess.verify_output(cross_class_group_reference, DuplicationProcess::OutputExpectation.new(0, cross_class_group_reference_fields, "cross-class Flay group changed"))
cross_class_group_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{cross_class_group_path}:1,#{cross_class_group_path}:10\" mass=50 score=50", "Total duplication score: 50", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(cross_class_group_actual, DuplicationProcess::OutputExpectation.new(2, cross_class_group_actual_fields, "cross-class Flay group differed"))

cross_scope_group_path = "test/fixtures/duplication_class_cross_scope_group.rb"
cross_scope_group_actual = DuplicationProcess.run(DuplicationProcess::Input.new(cross_scope_group_path, "fleek", ""))
cross_scope_group_reference = DuplicationProcess.run(DuplicationProcess::Input.new(cross_scope_group_path, "flay", ""))
cross_scope_group_fields = ["node=\"class\" kind=\"similar\" locations=\"#{cross_scope_group_path}:1,#{cross_scope_group_path}:11\" mass=50 score=50", "Total duplication score: 50", "Status: findings"]
DuplicationProcess.verify_output(cross_scope_group_actual, DuplicationProcess::OutputExpectation.new(2, cross_scope_group_fields, "nested cross-scope class group differed"))
cross_scope_group_reference_fields = ["Similar code found in :class (mass = 50)", "#{cross_scope_group_path}:1", "#{cross_scope_group_path}:11", "Total score (lower is better) = 50"]
DuplicationProcess.verify_output(cross_scope_group_reference, DuplicationProcess::OutputExpectation.new(0, cross_scope_group_reference_fields, "nested cross-scope Flay group changed"))

multi_method_group_path = "test/fixtures/duplication_class_multi_method_group.rb"
multi_method_group_actual = DuplicationProcess.run(DuplicationProcess::Input.new(multi_method_group_path, "fleek", ""))
multi_method_group_reference = DuplicationProcess.run(DuplicationProcess::Input.new(multi_method_group_path, "flay", ""))
multi_method_group_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{multi_method_group_path}:1,#{multi_method_group_path}:15\" mass=62 score=62", "Total duplication score: 62", "Status: findings"]
DuplicationProcess.verify_output(multi_method_group_actual, DuplicationProcess::OutputExpectation.new(2, multi_method_group_actual_fields, "multi-method Flay class group differed"))
multi_method_group_reference_fields = ["Similar code found in :class (mass = 62)", "#{multi_method_group_path}:1", "#{multi_method_group_path}:15", "Total score (lower is better) = 62"]
DuplicationProcess.verify_output(multi_method_group_reference, DuplicationProcess::OutputExpectation.new(0, multi_method_group_reference_fields, "multi-method Flay class group changed"))

multi_method_module_path = "test/fixtures/duplication_module_multi_method_group.rb"
multi_method_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(multi_method_module_path, "fleek", ""))
multi_method_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(multi_method_module_path, "flay", ""))
multi_method_module_actual_fields = ["node=\"module\" kind=\"similar\" locations=\"#{multi_method_module_path}:1,#{multi_method_module_path}:15\" mass=62 score=62", "Total duplication score: 62", "Status: findings"]
DuplicationProcess.verify_output(multi_method_module_actual, DuplicationProcess::OutputExpectation.new(2, multi_method_module_actual_fields, "multi-method Flay module group differed"))
multi_method_module_reference_fields = ["Similar code found in :module (mass = 62)", "#{multi_method_module_path}:1", "#{multi_method_module_path}:15", "Total score (lower is better) = 62"]
DuplicationProcess.verify_output(multi_method_module_reference, DuplicationProcess::OutputExpectation.new(0, multi_method_module_reference_fields, "multi-method Flay module group changed"))

nested_module_path = "test/fixtures/duplication_nested_module_group.rb"
nested_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nested_module_path, "fleek", ""))
nested_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_module_path, "flay", ""))
nested_module_actual_fields = ["node=\"module\" kind=\"similar\" locations=\"#{nested_module_path}:1,#{nested_module_path}:11\" mass=34 score=34", "Total duplication score: 34", "Status: findings"]
DuplicationProcess.verify_output(nested_module_actual, DuplicationProcess::OutputExpectation.new(2, nested_module_actual_fields, "nested Flay module group differed"))
nested_module_reference_fields = ["Similar code found in :module (mass = 34)", "#{nested_module_path}:1", "#{nested_module_path}:11", "Total score (lower is better) = 34"]
DuplicationProcess.verify_output(nested_module_reference, DuplicationProcess::OutputExpectation.new(0, nested_module_reference_fields, "nested Flay module group changed"))

deep_nested_module_path = "test/fixtures/duplication_deep_nested_module_group.rb"
deep_nested_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(deep_nested_module_path, "fleek", ""))
deep_nested_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(deep_nested_module_path, "flay", ""))
deep_nested_module_actual_fields = ["node=\"module\" kind=\"similar\" locations=\"#{deep_nested_module_path}:1,#{deep_nested_module_path}:13\" mass=36 score=36", "Total duplication score: 36", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(deep_nested_module_actual, DuplicationProcess::OutputExpectation.new(2, deep_nested_module_actual_fields, "deep nested Flay module candidates differed"))
deep_nested_module_reference_fields = ["Similar code found in :module (mass = 36)", "#{deep_nested_module_path}:1", "#{deep_nested_module_path}:13", "Total score (lower is better) = 36"]
DuplicationProcess.verify_output(deep_nested_module_reference, DuplicationProcess::OutputExpectation.new(0, deep_nested_module_reference_fields, "deep nested Flay module group changed"))

eight_level_module_path = "test/fixtures/duplication_eight_level_module_group.rb"
eight_level_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(eight_level_module_path, "fleek", ""))
eight_level_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(eight_level_module_path, "flay", ""))
eight_level_module_fields = ["node=\"module\" kind=\"similar\" locations=\"#{eight_level_module_path}:1,#{eight_level_module_path}:23\" mass=46 score=46", "Total duplication score: 46", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(eight_level_module_actual, DuplicationProcess::OutputExpectation.new(2, eight_level_module_fields, "eight-level Flay module candidates differed"))
eight_level_module_reference_fields = ["Similar code found in :module (mass = 46)", "#{eight_level_module_path}:1", "#{eight_level_module_path}:23", "Total score (lower is better) = 46"]
DuplicationProcess.verify_output(eight_level_module_reference, DuplicationProcess::OutputExpectation.new(0, eight_level_module_reference_fields, "eight-level Flay module group changed"))

nine_level_module_path = "test/fixtures/duplication_nine_level_module_boundary.rb"
nine_level_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nine_level_module_path, "fleek", ""))
nine_level_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nine_level_module_path, "flay", ""))
nine_level_module_fields = ["node=\"module\" kind=\"similar\" locations=\"#{nine_level_module_path}:1,#{nine_level_module_path}:25\" mass=48 score=48", "Total duplication score: 48", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nine_level_module_actual, DuplicationProcess::OutputExpectation.new(2, nine_level_module_fields, "nine-level Flay module candidates differed"))
nine_level_module_reference_fields = ["Similar code found in :module (mass = 48)", "#{nine_level_module_path}:1", "#{nine_level_module_path}:25", "Total score (lower is better) = 48"]
DuplicationProcess.verify_output(nine_level_module_reference, DuplicationProcess::OutputExpectation.new(0, nine_level_module_reference_fields, "ninth-level Flay module group changed"))

ten_level_module_path = "test/fixtures/duplication_ten_level_module_boundary.rb"
ten_level_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(ten_level_module_path, "fleek", ""))
ten_level_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(ten_level_module_path, "flay", ""))
ten_level_module_fields = ["scope=partial", "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"]
DuplicationProcess.verify_output(ten_level_module_actual, DuplicationProcess::OutputExpectation.new(1, ten_level_module_fields, "ten-level nested module boundary was treated as complete"))
ten_level_module_reference_fields = ["Similar code found in :module (mass = 50)", "#{ten_level_module_path}:1", "#{ten_level_module_path}:27", "Total score (lower is better) = 50"]
DuplicationProcess.verify_output(ten_level_module_reference, DuplicationProcess::OutputExpectation.new(0, ten_level_module_reference_fields, "ten-level Flay module group changed"))

nested_namespace_class_path = "test/fixtures/duplication_nested_namespace_class_group.rb"
nested_namespace_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nested_namespace_class_path, "fleek", ""))
nested_namespace_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_namespace_class_path, "flay", ""))
nested_namespace_class_fields = ["node=\"module\" kind=\"similar\" locations=\"#{nested_namespace_class_path}:1,#{nested_namespace_class_path}:14\" mass=54 score=54", "Total duplication score: 54", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nested_namespace_class_actual, DuplicationProcess::OutputExpectation.new(2, nested_namespace_class_fields, "nested-namespace class group differed"))
nested_namespace_class_reference_fields = ["Similar code found in :module (mass = 54)", "#{nested_namespace_class_path}:1", "#{nested_namespace_class_path}:14", "Total score (lower is better) = 54"]
DuplicationProcess.verify_output(nested_namespace_class_reference, DuplicationProcess::OutputExpectation.new(0, nested_namespace_class_reference_fields, "nested-namespace class Flay group changed"))

nested_class_path = "test/fixtures/duplication_nested_class_group.rb"
nested_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nested_class_path, "fleek", ""))
nested_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_class_path, "flay", ""))
nested_class_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{nested_class_path}:1,#{nested_class_path}:12\" mass=52 score=52", "Total duplication score: 52", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nested_class_actual, DuplicationProcess::OutputExpectation.new(2, nested_class_actual_fields, "nested-class group was not analyzed"))
nested_class_reference_fields = ["Similar code found in :class (mass = 52)", "#{nested_class_path}:1", "#{nested_class_path}:12", "Total score (lower is better) = 52"]
DuplicationProcess.verify_output(nested_class_reference, DuplicationProcess::OutputExpectation.new(0, nested_class_reference_fields, "nested-class Flay group changed"))

deep_nested_class_path = "test/fixtures/duplication_deep_nested_class_boundary.rb"
deep_nested_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(deep_nested_class_path, "fleek", ""))
deep_nested_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(deep_nested_class_path, "flay", ""))
deep_nested_class_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{deep_nested_class_path}:1,#{deep_nested_class_path}:14\" mass=54 score=54", "Total duplication score: 54", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(deep_nested_class_actual, DuplicationProcess::OutputExpectation.new(2, deep_nested_class_actual_fields, "three-level nested-class group was not analyzed"))
deep_nested_class_reference_fields = ["Similar code found in :class (mass = 54)", "#{deep_nested_class_path}:1", "#{deep_nested_class_path}:14", "Total score (lower is better) = 54"]
DuplicationProcess.verify_output(deep_nested_class_reference, DuplicationProcess::OutputExpectation.new(0, deep_nested_class_reference_fields, "deep nested-class Flay group changed"))

deeper_nested_class_path = "test/fixtures/duplication_deeper_nested_class_boundary.rb"
deeper_nested_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(deeper_nested_class_path, "fleek", ""))
deeper_nested_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(deeper_nested_class_path, "flay", ""))
deeper_nested_class_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{deeper_nested_class_path}:1,#{deeper_nested_class_path}:16\" mass=56 score=56", "Total duplication score: 56", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(deeper_nested_class_actual, DuplicationProcess::OutputExpectation.new(2, deeper_nested_class_actual_fields, "four-level nested-class group differed"))
deeper_nested_class_reference_fields = ["Similar code found in :class (mass = 56)", "#{deeper_nested_class_path}:1", "#{deeper_nested_class_path}:16", "Total score (lower is better) = 56"]
DuplicationProcess.verify_output(deeper_nested_class_reference, DuplicationProcess::OutputExpectation.new(0, deeper_nested_class_reference_fields, "four-level nested-class Flay group changed"))

five_level_nested_class_path = "test/fixtures/duplication_five_level_nested_class_boundary.rb"
five_level_nested_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(five_level_nested_class_path, "fleek", ""))
five_level_nested_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(five_level_nested_class_path, "flay", ""))
five_level_nested_class_actual_fields = ["scope=partial", "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"]
DuplicationProcess.verify_output(five_level_nested_class_actual, DuplicationProcess::OutputExpectation.new(1, five_level_nested_class_actual_fields, "five-level nested-class boundary was treated as complete"))
five_level_nested_class_reference_fields = ["Similar code found in :class (mass = 58)", "#{five_level_nested_class_path}:1", "#{five_level_nested_class_path}:18", "Total score (lower is better) = 58"]
DuplicationProcess.verify_output(five_level_nested_class_reference, DuplicationProcess::OutputExpectation.new(0, five_level_nested_class_reference_fields, "five-level nested-class Flay group changed"))

nested_class_siblings_path = "test/fixtures/duplication_nested_class_siblings.rb"
nested_class_siblings_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nested_class_siblings_path, "fleek", ""))
nested_class_siblings_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_class_siblings_path, "flay", ""))
nested_class_siblings_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{nested_class_siblings_path}:1,#{nested_class_siblings_path}:23\" mass=104 score=104", "Total duplication score: 104", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nested_class_siblings_actual, DuplicationProcess::OutputExpectation.new(2, nested_class_siblings_actual_fields, "nested-class siblings group differed"))
nested_class_siblings_reference_fields = ["Similar code found in :class (mass = 104)", "#{nested_class_siblings_path}:1", "#{nested_class_siblings_path}:23", "Total score (lower is better) = 104"]
DuplicationProcess.verify_output(nested_class_siblings_reference, DuplicationProcess::OutputExpectation.new(0, nested_class_siblings_reference_fields, "nested-class siblings Flay group changed"))

nested_sibling_methods_path = "test/fixtures/duplication_nested_class_sibling_methods.rb"
nested_sibling_methods_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nested_sibling_methods_path, "fleek", ""))
nested_sibling_methods_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_sibling_methods_path, "flay", ""))
nested_sibling_methods_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{nested_sibling_methods_path}:1,#{nested_sibling_methods_path}:29\" mass=118 score=118", "Total duplication score: 118", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nested_sibling_methods_actual, DuplicationProcess::OutputExpectation.new(2, nested_sibling_methods_actual_fields, "multi-method nested class siblings group differed"))
nested_sibling_methods_reference_fields = ["Similar code found in :class (mass = 118)", "#{nested_sibling_methods_path}:1", "#{nested_sibling_methods_path}:29", "Total score (lower is better) = 118"]
DuplicationProcess.verify_output(nested_sibling_methods_reference, DuplicationProcess::OutputExpectation.new(0, nested_sibling_methods_reference_fields, "multi-method nested class siblings Flay group changed"))

nested_wrapped_siblings_path = "test/fixtures/duplication_nested_wrapped_class_siblings.rb"
nested_wrapped_siblings_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nested_wrapped_siblings_path, "fleek", ""))
nested_wrapped_siblings_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_wrapped_siblings_path, "flay", ""))
nested_wrapped_siblings_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{nested_wrapped_siblings_path}:1,#{nested_wrapped_siblings_path}:35\" mass=158 score=158", "Total duplication score: 158", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nested_wrapped_siblings_actual, DuplicationProcess::OutputExpectation.new(2, nested_wrapped_siblings_actual_fields, "nested wrapped class siblings group differed"))
nested_wrapped_siblings_reference_fields = ["Similar code found in :class (mass = 158)", "#{nested_wrapped_siblings_path}:1", "#{nested_wrapped_siblings_path}:35", "Total score (lower is better) = 158"]
DuplicationProcess.verify_output(nested_wrapped_siblings_reference, DuplicationProcess::OutputExpectation.new(0, nested_wrapped_siblings_reference_fields, "nested wrapped class siblings Flay group changed"))

qualified_namespace_class_path = "test/fixtures/duplication_qualified_namespace_class_group.rb"
qualified_namespace_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_class_path, "fleek", ""))
qualified_namespace_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_class_path, "flay", ""))
qualified_namespace_class_fields = ["node=\"module\" kind=\"similar\" locations=\"#{qualified_namespace_class_path}:1,#{qualified_namespace_class_path}:12\" mass=56 score=56", "Total duplication score: 56", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(qualified_namespace_class_actual, DuplicationProcess::OutputExpectation.new(2, qualified_namespace_class_fields, "qualified-namespace class group differed"))
qualified_namespace_class_reference_fields = ["Similar code found in :module (mass = 56)", "#{qualified_namespace_class_path}:1", "#{qualified_namespace_class_path}:12", "Total score (lower is better) = 56"]
DuplicationProcess.verify_output(qualified_namespace_class_reference, DuplicationProcess::OutputExpectation.new(0, qualified_namespace_class_reference_fields, "qualified-namespace class Flay group changed"))

qualified_namespace_multiple_classes_path = "test/fixtures/duplication_qualified_namespace_multiple_classes.rb"
qualified_namespace_multiple_classes_actual = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_multiple_classes_path, "fleek", ""))
qualified_namespace_multiple_classes_reference = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_multiple_classes_path, "flay", ""))
qualified_namespace_multiple_classes_fields = ["node=\"module\" kind=\"similar\" locations=\"#{qualified_namespace_multiple_classes_path}:1,#{qualified_namespace_multiple_classes_path}:21\" mass=106 score=106", "Total duplication score: 106", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(qualified_namespace_multiple_classes_actual, DuplicationProcess::OutputExpectation.new(2, qualified_namespace_multiple_classes_fields, "multiple qualified-namespace class group differed"))
qualified_namespace_multiple_classes_reference_fields = ["Similar code found in :module (mass = 106)", "#{qualified_namespace_multiple_classes_path}:1", "#{qualified_namespace_multiple_classes_path}:21", "Total score (lower is better) = 106"]
DuplicationProcess.verify_output(qualified_namespace_multiple_classes_reference, DuplicationProcess::OutputExpectation.new(0, qualified_namespace_multiple_classes_reference_fields, "multiple qualified-namespace class Flay group changed"))

qualified_namespace_multi_method_path = "test/fixtures/duplication_qualified_namespace_multi_method_class_boundary.rb"
qualified_namespace_multi_method_actual = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_multi_method_path, "fleek", ""))
qualified_namespace_multi_method_reference = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_multi_method_path, "flay", ""))
qualified_namespace_multi_method_fields = ["node=\"module\" kind=\"similar\" locations=\"#{qualified_namespace_multi_method_path}:1,#{qualified_namespace_multi_method_path}:19\" mass=104 score=104", "Total duplication score: 104", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(qualified_namespace_multi_method_actual, DuplicationProcess::OutputExpectation.new(2, qualified_namespace_multi_method_fields, "multi-method qualified class group differed"))
qualified_namespace_multi_method_reference_fields = ["Similar code found in :module (mass = 104)", "#{qualified_namespace_multi_method_path}:1", "#{qualified_namespace_multi_method_path}:19", "Total score (lower is better) = 104"]
DuplicationProcess.verify_output(qualified_namespace_multi_method_reference, DuplicationProcess::OutputExpectation.new(0, qualified_namespace_multi_method_reference_fields, "multi-method qualified-class Flay group changed"))

qualified_namespace_multiple_multi_method_path = "test/fixtures/duplication_qualified_namespace_multiple_multi_method_classes.rb"
qualified_namespace_multiple_multi_method_actual = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_multiple_multi_method_path, "fleek", ""))
qualified_namespace_multiple_multi_method_reference = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_multiple_multi_method_path, "flay", ""))
qualified_namespace_multiple_multi_method_fields = ["node=\"module\" kind=\"similar\" locations=\"#{qualified_namespace_multiple_multi_method_path}:1,#{qualified_namespace_multiple_multi_method_path}:23\" mass=42 score=42", "Total duplication score: 42", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(qualified_namespace_multiple_multi_method_actual, DuplicationProcess::OutputExpectation.new(2, qualified_namespace_multiple_multi_method_fields, "multiple multi-method qualified classes group differed"))
qualified_namespace_multiple_multi_method_reference_fields = ["Similar code found in :module (mass = 42)", "#{qualified_namespace_multiple_multi_method_path}:1", "#{qualified_namespace_multiple_multi_method_path}:23", "Total score (lower is better) = 42"]
DuplicationProcess.verify_output(qualified_namespace_multiple_multi_method_reference, DuplicationProcess::OutputExpectation.new(0, qualified_namespace_multiple_multi_method_reference_fields, "multiple multi-method qualified classes Flay group changed"))

qualified_namespace_depth_path = "test/fixtures/duplication_qualified_namespace_depth_boundary.rb"
qualified_namespace_depth_actual = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_depth_path, "fleek", ""))
qualified_namespace_depth_reference = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_depth_path, "flay", ""))
qualified_namespace_depth_fields = ["Group: check=\"flay:StructuralDuplication\" node=\"module\" kind=\"similar\" locations=\"#{qualified_namespace_depth_path}:1,#{qualified_namespace_depth_path}:12\" mass=66 score=66", "Total duplication score: 66", "scope=partial", "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"]
DuplicationProcess.verify_output(qualified_namespace_depth_actual, DuplicationProcess::OutputExpectation.new(1, qualified_namespace_depth_fields, "qualified-namespace depth boundary differed"))
qualified_namespace_depth_reference_fields = "Similar code found in :module (mass = 68)|#{qualified_namespace_depth_path}:23|#{qualified_namespace_depth_path}:34|Similar code found in :module (mass = 66)|#{qualified_namespace_depth_path}:1|#{qualified_namespace_depth_path}:12|Total score (lower is better) = 134".split("|")
DuplicationProcess.verify_output(qualified_namespace_depth_reference, DuplicationProcess::OutputExpectation.new(0, qualified_namespace_depth_reference_fields, "qualified-namespace depth Flay groups changed"))

clean_scope_path = "test/fixtures/duplication_class_scopes_clean.rb"
clean_scope_actual = DuplicationProcess.run(DuplicationProcess::Input.new(clean_scope_path, "fleek", ""))
clean_scope_reference = DuplicationProcess.run(DuplicationProcess::Input.new(clean_scope_path, "flay", ""))
clean_scope_fields = ["Total duplication score: 0", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: complete"]
DuplicationProcess.verify_output(clean_scope_actual, DuplicationProcess::OutputExpectation.new(0, clean_scope_fields, "clean nested scope candidate parity differed"))
DuplicationProcess.verify_output(clean_scope_reference, DuplicationProcess::OutputExpectation.new(0, ["Total score (lower is better) = 0"], "clean nested scope Flay reference changed"))

module_group_path = "test/fixtures/duplication_module_group.rb"
module_group_actual = DuplicationProcess.run(DuplicationProcess::Input.new(module_group_path, "fleek", ""))
module_group_reference = DuplicationProcess.run(DuplicationProcess::Input.new(module_group_path, "flay", ""))
module_group_actual_fields = ["node=\"module\" kind=\"similar\" locations=\"#{module_group_path}:1,#{module_group_path}:20\" mass=34 score=34", "Total duplication score: 34", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(module_group_actual, DuplicationProcess::OutputExpectation.new(2, module_group_actual_fields, "cross-module Flay group differed"))
module_group_reference_fields = ["Similar code found in :module (mass = 34)", "#{module_group_path}:1", "#{module_group_path}:20", "Total score (lower is better) = 34"]
DuplicationProcess.verify_output(module_group_reference, DuplicationProcess::OutputExpectation.new(0, module_group_reference_fields, "Flay cross-module group changed"))

module_identical_path = "test/fixtures/duplication_module_identical_group.rb"
module_identical_actual = DuplicationProcess.run(DuplicationProcess::Input.new(module_identical_path, "fleek", ""))
module_identical_reference = DuplicationProcess.run(DuplicationProcess::Input.new(module_identical_path, "flay", ""))
module_identical_fields = ["node=\"module\" kind=\"identical\" locations=\"#{module_identical_path}:1,#{module_identical_path}:20\" mass=34 score=68", "Total duplication score: 68", "Status: findings"]
DuplicationProcess.verify_output(module_identical_actual, DuplicationProcess::OutputExpectation.new(2, module_identical_fields, "identical Flay module group differed"))
module_identical_reference_fields = ["IDENTICAL code found in :module (mass*2 = 68)", "#{module_identical_path}:1", "#{module_identical_path}:20", "Total score (lower is better) = 68"]
DuplicationProcess.verify_output(module_identical_reference, DuplicationProcess::OutputExpectation.new(0, module_identical_reference_fields, "Flay identical module group changed"))

namespace_class_path = "test/fixtures/duplication_class_methods_namespace.rb"
namespace_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(namespace_class_path, "fleek", ""))
namespace_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(namespace_class_path, "flay", ""))
namespace_class_actual_fields = ["kind=\"similar\"", "locations=\"#{namespace_class_path}:3,#{namespace_class_path}:10\"", "mass=48 score=48", "Total duplication score: 48", "Status: findings"]
DuplicationProcess.verify_output(namespace_class_actual, DuplicationProcess::OutputExpectation.new(2, namespace_class_actual_fields, "simple namespace class methods were not analyzed"))
namespace_class_reference_fields = ["Similar code found in :defn (mass = 48)", "#{namespace_class_path}:3", "#{namespace_class_path}:10", "Total score (lower is better) = 48"]
DuplicationProcess.verify_output(namespace_class_reference, DuplicationProcess::OutputExpectation.new(0, namespace_class_reference_fields, "Flay namespace class-method group changed"))

empty_namespace_path = "test/fixtures/duplication_empty_namespace_classes.rb"
empty_namespace_actual = DuplicationProcess.run(DuplicationProcess::Input.new(empty_namespace_path, "fleek", ""))
empty_namespace_reference = DuplicationProcess.run(DuplicationProcess::Input.new(empty_namespace_path, "flay", ""))
DuplicationProcess.verify_output(empty_namespace_actual, DuplicationProcess::OutputExpectation.new(0, ["Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Total duplication score: 0", "Status: complete"], "empty namespaced classes were not analyzed cleanly"))
DuplicationProcess.verify_output(empty_namespace_reference, DuplicationProcess::OutputExpectation.new(0, ["Total score (lower is better) = 0"], "Flay empty namespaced classes changed"))

empty_module_path = "test/fixtures/duplication_empty_module.rb"
empty_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(empty_module_path, "fleek", ""))
empty_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(empty_module_path, "flay", ""))
DuplicationProcess.verify_output(empty_module_actual, DuplicationProcess::OutputExpectation.new(0, ["Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Total duplication score: 0", "Status: complete"], "empty modules were not analyzed cleanly"))
DuplicationProcess.verify_output(empty_module_reference, DuplicationProcess::OutputExpectation.new(0, ["Total score (lower is better) = 0"], "Flay empty module changed"))

partial_candidates_path = "test/fixtures/duplication_class_methods_partial_candidates.rb"
partial_candidates_actual = DuplicationProcess.run(DuplicationProcess::Input.new(partial_candidates_path, "fleek", ""))
partial_candidates_reference = DuplicationProcess.run(DuplicationProcess::Input.new(partial_candidates_path, "flay", ""))
partial_candidates_fields = ["kind=\"similar\"", "locations=\"#{partial_candidates_path}:4,#{partial_candidates_path}:15\"", "mass=48 score=48", "Total duplication score: 48", "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"]
DuplicationProcess.verify_output(partial_candidates_actual, DuplicationProcess::OutputExpectation.new(1, partial_candidates_fields, "supported class methods were hidden by unsupported callbacks"))
partial_candidates_reference_fields = ["Similar code found in :defn (mass = 48)", "#{partial_candidates_path}:4", "#{partial_candidates_path}:15", "Total score (lower is better) = 48"]
DuplicationProcess.verify_output(partial_candidates_reference, DuplicationProcess::OutputExpectation.new(0, partial_candidates_reference_fields, "Flay class methods with callbacks changed"))

partial_rails_path = "test/fixtures/duplication_class_methods_partial_rails.rb"
partial_rails_actual = DuplicationProcess.run(DuplicationProcess::Input.new(partial_rails_path, "fleek", ""))
partial_rails_reference = DuplicationProcess.run(DuplicationProcess::Input.new(partial_rails_path, "flay", ""))
partial_rails_expected = ["#{partial_rails_path}\" scope=partial", "locations=\"#{partial_rails_path}:4,#{partial_rails_path}:11\"", "mass=48 score=48", "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"]
DuplicationProcess.verify_output(partial_rails_actual, DuplicationProcess::OutputExpectation.new(1, partial_rails_expected, "partial Rails class results were hidden or reported complete"))
DuplicationProcess.verify(partial_rails_actual[2].include?("Partial results may omit Flay candidates"), "partial Rails class results were not labeled")
DuplicationProcess.verify_output(partial_rails_reference, DuplicationProcess::OutputExpectation.new(0, ["Similar code found in :defn (mass = 48)", "#{partial_rails_path}:4", "#{partial_rails_path}:11"], "partial Rails Flay reference changed"))

rails_corpus_root = ENV["FLEEK_RAILS_CORPUS"]
if ENV["FLEEK_REQUIRE_RAILS_CORPUS"] == "1" && (!rails_corpus_root || rails_corpus_root.empty?)
  raise "FLEEK_RAILS_CORPUS is required for the pinned Rails controller contract"
end
if rails_corpus_root && !rails_corpus_root.empty?
  rails_controller_path = File.join(rails_corpus_root, "app/controllers/users_controller.rb")
  raise "pinned Rails UsersController is missing: #{rails_controller_path}" unless File.file?(rails_controller_path)
  rails_revision_process = Process.spawn("git", "-C", rails_corpus_root, "rev-parse", "HEAD", out: "/tmp/fleek-rails-revision-out", err: "/tmp/fleek-rails-revision-err")
  rails_revision = AnalysisRunner.observe(rails_revision_process, "/tmp/fleek-rails-revision-out", "/tmp/fleek-rails-revision-err")
  expected_rails_revision = "92ce7c470bc31952d7dc51cac15e577a948e479e"
  unless rails_revision[0] == 0 && rails_revision[1].strip == expected_rails_revision
    raise "pinned Rails corpus revision differed from #{expected_rails_revision}"
  end
  rails_file_process = Process.spawn("git", "-C", rails_corpus_root, "diff", "--quiet", expected_rails_revision, "--", "app/controllers/users_controller.rb", out: "/tmp/fleek-rails-file-out", err: "/tmp/fleek-rails-file-err")
  rails_file = AnalysisRunner.observe(rails_file_process, "/tmp/fleek-rails-file-out", "/tmp/fleek-rails-file-err")
  raise "pinned Rails UsersController has local modifications" unless rails_file[0] == 0
  rails_actual = DuplicationProcess.run(DuplicationProcess::Input.new(rails_controller_path, "fleek", ""))
  rails_reference = DuplicationProcess.run(DuplicationProcess::Input.new(rails_controller_path, "flay", ""))
  rails_fields = ["scope=partial", "locations=\"#{rails_controller_path}:51,#{rails_controller_path}:58\"", "mass=48 score=48", "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"]
  DuplicationProcess.verify_output(rails_actual, DuplicationProcess::OutputExpectation.new(1, rails_fields, "pinned Rails controller Flay group or incomplete status differed"))
  DuplicationProcess.verify(rails_actual[2].include?("Partial results may omit Flay candidates"), "pinned Rails controller partial warning missing")
  rails_reference_fields = ["Similar code found in :defn (mass = 48)", "#{rails_controller_path}:51", "#{rails_controller_path}:58", "Total score (lower is better) = 48"]
  DuplicationProcess.verify_output(rails_reference, DuplicationProcess::OutputExpectation.new(0, rails_reference_fields, "pinned Rails Flay reference changed"))
end

DuplicationProcess.verify_class_method_pair(class_methods_path, 19, "class method")
DuplicationProcess.verify_class_method_pair(class_methods_with_helper_path, 19, "class helper")
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_required_parameters.rb", :required_parameters)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_parameter_arity.rb", :parameter_arity)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_parameter_names.rb", :parameter_names)
optional_parameters_path = "test/fixtures/duplication_class_methods_optional_parameters.rb"
DuplicationProcess.verify_class_method_parity(optional_parameters_path, :optional_parameters)
optional_defaults_path = "test/fixtures/duplication_class_methods_optional_parameter_defaults.rb"
DuplicationProcess.verify_class_method_parity(optional_defaults_path, :optional_parameter_defaults)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_optional_literal_defaults.rb", :optional_literal_defaults)
DuplicationProcess.verify_class_method_no_group("test/fixtures/duplication_class_methods_optional_parameter_counts.rb")
DuplicationProcess.verify_class_method_no_group("test/fixtures/duplication_class_methods_optional_parameter_count_candidates.rb")
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_module_methods.rb", :module_methods)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_conditionals.rb", :conditionals)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_unless.rb", :unless_branches)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_conditional_return.rb", :conditional_return)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_or.rb", :or_expression)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_local_writes.rb", :local_writes)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_local_write_names.rb", :local_write_names)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_candidate_capacity.rb", :candidate_capacity)

class_group_with_pair_path = "test/fixtures/duplication_class_methods_class_group_with_conditional_pair.rb"
class_group_with_pair_actual = DuplicationProcess.run(DuplicationProcess::Input.new(class_group_with_pair_path, "fleek", ""))
class_group_with_pair_reference = DuplicationProcess.run(DuplicationProcess::Input.new(class_group_with_pair_path, "flay", ""))
class_group_with_pair_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{class_group_with_pair_path}:20,#{class_group_with_pair_path}:32\" mass=62 score=62", "node=\"class\" kind=\"similar\" locations=\"#{class_group_with_pair_path}:1,#{class_group_with_pair_path}:10\" mass=50 score=50", "Total duplication score: 112", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(class_group_with_pair_actual, DuplicationProcess::OutputExpectation.new(2, class_group_with_pair_fields, "Flay class and independent method groups differed"))
class_method_group_position = class_group_with_pair_actual[1].index("node=\"defn\"")
class_group_position = class_group_with_pair_actual[1].index("node=\"class\"")
DuplicationProcess.verify(class_method_group_position < class_group_position, "Flay group ordering differed")
class_group_with_pair_reference_fields = ["Similar code found in :defn (mass = 62)", "#{class_group_with_pair_path}:20", "#{class_group_with_pair_path}:32", "Similar code found in :class (mass = 50)", "#{class_group_with_pair_path}:1", "#{class_group_with_pair_path}:10", "Total score (lower is better) = 112"]
DuplicationProcess.verify_output(class_group_with_pair_reference, DuplicationProcess::OutputExpectation.new(0, class_group_with_pair_reference_fields, "Flay groups with conditional class-method candidates changed"))

topology_path = "test/fixtures/duplication_class_methods_topology.rb"
DuplicationProcess.verify_class_method_no_group(topology_path, "different class method tree topology was grouped")

partial_path = "test/fixtures/duplication_class_methods_partial_match.rb"
partial_actual = DuplicationProcess.run(DuplicationProcess::Input.new(partial_path, "fleek", ""))
partial_reference = DuplicationProcess.run(DuplicationProcess::Input.new(partial_path, "flay", ""))
DuplicationProcess.verify_output(partial_actual, DuplicationProcess::OutputExpectation.new(1, ["Status: incomplete"], "partial class-method duplicate was silently skipped"))
DuplicationProcess.verify(partial_actual[2].include?("unsupported Flay candidate syntax"), "partial class-method duplicate was silently skipped")
partial_reference_fields = ["IDENTICAL code found in :call (mass*2 = 64)", "#{partial_path}:4", "#{partial_path}:9", "Total score (lower is better) = 64"]
DuplicationProcess.verify_output(partial_reference, DuplicationProcess::OutputExpectation.new(0, partial_reference_fields, "partial Flay group changed"))

class_identical_path = "test/fixtures/duplication_class_methods_identical.rb"
DuplicationProcess.verify_class_method_parity(class_identical_path, :identical)

ambiguous_class_methods = DuplicationProcess.run(DuplicationProcess::Input.new("test/fixtures/duplication_class_methods_ambiguous.rb", "fleek", ""))
ambiguous_class_methods_path = "test/fixtures/duplication_class_methods_ambiguous.rb"
ambiguous_class_methods_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{ambiguous_class_methods_path}:2,#{ambiguous_class_methods_path}:19,#{ambiguous_class_methods_path}:36\" mass=48 score=48", "Total duplication score: 48", "File duplication score: \"#{ambiguous_class_methods_path}\" score=48", "Status: findings"]
DuplicationProcess.verify_output(ambiguous_class_methods, DuplicationProcess::OutputExpectation.new(2, ambiguous_class_methods_fields, "multiple Flay method candidates were not grouped"))

puts "Duplication contract: pass"
