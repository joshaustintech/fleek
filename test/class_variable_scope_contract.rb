# Verifies ClassVariable grouping and scope behavior against Reek 6.6.0.
class ScopeProcess
  def self.fleek(path)
    process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", path, out: "/tmp/fleek-scope-out", err: "/tmp/fleek-scope-err")
    observe(process_id, "/tmp/fleek-scope-out", "/tmp/fleek-scope-err")
  end

  def self.reek(path)
    process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "reek", "--smell", "ClassVariable", path, out: "/tmp/fleek-scope-reference-out", err: "/tmp/fleek-scope-reference-err")
    observe(process_id, "/tmp/fleek-scope-reference-out", "/tmp/fleek-scope-reference-err")
  end

  def self.observe(process_id, output_path, error_path)
    _, process_status = Process.waitpid2(process_id)
    [process_status.exitstatus, File.read(output_path), File.read(error_path)]
  end

  def self.assert_findings_match(actual, reference, count)
    expected_lines = reference[1].lines[1, count]
    actual_lines = actual[1].lines[1, count]
    raise "ClassVariable findings differ" unless actual_lines == expected_lines
  end
end

occurrences_path = "test/fixtures/class_variable_occurrences.rb"
occurrences = ScopeProcess.fleek(occurrences_path)
reference = ScopeProcess.reek(occurrences_path)
raise "repeated ClassVariable status differs: #{occurrences[0]}, #{reference[0]}" unless occurrences[0] == reference[0] && occurrences[0] == 2
ScopeProcess.assert_findings_match(occurrences, reference, 2)

writes_path = "test/fixtures/class_variable_write_forms.rb"
writes = ScopeProcess.fleek(writes_path)
writes_reference = ScopeProcess.reek(writes_path)
raise "ClassVariable write-form status differs" unless writes[0] == writes_reference[0] && writes[0] == 2
ScopeProcess.assert_findings_match(writes, writes_reference, 4)

singleton_path = "test/fixtures/class_variable_singleton.rb"
singleton = ScopeProcess.fleek(singleton_path)
singleton_reference = ScopeProcess.reek(singleton_path)
raise "singleton context differs from Reek" unless singleton[0] == singleton_reference[0] && singleton[1].lines[1] == singleton_reference[1].lines[1]

top_level_path = "test/fixtures/class_variable_top_level.rb"
top_level = ScopeProcess.fleek(top_level_path)
top_level_reference = ScopeProcess.reek(top_level_path)
raise "top-level behavior differs from Reek" unless top_level[0] == top_level_reference[0]

nested = ScopeProcess.fleek("test/fixtures/class_variable_nested.rb")
raise "nested scopes were silently reported" unless nested[0] == 1 && nested[2].include?("nested classes or modules")
reopened = ScopeProcess.fleek("test/fixtures/class_variable_reopen.rb")
raise "reopened classes were silently reported" unless reopened[0] == 1 && reopened[2].include?("one simple class")

puts "ClassVariable scope contract: pass"
