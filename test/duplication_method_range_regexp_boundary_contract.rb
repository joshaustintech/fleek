require_relative "analysis_runner"

FlayMethodCandidateContract.verify_no_group("test/fixtures/duplication_methods_range_clean.rb", "range-clean")
FlayMethodCandidateContract.verify_unsupported("test/fixtures/duplication_methods_range_unsupported.rb", "range-unsupported", 14)
FlayMethodCandidateContract.verify_no_group("test/fixtures/duplication_methods_regexp_clean.rb", "regexp-clean")
FlayMethodCandidateContract.verify_unsupported("test/fixtures/duplication_methods_regexp_unsupported.rb", "regexp-unsupported", 14)
puts "Method range and regexp boundaries: pass"
