require_relative "analysis_runner"
# Verifies selected ClassVariable analysis against the unchanged Reek CLI.
class AnalysisProcess
  def self.fleek(path)
    process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", path, out: "/tmp/fleek-analysis-out", err: "/tmp/fleek-analysis-err")
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read("/tmp/fleek-analysis-out"), File.read("/tmp/fleek-analysis-err")]
  end

  def self.unselected(path)
    process_id = Process.spawn("build/fleek", path, out: "/tmp/fleek-analysis-out", err: "/tmp/fleek-analysis-err")
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read("/tmp/fleek-analysis-out"), File.read("/tmp/fleek-analysis-err")]
  end

  def self.reek(path)
    process_id = Process.spawn(bundle_executable, "exec", "reek", "--smell", "ClassVariable", path, out: "/tmp/fleek-analysis-reference-out", err: "/tmp/fleek-analysis-reference-err")
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read("/tmp/fleek-analysis-reference-out"), File.read("/tmp/fleek-analysis-reference-err")]
  end

  def self.bundle_executable
    ENV["BUNDLE"] || "bundle"
  end
end

finding = AnalysisProcess.fleek("test/fixtures/class_variable.rb")
reference = AnalysisProcess.reek("test/fixtures/class_variable.rb")
raise "finding status differs from Reek: #{finding[0]} #{finding[1]} #{finding[2]}" unless finding[0] == 2
raise "finding status differs from Reek" unless finding[0] == reference[0]
raise "finding context/message/location missing" unless finding[1].include?("[3]:ClassVariable: Counter declares the class variable '@@count'")
AnalysisRunner.assert_same_report(finding, reference, "finding")
raise "findings diagnostic leaked to stderr" unless finding[2] == ""

clean = AnalysisProcess.fleek("test/fixtures/class_variable_clean.rb")
clean_reference = AnalysisProcess.reek("test/fixtures/class_variable_clean.rb")
raise "clean status differs from Reek" unless clean[0] == 0
raise "clean status differs from Reek" unless clean[0] == clean_reference[0]
raise "clean source reported a finding" if clean[1].include?("ClassVariable:")

text_only = AnalysisProcess.fleek("test/fixtures/class_variable_text.rb")
raise "string marker reported as class variable" if text_only[1].include?("ClassVariable:")
raise "comment marker reported as class variable" unless AnalysisProcess.fleek("test/fixtures/class_variable_text.rb")[0] == 0

inherited = AnalysisProcess.fleek("test/fixtures/class_variable_inherited.rb")
inherited_reference = AnalysisProcess.reek("test/fixtures/class_variable_inherited.rb")
raise "inherited class status differs from Reek" if inherited[0] != inherited_reference[0]
AnalysisRunner.assert_same_report(inherited, inherited_reference, "inherited class")

namespaced = AnalysisProcess.fleek("test/fixtures/class_variable_namespaced.rb")
namespaced_reference = AnalysisProcess.reek("test/fixtures/class_variable_namespaced.rb")
raise "namespaced class status differs from Reek" unless namespaced[0] == namespaced_reference[0]
AnalysisRunner.assert_same_report(namespaced, namespaced_reference, "namespaced class")
raise "qualified class context missing" unless namespaced[1].include?("context=\"ApplicationCable::Connection\"")
raise "one-level namespace line aggregation missing" unless namespaced[1].include?("lines=\"3, 6\"")

namespaced_module = AnalysisProcess.fleek("test/fixtures/class_variable_namespaced_module.rb")
namespaced_module_reference = AnalysisProcess.reek("test/fixtures/class_variable_namespaced_module.rb")
raise "namespaced module status differs from Reek" unless namespaced_module[0] == namespaced_module_reference[0]
AnalysisRunner.assert_same_report(namespaced_module, namespaced_module_reference, "namespaced module")
raise "qualified module context missing" unless namespaced_module[1].include?("context=\"ApplicationCable::Channel\"")

namespaced_suppressed = AnalysisProcess.fleek("test/fixtures/class_variable_namespaced_suppressed.rb")
namespaced_suppressed_reference = AnalysisProcess.reek("test/fixtures/class_variable_namespaced_suppressed.rb")
raise "namespaced suppression status differs from Reek" unless namespaced_suppressed[0] == namespaced_suppressed_reference[0]
AnalysisRunner.assert_same_report(namespaced_suppressed, namespaced_suppressed_reference, "namespaced suppression")

nested_namespace = AnalysisProcess.fleek("test/fixtures/class_variable_nested_namespace.rb")
nested_namespace_reference = AnalysisProcess.reek("test/fixtures/class_variable_nested_namespace.rb")
AnalysisRunner.assert_same_report(nested_namespace, nested_namespace_reference, "nested namespace ClassVariable")
raise "nested namespace context missing" unless nested_namespace[1].include?("context=\"ApplicationCable::Internal::Connection\"")
raise "nested namespace line aggregation missing" unless nested_namespace[1].include?("lines=\"4, 6, 9\"")

too_deep = AnalysisProcess.fleek("test/fixtures/class_variable_namespace_too_deep.rb")
raise "over-limit namespace was not reported incomplete" unless too_deep[0] == 1 && too_deep[1].include?("Status: incomplete")

wrapped_nested = AnalysisProcess.fleek("test/fixtures/class_variable_nested_namespace_wrapped_child.rb")
raise "wrapped nested namespace class was not reported incomplete" unless wrapped_nested[0] == 1 && wrapped_nested[1].include?("Status: incomplete")

namespace_and_child = AnalysisProcess.fleek("test/fixtures/class_variable_namespace_and_child.rb")
raise "unreported namespace occurrence implied complete analysis" unless namespace_and_child[0] == 1 && namespace_and_child[1].include?("Status: incomplete")

wrapped_namespace_child = AnalysisProcess.fleek("test/fixtures/class_variable_namespace_wrapped_child.rb")
raise "wrapped namespace child was accepted" unless wrapped_namespace_child[0] == 1 && wrapped_namespace_child[1].include?("Status: incomplete")

unselected = AnalysisProcess.unselected("test/fixtures/class_variable.rb")
raise "omitted check selection was accepted" unless unselected[0] == 1 && unselected[2].include?("unsupported")

File.binwrite("/tmp/fleek-class-variable-nul.rb", "class Counter\n\0@@count = 0\nend\n")
nul = AnalysisProcess.fleek("/tmp/fleek-class-variable-nul.rb")
raise "embedded NUL was not rejected" unless nul[0] == 1 && nul[2].include?("embedded NUL")

File.write("/tmp/fleek-class-variable-invalid.rb", "class Counter\n  @@count =\nend\n")
invalid = AnalysisProcess.fleek("/tmp/fleek-class-variable-invalid.rb")
raise "invalid source was not rejected" unless invalid[0] == 1
File.write("/tmp/fleek-class-variable-unsupported.rb", "class Counter\n  class Nested; end\nend\n")
unsupported = AnalysisProcess.fleek("/tmp/fleek-class-variable-unsupported.rb")
raise "unsupported context was accepted" unless unsupported[0] == 1 && unsupported[2].include?("supports one simple class")

puts "ClassVariable contract: pass"
