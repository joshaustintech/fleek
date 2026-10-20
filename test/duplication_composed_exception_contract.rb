require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_composed_exception_regexp_identical.rb",
  "composed-exception-regexp-identical", 36, 1, 11)
FlayMethodCandidateContract.verify("test/fixtures/duplication_composed_exception_regexp_changed.rb",
  "composed-exception-regexp-changed", 36, 1, 11)
FlayMethodCandidateContract.verify("test/fixtures/duplication_composed_exception_string_identical.rb",
  "composed-exception-string-identical", 32, 1, 11)
FlayMethodCandidateContract.verify("test/fixtures/duplication_composed_exception_string_changed.rb",
  "composed-exception-string-changed", 32, 1, 11)
FlayMethodCandidateContract.verify("test/fixtures/duplication_composed_exception_plain_identical.rb",
  "composed-exception-plain-identical", 28, 1, 11)
[
  ["test/fixtures/duplication_composed_exception_regexp_identical.rb", "composed-exception-regexp-identical"],
  ["test/fixtures/duplication_composed_exception_regexp_changed.rb", "composed-exception-regexp-changed"],
  ["test/fixtures/duplication_composed_exception_string_identical.rb", "composed-exception-string-identical"],
  ["test/fixtures/duplication_composed_exception_string_changed.rb", "composed-exception-string-changed"],
  ["test/fixtures/duplication_composed_exception_plain_identical.rb", "composed-exception-plain-identical"]
].each do |path, label|
  FlayMethodCandidateContract.verify_empty_stderr(path, "#{label}-streams")
end

path = "test/fixtures/duplication_composed_exception_unsupported_default.rb"
root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
actual_output = "#{root}/composed-exception-unsupported-actual.out"
actual_error = "#{root}/composed-exception-unsupported-actual.err"
reference_output = "#{root}/composed-exception-unsupported-reference.out"
reference_error = "#{root}/composed-exception-unsupported-reference.err"
begin
  actual_status = FlayMethodCandidateContract.run_fleek(path, actual_output, actual_error)
  reference_status = FlayMethodCandidateContract.run_flay(path, reference_output, reference_error)
  actual_report = File.read(actual_output)
  actual_diagnostic = File.read(actual_error)
  reference_report = File.read(reference_output)
  reference_diagnostic = File.read(reference_error)
  actual_fields = [
    "scope=partial", "node=\"defn\" kind=\"similar\"",
    "locations=\"#{path}:2,#{path}:12\" mass=36 score=36",
    "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"
  ]
  reference_fields = ["code found in :defn", "#{path}:2", "#{path}:12", "Total score (lower is better) = 36"]
  raise "composed exception partial finding or streams differed" unless actual_status == 1 &&
    actual_fields.all? { |field| actual_report.include?(field) } && actual_diagnostic.include?("Partial results") &&
    !actual_report.include?("Partial results") && reference_status.success? &&
    reference_fields.all? { |field| reference_report.include?(field) } && reference_diagnostic.empty?
ensure
  AnalysisRunner.cleanup_contract_outputs([actual_error, reference_output, reference_error], actual_output)
end
puts "Composed exception contract: pass"
