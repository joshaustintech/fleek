require_relative "analysis_runner"

# Compares the first structural grouping slice with locked Flay output.
class DuplicationProcess
  # Describes one source invocation and its optional Fleek arguments.
  Input = Struct.new(:path, :tool, :option)

  def self.run(input)
    tool = input.tool
    path = input.path
    return run_fleek(path, input.option) if tool == "fleek"
    run_flay(path)
  end

  def self.run_fleek(path, option)
    process_id = if option.empty?
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", path, out: "/tmp/fleek-duplication-out", err: "/tmp/fleek-duplication-err")
                 else
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", option, path, out: "/tmp/fleek-duplication-out", err: "/tmp/fleek-duplication-err")
                 end
    AnalysisRunner.observe(process_id, "/tmp/fleek-duplication-out", "/tmp/fleek-duplication-err")
  end

  def self.run_flay(path)
    process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "flay", path, out: "/tmp/flay-duplication-out", err: "/tmp/flay-duplication-err")
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
similar_fields = similar[1].include?("mass=32 score=32") && similar[1].include?("Total duplication score: 32")
similar_state = similar[1].include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded") && similar[1].include?("Status: findings")
DuplicationProcess.verify(similar[0] == 2 && similar_group && similar_locations && similar_fields && similar_state && similar[2].empty?, "similar method group report differed")

different_path = "test/fixtures/duplication_different_shapes.rb"
different = DuplicationProcess.run(DuplicationProcess::Input.new(different_path, "fleek", ""))
different_reference = DuplicationProcess.run(DuplicationProcess::Input.new(different_path, "flay", ""))
different_reports_clean = different[0] == 0 && different[1].include?("Total duplication score: 0") && different[1].include?("Status: complete")
different_reference_clean = different_reference[0] == 0 && different_reference[1].include?("Total score (lower is better) = 0")
DuplicationProcess.verify(different_reports_clean && different_reference_clean, "different method shapes were grouped")

identical_path = "test/fixtures/duplication_identical.rb"
identical = DuplicationProcess.run(DuplicationProcess::Input.new(identical_path, "fleek", ""))
identical_reference = DuplicationProcess.run(DuplicationProcess::Input.new(identical_path, "flay", ""))
identical_reference_weighted = identical_reference[1].include?("IDENTICAL code found in :defn (mass*2 = 64)") && identical_reference[1].include?("Total score (lower is better) = 64")
identical_fields = ["kind=\"identical\"", "mass=64 score=64", "Total duplication score: 64"]
identical_report_weighted = identical_fields.all? { |field| identical[1].include?(field) }
DuplicationProcess.verify(identical[0] == 2 && identical_reference_weighted && identical_report_weighted, "identical group multiplier changed")

unsupported_path = "test/fixtures/duplication_unsupported.rb"
unsupported = DuplicationProcess.run(DuplicationProcess::Input.new(unsupported_path, "fleek", ""))
unsupported_state = unsupported[1].include?("Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded") && unsupported[1].include?("Status: incomplete")
DuplicationProcess.verify(unsupported[0] == 1 && unsupported_state && unsupported[2].include?("unsupported Flay candidate syntax"), "unsupported syntax implied complete analysis")

fuzzy = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "fleek", "--fuzzy"))
DuplicationProcess.verify(fuzzy[0] == 1 && fuzzy[2].include?("Unsupported Flay option: \"--fuzzy\""), "unsupported fuzzy request was accepted")

puts "Duplication contract: pass"
