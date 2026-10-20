require_relative "analysis_runner"

FlayMethodCandidateContract.verify("test/fixtures/duplication_methods_composed_signature_block_identical.rb",
  "composed-signature-block-identical", 44, 1, 7)
FlayMethodCandidateContract.verify_empty_stderr("test/fixtures/duplication_methods_composed_signature_block_identical.rb",
  "composed-signature-block-identical-stderr")
FlayMethodCandidateContract.verify_no_group("test/fixtures/duplication_methods_composed_signature_block_arity_mismatch.rb",
  "composed-signature-block-arity-mismatch")
FlayMethodCandidateContract.verify_empty_stderr("test/fixtures/duplication_methods_composed_signature_block_arity_mismatch.rb",
  "composed-signature-block-arity-mismatch-stderr")
