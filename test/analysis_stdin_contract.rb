# Verifies named standard-input analysis through the public CLI.
require_relative "analysis_runner"
# Runs named and mixed stdin CLI cases.
class StdinProcess
  def self.run(origin, input_path)
    process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", "--stdin", origin, in: input_path, out: "/tmp/fleek-stdin-out", err: "/tmp/fleek-stdin-err")
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read("/tmp/fleek-stdin-out"), File.read("/tmp/fleek-stdin-err")]
  end

  def self.mixed(origin, input_path, path)
    process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", "--stdin", origin, path, in: input_path, out: "/tmp/fleek-stdin-out", err: "/tmp/fleek-stdin-err")
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read("/tmp/fleek-stdin-out"), File.read("/tmp/fleek-stdin-err")]
  end

  def self.missing_origin
    process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", "--stdin", in: "/dev/null", out: "/tmp/fleek-stdin-out", err: "/tmp/fleek-stdin-err")
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read("/tmp/fleek-stdin-out"), File.read("/tmp/fleek-stdin-err")]
  end
end

origin = "test/fixtures/class_variable.rb"
missing = StdinProcess.missing_origin
raise "stdin origin was not required" unless missing[0] == 1 && missing[2].include?("source filename")

file = AnalysisRunner.fleek(origin)
stdin = StdinProcess.run(origin, origin)
raise "named stdin differs from file" unless stdin == file

invalid = StdinProcess.run("editor_buffer.rb", "test/fixtures/bad_syntax.rb")
raise "stdin syntax diagnostic lost its origin" unless invalid[0] == 1 && invalid[2].include?("editor_buffer.rb")

empty_origin = "empty-buffer.rb"
empty = StdinProcess.run(empty_origin, "test/fixtures/empty.rb")
raise "empty named stdin was not a complete clean source" unless empty[0] == 0 && empty[1].include?("Source: \"#{empty_origin}\" scope=included") && empty[1].include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded") && empty[1].include?("Status: complete")

mixed = StdinProcess.mixed(origin, origin, "test/fixtures/class_variable.rb")
AnalysisRunner.assert_report_state(mixed, AnalysisRunner::ReportExpectation.new(2, "Coverage: 2 selected; 2 analyzed; 0 failed; 0 excluded", "findings", "mixed stdin and path"))
raise "mixed stdin and path diagnosed errors" unless mixed[2] == ""

puts "Named stdin contract: pass"
