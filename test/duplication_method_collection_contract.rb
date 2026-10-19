require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_array_expression.rb", "method-array-expression", 38, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_hash_expression.rb", "method-keyword-hash-expression", 60, 1, 6)
puts "Method collection contract: pass"
