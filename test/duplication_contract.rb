require_relative "analysis_runner"

# Compares the first structural grouping slice with locked Flay output.
class DuplicationProcess
  # Describes one source invocation and its optional Fleek arguments.
  Input = Struct.new(:path, :tool, :option, :value)

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

  # :reek:ControlParameter
  def self.verify(condition, message)
    raise message unless condition
  end
end

similar_path = "test/fixtures/duplication_methods.rb"
similar = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "fleek", ""))
reference = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "flay", ""))
reference_group = reference[1].include?("Similar code found in :defn (mass = 32)")
reference_locations = reference[1].include?("#{similar_path}:1") && reference[1].include?("#{similar_path}:18")
DuplicationProcess.verify(reference[0] == 0 && reference_group && reference_locations && reference[1].include?("Total score (lower is better) = 32"), "reference did not select the expected similar method group")
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
identical_fields = ["kind=\"identical\"", "mass=64 score=64", "Total duplication score: 64", "File duplication score: \"#{identical_path}\" score=64"]
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

puts "Duplication contract: pass"
