require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_instance_variable_operator_writes.rb", "instance-variable-operator-writes", 24, 1, 6)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_instance_variable_operator_write_names.rb", "instance-variable-operator-write-names", 24, 1, 6)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_instance_variable_operator_write_operators.rb", "instance-variable-operator-write-operators", 24, 1, 6)
