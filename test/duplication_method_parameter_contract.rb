require_relative "analysis_runner"
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_rest_parameter.rb", "rest-parameter", 6, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_keyword_parameters.rb", "keyword-parameter", 8, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_optional_keyword_parameters.rb", "optional-keyword-parameter", 10, 1, 5)
FlayMethodCandidateContract.verify_no_group("test/fixtures/duplication_methods_optional_keyword_count.rb", "optional-keyword-count")
FlayMethodCandidateContract.verify_unsupported("test/fixtures/duplication_methods_optional_keyword_nonliteral.rb", "optional-keyword-nonliteral")
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_post_parameters.rb", "post-parameter", 10, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_post_parameter_names.rb", "post-parameter-name", 10, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_post_parameter_count.rb", "post-parameter-count", 10, 1, 5)
