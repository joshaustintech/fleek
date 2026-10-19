require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_class_variable_operator_writes.rb", "class-variable-operator-writes", 24, 1, 6)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_class_variable_operator_write_names.rb", "class-variable-operator-write-names", 24, 1, 6)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_class_variable_operator_write_operators.rb", "class-variable-operator-write-operators", 24, 1, 6)
