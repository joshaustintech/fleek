require_relative "analysis_runner"

# Compares the first structural grouping slice with locked Flay output.
class DuplicationProcess
  # Describes one source invocation and its optional Fleek arguments.
  Input = Struct.new(:path, :tool, :option, :value)
  # Describes the expected output status and required fields.
  OutputExpectation = Struct.new(:status, :fields, :message)

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
    verify(observation[0] == expectation.status, message)
    expectation.fields.each { |field| verify(observation[1].include?(field), message) }
  end

  def self.verify_class_method_pair(path, second_line, description)
    actual = run(Input.new(path, "fleek", ""))
    reference = run(Input.new(path, "flay", ""))
    verify_output(reference, OutputExpectation.new(0, ["Similar code found in :defn (mass = 32)", "#{path}:2", "#{path}:#{second_line}"], "#{description} Flay reference changed"))
    verify_output(actual, OutputExpectation.new(2, ["Status: findings", "#{path}:2,#{path}:#{second_line}", "mass=32 score=32"], "#{description} candidates were not analyzed"))
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
DuplicationProcess.verify(unsupported[0] == 1 && unsupported_state && unsupported[2].include?("unsupported Flay candidate syntax"), "unsupported syntax implied complete analysis")

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
DuplicationProcess.verify_class_method_pair(class_methods_path, 19, "class method")
DuplicationProcess.verify_class_method_pair(class_methods_with_helper_path, 19, "class helper")

ambiguous_class_methods = DuplicationProcess.run(DuplicationProcess::Input.new("test/fixtures/duplication_class_methods_ambiguous.rb", "fleek", ""))
DuplicationProcess.verify_output(ambiguous_class_methods, DuplicationProcess::OutputExpectation.new(1, ["Status: incomplete"], "ambiguous class method groups were reported as complete"))

puts "Duplication contract: pass"
