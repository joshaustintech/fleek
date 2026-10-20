require_relative "analysis_runner"

case_path = "test/fixtures/duplication_composed_case_collection.rb"
FlayMethodCandidateContract.verify(case_path, "composed-case-collection", 38, 1, 12)
FlayMethodCandidateContract.verify_empty_stderr(case_path, "composed-case-collection-streams")

loop_path = "test/fixtures/duplication_composed_loop_collection.rb"
FlayMethodCandidateContract.verify(loop_path, "composed-loop-collection", 30, 1, 7)
FlayMethodCandidateContract.verify_empty_stderr(loop_path, "composed-loop-collection-streams")

identity_path = "test/fixtures/duplication_composed_collection_identity.rb"
FlayMethodCandidateContract.verify(identity_path, "composed-collection-identity", 26, 1, 9)
FlayMethodCandidateContract.verify_empty_stderr(identity_path, "composed-collection-identity-streams")

topology_path = "test/fixtures/duplication_composed_collection_topology.rb"
FlayMethodCandidateContract.verify_no_group(topology_path, "composed-collection-topology")
FlayMethodCandidateContract.verify_empty_stderr(topology_path, "composed-collection-topology-streams")

puts "Composed collection contract: pass"
