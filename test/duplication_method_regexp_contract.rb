require_relative "analysis_runner"
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_regexp.rb", "regexp", 10, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_regexp_content.rb", "regexp-content", 10, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_regexp_flags.rb", "regexp-flags", 10, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_interpolated_regexp.rb", "interpolated-regexp", 16, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_interpolated_regexp_content.rb", "interpolated-regexp-content", 16, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_interpolated_regexp_flags.rb", "interpolated-regexp-flags", 16, 1, 5)
