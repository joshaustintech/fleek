require_relative "analysis_runner"

path = "test/fixtures/duplication_methods_hash_rocket.rb"
actual = AnalysisRunner.fleek_with_check("flay:StructuralDuplication", path)
reference = AnalysisRunner.flay(path)
group = "node=\"defn\" kind=\"identical\" locations=\"#{path}:1,#{path}:6\" mass=60 score=120"
AnalysisRunner.assert_report_contains(actual, [2,
  [group, "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"],
  "top-level hash-rocket methods were not analyzed"])
reference_fields = ["IDENTICAL code found in :defn (mass*2 = 120)", "#{path}:1", "#{path}:6", "Total score (lower is better) = 120"]
raise "Flay hash-rocket method reference changed" unless reference[0] == 0 && reference_fields.all? { |field| reference[1].include?(field) }
puts "Method hash-rocket contract: pass"
