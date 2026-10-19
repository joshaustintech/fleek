require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_multiple_assignment.rb", "multiple-assignment", 22, 1, 6)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_multiple_assignment_names.rb", "multiple-assignment-names", 20, 1, 6)
FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_multiple_assignment_three_targets.rb", "multiple-assignment-three-targets", 26, 1, 6)
FlayMethodCandidateContract.verify_no_group("test/fixtures/duplication_methods_multiple_assignment_count_mismatch.rb", "multiple-assignment-count-mismatch")
