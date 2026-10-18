#: Flay and Reek findings describe deliberate CLI variation in this harness.
# :reek:BooleanParameter
# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:IrresponsibleModule
# :reek:TooManyStatements
class DuplicationOnlyNodeContract
  PATH = "test/fixtures/duplication_class_methods_class_group_with_conditional_pair.rb"
  BUNDLE = ENV["BUNDLE"] || "bundle"

  def self.run(tool, node, repeated = false)
    if tool == "flay"
      process_id = if repeated
                     Process.spawn(BUNDLE, "exec", "flay", "--only", "class", "--only", node, PATH, out: "/tmp/flay-only-node-out", err: "/tmp/flay-only-node-err")
                   else
                     Process.spawn(BUNDLE, "exec", "flay", "--only", node, PATH, out: "/tmp/flay-only-node-out", err: "/tmp/flay-only-node-err")
                   end
      return AnalysisRunner.observe(process_id, "/tmp/flay-only-node-out", "/tmp/flay-only-node-err")
    end
    process_id = if repeated
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--only", "class", "--only", node, PATH, out: "/tmp/fleek-only-node-out", err: "/tmp/fleek-only-node-err")
                 else
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--only", node, PATH, out: "/tmp/fleek-only-node-out", err: "/tmp/fleek-only-node-err")
                 end
    AnalysisRunner.observe(process_id, "/tmp/fleek-only-node-out", "/tmp/fleek-only-node-err")
  end
end

require_relative "analysis_runner"

class_group = DuplicationOnlyNodeContract.run("fleek", "class")
class_reference = DuplicationOnlyNodeContract.run("flay", "class")
AnalysisRunner.assert_report_contains(class_reference, [0,
  ["Total score (lower is better) = 112", "Similar code found in :class (mass = 50)"],
  "Flay --only class reference changed"])
raise "Flay --only class included method group" if class_reference[1].include?(":defn")
raise "--only class did not filter displayed Flay groups" unless class_group[0] == 2 && class_group[1].include?("node=\"class\" kind=\"similar\"") && !class_group[1].include?("node=\"defn\"")
raise "--only class did not preserve unfiltered total score" unless class_group[1].include?("Total duplication score: 112")
raise "--only class file score differed" unless class_group[1].include?("File duplication score: \"#{DuplicationOnlyNodeContract::PATH}\" score=50") && class_group[1].include?("Status: findings")

method_group = DuplicationOnlyNodeContract.run("fleek", "defn")
method_reference = DuplicationOnlyNodeContract.run("flay", "defn")
AnalysisRunner.assert_report_contains(method_reference, [0,
  ["Total score (lower is better) = 112", "Similar code found in :defn (mass = 62)"],
  "Flay --only defn reference changed"])
raise "--only defn did not filter displayed Flay groups" if method_group[0] != 2 || !method_group[1].include?("node=\"defn\" kind=\"similar\"") || method_group[1].include?("node=\"class\"")
raise "--only defn did not preserve unfiltered total score" unless method_group[1].include?("Total duplication score: 112")
raise "--only defn file score differed" unless method_group[1].include?("score=62") && method_group[1].include?("Status: findings")

no_match = DuplicationOnlyNodeContract.run("fleek", "call")
no_match_reference = DuplicationOnlyNodeContract.run("flay", "call")
AnalysisRunner.assert_report_contains(no_match_reference, [0,
  ["Total score (lower is better) = 112"], "Flay --only call reference changed"])
raise "Flay --only call reference showed group" if no_match_reference[1].include?("code found")
AnalysisRunner.assert_report_contains(no_match, [0,
  ["Total duplication score: 112", "score=0", "Status: complete"],
  "--only unmatched node did not produce clean filtered results"])
raise "--only unmatched node retained group" if no_match[1].include?("Group:")

repeated = DuplicationOnlyNodeContract.run("fleek", "defn", true)
repeated_reference = DuplicationOnlyNodeContract.run("flay", "defn", true)
AnalysisRunner.assert_report_contains(repeated_reference, [0,
  ["Similar code found in :defn (mass = 62)"], "Flay repeated --only precedence changed"])
AnalysisRunner.assert_report_contains(repeated, [2,
  ["node=\"defn\" kind=\"similar\"", "Status: findings"],
  "repeated --only did not use last value"])
raise "repeated --only retained earlier class group" if repeated[1].include?("node=\"class\"")

missing_repeated_value_id = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--only", "class", "--only", out: "/tmp/fleek-only-node-missing-out", err: "/tmp/fleek-only-node-missing-err")
missing_repeated_value = AnalysisRunner.observe(missing_repeated_value_id, "/tmp/fleek-only-node-missing-out", "/tmp/fleek-only-node-missing-err")
raise "repeated --only without a value was accepted" unless missing_repeated_value[0] == 1
raise "missing repeated --only emitted findings" unless missing_repeated_value[1].empty?
raise "missing repeated --only diagnostic changed" unless missing_repeated_value[2].include?("--only requires a node type")

puts "Flay --only node contract: pass"
