require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_yield_statement.rb", "flow-yield", 6, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_yield_arguments.rb", "flow-yield-arguments", 8, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_next.rb", "flow-next", 24, 1, 8)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_break.rb", "flow-break", 20, 1, 7)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_redo.rb", "flow-redo", 18, 1, 7)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_rescue_retry.rb", "flow-rescue-retry", 16, 1, 9)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_ensure.rb", "flow-ensure", 10, 1, 9)
puts "Method exception-flow contract: pass"
