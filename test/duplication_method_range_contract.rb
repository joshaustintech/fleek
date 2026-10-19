require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_range_expression.rb", "range-expression", 10, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_range_operator.rb", "range-operator", 10, 1, 5)
puts "Method range contract: pass"
