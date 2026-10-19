require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_block_optional_parameter.rb", "block-optional-parameter", 20, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_block_optional_parameter_expression.rb", "block-optional-parameter-expression", 20, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_block_optional_parameter_names.rb", "block-optional-parameter-names", 20, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_block_optional_parameter_defaults.rb", "block-optional-parameter-defaults", 20, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_block_optional_parameters.rb", "block-optional-parameters", 24, 1, 5)
FlayMethodCandidateContract.verify_no_group("test/fixtures/duplication_methods_block_optional_parameter_count_mismatch.rb", "block-optional-parameter-count-mismatch")
