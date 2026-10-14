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
raise "finding does not match Reek" unless finding[1].lines[1].strip == reference[1].lines[1].strip
raise "findings diagnostic leaked to stderr" unless finding[2] == ""

clean = AnalysisProcess.fleek("test/fixtures/class_variable_clean.rb")
clean_reference = AnalysisProcess.reek("test/fixtures/class_variable_clean.rb")
raise "clean status differs from Reek" unless clean[0] == 0
raise "clean status differs from Reek" unless clean[0] == clean_reference[0]
raise "clean source reported a finding" if clean[1].include?("ClassVariable:")

text_only = AnalysisProcess.fleek("test/fixtures/class_variable_text.rb")
raise "string marker reported as class variable" if text_only[1].include?("ClassVariable:")
raise "comment marker reported as class variable" unless AnalysisProcess.fleek("test/fixtures/class_variable_text.rb")[0] == 0

unselected = AnalysisProcess.unselected("test/fixtures/class_variable.rb")
raise "omitted check selection was accepted" unless unselected[0] == 1 && unselected[2].include?("unsupported")

File.binwrite("/tmp/fleek-class-variable-nul.rb", "class Counter\n\0@@count = 0\nend\n")
nul = AnalysisProcess.fleek("/tmp/fleek-class-variable-nul.rb")
raise "embedded NUL was not rejected" unless nul[0] == 1 && nul[2].include?("embedded NUL")

File.write("/tmp/fleek-class-variable-invalid.rb", "class Counter\n  @@count =\nend\n")
invalid = AnalysisProcess.fleek("/tmp/fleek-class-variable-invalid.rb")
raise "invalid source was not rejected" unless invalid[0] == 1
File.write("/tmp/fleek-class-variable-unsupported.rb", "class Counter < Base\n  @@count = 0\nend\n")
unsupported = AnalysisProcess.fleek("/tmp/fleek-class-variable-unsupported.rb")
raise "unsupported context was accepted" unless unsupported[0] == 1 && unsupported[2].include?("supports one simple class")

puts "ClassVariable contract: pass"
