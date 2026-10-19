require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_class_variable_reads.rb", "class-variable-reads", 12, 1, 6)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_class_variable_read_names.rb", "class-variable-read-names", 12, 1, 6)
