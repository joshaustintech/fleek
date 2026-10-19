require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_local_operator_write.rb", "local-operator-write", 24, 1, 8)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_local_operator_write_names.rb", "local-operator-write-names", 24, 1, 8)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_local_operator_write_operators.rb", "local-operator-write-operators", 24, 1, 8)
