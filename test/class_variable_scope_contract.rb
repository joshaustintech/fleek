# Verifies ClassVariable grouping and scope behavior against Reek 6.6.0.
require_relative "analysis_runner"

occurrences_path = "test/fixtures/class_variable_occurrences.rb"
occurrences = AnalysisRunner.fleek(occurrences_path)
reference = AnalysisRunner.reek(occurrences_path)
AnalysisRunner.assert_reference(occurrences, reference, "repeated ClassVariable")

writes_path = "test/fixtures/class_variable_write_forms.rb"
writes = AnalysisRunner.fleek(writes_path)
writes_reference = AnalysisRunner.reek(writes_path)
AnalysisRunner.assert_reference(writes, writes_reference, "ClassVariable write-form")

singleton_path = "test/fixtures/class_variable_singleton.rb"
singleton = AnalysisRunner.fleek(singleton_path)
singleton_reference = AnalysisRunner.reek(singleton_path)
raise "singleton context differs from Reek" unless singleton[0] == singleton_reference[0] && AnalysisRunner.warning_lines(singleton[1]) == AnalysisRunner.warning_lines(singleton_reference[1])

top_level_path = "test/fixtures/class_variable_top_level.rb"
top_level = AnalysisRunner.fleek(top_level_path)
top_level_reference = AnalysisRunner.reek(top_level_path)
raise "top-level behavior differs from Reek" unless top_level[0] == top_level_reference[0]

nested = AnalysisRunner.fleek("test/fixtures/class_variable_nested.rb")
raise "nested scopes were silently reported" unless nested[0] == 1 && nested[2].include?("nested classes or modules")
reopened = AnalysisRunner.fleek("test/fixtures/class_variable_reopen.rb")
raise "reopened classes were silently reported" unless reopened[0] == 1 && reopened[2].include?("one simple class")

puts "ClassVariable scope contract: pass"
