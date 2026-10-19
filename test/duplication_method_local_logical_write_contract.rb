require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_local_or_write.rb", "local-or-write", 20, 1, 7)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_local_and_write.rb", "local-and-write", 20, 1, 7)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_local_or_write_names.rb", "local-or-write-names", 20, 1, 7)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_local_and_write_names.rb", "local-and-write-names", 20, 1, 7)
FlayMethodCandidateContract.verify_no_group("test/fixtures/duplication_methods_local_logical_write_operators.rb", "local-logical-write-operators")
