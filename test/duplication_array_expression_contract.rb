require_relative "analysis_runner"

array_expression_path = "test/fixtures/duplication_class_methods_array_expression.rb"
actual = AnalysisRunner.fleek_with_check("flay:StructuralDuplication", array_expression_path)
reference = AnalysisRunner.flay(array_expression_path)
group = "node=\"class\" kind=\"similar\" locations=\"#{array_expression_path}:1,#{array_expression_path}:7\" mass=40 score=40"
AnalysisRunner.assert_report_contains(actual, [2,
  [group, "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"],
  "array expressions inside class methods were not analyzed"])
AnalysisRunner.assert_report_contains(reference, [0,
  ["Similar code found in :class (mass = 40)", "#{array_expression_path}:1", "#{array_expression_path}:7", "Total score (lower is better) = 40"],
  "array expression Flay reference changed"])
puts "Array expression duplication contract: pass"
