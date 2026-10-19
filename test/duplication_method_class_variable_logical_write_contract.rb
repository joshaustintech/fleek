require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_class_variable_and_write.rb", "class-variable-and-write", 12, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_class_variable_or_write.rb", "class-variable-or-write", 12, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_class_variable_and_write_names.rb", "class-variable-and-write-names", 12, 1, 5)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_class_variable_or_write_names.rb", "class-variable-or-write-names", 12, 1, 5)
FlayMethodCandidateContract.verify_no_group("test/fixtures/duplication_methods_class_variable_logical_write_operators.rb", "class-variable-logical-write-operators")
