require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_class_variable_writes.rb", "class-variable-writes", 12, 1, 6)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_class_variable_write_names.rb", "class-variable-write-names", 12, 1, 6)
