require_relative "analysis_runner"
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_rest_parameter.rb", "rest-parameter-focused", 6, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_rest_anonymous.rb", "rest-anonymous", 6, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_rest_anonymous_named.rb", "rest-anonymous-named", 6, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_keyword_rest_parameter.rb", "keyword-rest-parameter-focused", 6, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_keyword_rest_anonymous.rb", "keyword-rest-anonymous", 6, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_keyword_rest_anonymous_named.rb", "keyword-rest-anonymous-named", 6, 1, 5)
