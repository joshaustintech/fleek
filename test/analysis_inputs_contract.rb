# Verifies file and recursive-directory selection behavior.
# Runs multiple-source CLI cases.
require_relative "analysis_runner"
# Processes several input shapes for the CLI contract.
class InputProcess # Runs multi-input cases for the CLI contract.
  def self.fleek_directory(path)
    AnalysisRunner.fleek(path)
  end

  def self.reek_directory(path)
    AnalysisRunner.reek(path)
  end

  def self.fleek_repeated(path)
    AnalysisRunner.repeated("fleek", path)
  end

  def self.reek_repeated(path)
    AnalysisRunner.repeated("reek", path)
  end

  def self.fleek_mixed(failed_path, good_path)
    process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", failed_path, good_path, out: "/tmp/fleek-input-out", err: "/tmp/fleek-input-err")
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read("/tmp/fleek-input-out"), File.read("/tmp/fleek-input-err")]
  end

end

directory = "test/fixtures/discovery"
actual = InputProcess.fleek_directory(directory)
reference = InputProcess.reek_directory(directory)
AnalysisRunner.assert_reference(actual, reference, "directory scan")

file = "test/fixtures/class_variable.rb"
repeated = InputProcess.fleek_repeated(file)
repeated_reference = InputProcess.reek_repeated(file)
AnalysisRunner.assert_reference(repeated, repeated_reference, "repeated paths")

mixed = InputProcess.fleek_mixed("test/fixtures/bad_syntax.rb", file)
raise "partial analysis status missing" unless mixed[0] == 1 && mixed[1].include?("Status: incomplete")
raise "good file lost after input failure" unless mixed[1].include?("@@count")
raise "failed source not identified" unless mixed[2].include?("bad_syntax.rb")
unsupported = InputProcess.fleek_mixed("test/fixtures/class_variable_nested.rb", file)
raise "unsupported source not identified" unless unsupported[0] == 1 && unsupported[2].include?("class_variable_nested.rb")
raise "good file lost beside unsupported source" unless unsupported[1].include?("@@count")

non_ruby = AnalysisRunner.fleek("test/fixtures/not_ruby.txt")
raise "non-Ruby input was accepted" unless non_ruby[0] == 1 && non_ruby[2].include?("Ruby source")
missing = AnalysisRunner.fleek("test/fixtures/missing.rb")
raise "missing input was accepted" unless missing[0] == 1 && missing[2].include?("Cannot read")
empty = InputProcess.fleek_directory("test/fixtures/discovery/hidden_only")
raise "empty discovery was successful" unless empty[0] == 1 && empty[2].include?("No Ruby source files discovered")
directory_link = AnalysisRunner.fleek("test/fixtures/discovery/recursive_link")
raise "explicit directory symlink was followed" unless directory_link[0] == 1

puts "Analysis input contract: pass"
