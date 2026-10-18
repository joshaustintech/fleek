require_relative "analysis_runner"

hash_expression_path = "test/fixtures/duplication_class_methods_hash_expression.rb"
actual = AnalysisRunner.fleek_with_check("flay:StructuralDuplication", hash_expression_path)
reference = AnalysisRunner.flay(hash_expression_path)
group = "node=\"class\" kind=\"similar\" locations=\"#{hash_expression_path}:1,#{hash_expression_path}:8\" mass=62 score=62"
AnalysisRunner.assert_report_contains(actual, [2,
  [group, "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"],
  "hash expressions inside class methods were not analyzed"])
reference_fields = ["Similar code found in :class (mass = 62)", "#{hash_expression_path}:1", "#{hash_expression_path}:8", "Total score (lower is better) = 62"]
raise "hash expression Flay reference changed" unless reference[0] == 0 && reference_fields.all? { |field| reference[1].index(field) != nil }
puts "Hash expression duplication contract: pass"
