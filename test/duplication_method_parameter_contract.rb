require_relative "analysis_runner"
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_rest_parameter.rb", "rest-parameter", 6, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_keyword_parameters.rb", "keyword-parameter", 8, 1, 5)
