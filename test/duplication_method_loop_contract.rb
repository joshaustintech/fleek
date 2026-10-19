require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_while_control.rb", "loop-while", 10, 1, 7)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_until_control.rb", "loop-until", 10, 1, 7)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_for_control.rb", "loop-for", 14, 1, 7)
puts "Method loop contract: pass"
