# Verifies the public text report through compiled CLI output.
require_relative "analysis_runner"
# Runs text-report requests through the public CLI boundary.
class TextReportProcess
  def self.mixed_inputs
    process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", "test/fixtures/class_variable.rb", "test/fixtures/missing-report-source.rb", out: "/tmp/fleek-text-report-out", err: "/tmp/fleek-text-report-err")
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read("/tmp/fleek-text-report-out"), File.read("/tmp/fleek-text-report-err")]
  end

  def self.format_request
    process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", "--format", "json", "test/fixtures/class_variable.rb", out: "/tmp/fleek-text-report-out", err: "/tmp/fleek-text-report-err")
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read("/tmp/fleek-text-report-out"), File.read("/tmp/fleek-text-report-err")]
  end

end

result = AnalysisRunner.fleek("test/fixtures/class_variable.rb")
raise "report version missing" unless result[1].start_with?("Fleek report v1\n")
raise "reference identities missing" unless result[1].include?("References: Flay 2.14.4; Reek 6.6.0; Spinel 2026.09.12")
raise "selected check missing" unless result[1].include?("Checks selected: reek:ClassVariable")
raise "run check missing" unless result[1].include?("Checks run: reek:ClassVariable")
raise "scope limits missing" unless result[1].include?("Scope limits: Ruby .rb inputs; only reek:ClassVariable is implemented.")
raise "findings section missing" unless result[1].include?("Findings:\n")
raise "source field missing" unless result[1].include?("Source: \"test/fixtures/class_variable.rb\" scope=included")
raise "stable finding fields missing" unless result[1].include?("Finding: check=\"reek:ClassVariable\" source=\"test/fixtures/class_variable.rb\" lines=\"3\" context=\"Counter\" name=\"@@count\"")
raise "coverage fields missing" unless result[1].include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
raise "finding result missing" unless result[1].include?("Status: findings")
raise "report diagnostics leaked to stderr" unless result[2].empty?
raise "report section order changed" unless result[1].index("References:") < result[1].index("Checks selected:") && result[1].index("Checks selected:") < result[1].index("Checks run:") && result[1].index("Checks run:") < result[1].index("Scope limits:") && result[1].index("Scope limits:") < result[1].index("Sources:") && result[1].index("Sources:") < result[1].index("Findings:") && result[1].index("Findings:") < result[1].index("Coverage:") && result[1].index("Coverage:") < result[1].index("Status:")
raise "identical report was not deterministic" unless AnalysisRunner.fleek("test/fixtures/class_variable.rb") == result

missing_source = AnalysisRunner.fleek("test/fixtures/missing-report-source.rb")
raise "failed source missing from report sources" unless missing_source[1].include?("Source: \"test/fixtures/missing-report-source.rb\" scope=failed")
partial_sources = TextReportProcess.mixed_inputs
raise "mixed report omitted failed source" unless partial_sources[1].include?("Source: \"test/fixtures/missing-report-source.rb\" scope=failed")
raise "mixed report omitted analyzed source" unless partial_sources[1].include?("Source: \"test/fixtures/class_variable.rb\" scope=included")
raise "mixed report coverage did not identify both sources" unless partial_sources[0] == 1 && partial_sources[1].include?("Coverage: 2 selected; 1 analyzed; 1 failed; 0 excluded")
raise "mixed report lost failed-source diagnostic" unless partial_sources[2].include?("Cannot read source file")

special_path = "test/fixtures/report-\\slash-\"quoted\"\tline\n-é\r.rb"
File.write(special_path, "class Café\n  @@count = 1\nend\n")
special = AnalysisRunner.fleek(special_path)
escaped_path = "Source: \"test/fixtures/report-\\\\slash-\\\"quoted\\\"\\tline\\n-é\\r.rb\" scope=included"
raise "source field escaping is ambiguous" unless special[1].include?(escaped_path)
raise "finding source escaping is ambiguous" unless special[1].include?("source=\"test/fixtures/report-\\\\slash-\\\"quoted\\\"\\tline\\n-é\\r.rb\"")
raise "non-ASCII finding was lost" unless special[1].include?("Café")
File.delete(special_path)
File.write(special_path, "class Café\n  @@count =\nend\n")
special_error = AnalysisRunner.fleek(special_path)
escaped_diagnostic_path = "\"test/fixtures/report-\\\\slash-\\\"quoted\\\"\\tline\\n-é\\r.rb\":2:"
raise "diagnostic path escaping is ambiguous" unless special_error[0] == 1 && special_error[2].include?(escaped_diagnostic_path) && !special_error[2].include?("line\n-é")
raise "failed source did not record attempted check" unless special_error[1].include?("Checks run: reek:ClassVariable") && special_error[1].include?("Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded")
File.delete(special_path)

order_directory = "test/fixtures/report_order"
if Dir.exist?(order_directory)
  Dir.children(order_directory).each { |entry| File.delete("#{order_directory}/#{entry}") }
  Dir.rmdir(order_directory)
end
Dir.mkdir(order_directory)
File.write("#{order_directory}/z.rb", "class Zed\nend\n")
File.write("#{order_directory}/a.rb", "class Able\nend\n")
ordered = AnalysisRunner.fleek(order_directory)
source_rows = ordered[1].lines.select { |line| line.include?("  Source:") }
raise "source ordering changed" unless source_rows[0].include?("a.rb") && source_rows[1].include?("z.rb")
AnalysisRunner.assert_report_state(ordered, AnalysisRunner::ReportExpectation.new(0, "Coverage: 2 selected; 2 analyzed; 0 failed; 0 excluded", "complete", "clean report"))
File.delete("#{order_directory}/a.rb")
File.delete("#{order_directory}/z.rb")
Dir.rmdir(order_directory)

format = TextReportProcess.format_request
raise "unsupported format was accepted" unless format[0] == 1 && format[1].empty? && format[2].include?("Unsupported output format")

puts "Text report contract: pass"
