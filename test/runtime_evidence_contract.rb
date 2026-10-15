# Protects the public correctness gate required before runtime measurement.
process_id = Process.spawn(ENV["SPINEL"] || "spinel", "-E", "test/runtime_evidence.rb", "--verify-only",
  out: "/tmp/fleek-runtime-contract-out", err: "/tmp/fleek-runtime-contract-err")
_, status = Process.waitpid2(process_id)
output = File.read("/tmp/fleek-runtime-contract-out")
error = File.read("/tmp/fleek-runtime-contract-err")
raise "runtime evidence equivalence gate failed: #{error}" unless status.success? && output.include?("Runtime equivalence contract: pass")
puts "Runtime evidence contract: pass"
