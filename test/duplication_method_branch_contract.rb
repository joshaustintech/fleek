require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_conditionals.rb", "branch-if-else", 62, 1, 13)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_unless_expression.rb", "branch-unless", 16, 1, 9)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_and.rb", "branch-and", 34, 1, 11)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_or.rb", "branch-or", 34, 1, 11)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_case_expression.rb", "branch-case", 34, 1, 12)
FlayMethodCandidateContract.verify_no_group("test/fixtures/duplication_methods_case_condition_lengths.rb", "branch-case-condition-lengths")
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_conditional_return.rb", "branch-return", 44, 1, 9)
puts "Method branch contract: pass"
