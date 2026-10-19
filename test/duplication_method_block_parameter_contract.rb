require_relative "analysis_runner"
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_block_parameter.rb", "block-parameter", 6, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_block_parameter_anonymous.rb", "block-parameter-anonymous", 6, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_block_parameter_anonymous_named.rb", "block-parameter-anonymous-named", 6, 1, 5)
