# frozen_string_literal: true

if ARGV[0] == "-E" && ARGV[1] == "test/mutation_contract.rb"
  if ENV["FLEEK_PRECOMPILE_MUTATION_CONTRACTS"] == "1"
    runner_root = ENV.fetch("FLEEK_RUNNER_BUDGET_ROOT")
    File.write("#{runner_root}/child-jobs", ENV.fetch("JOBS", "unset"))
  end
  exit 0
end
root = ENV.fetch("FLEEK_PRECOMPILE_PROBE_ROOT")
process_id = Process.pid
File.write("#{root}/started-#{process_id}", ENV.fetch("TMPDIR"))
File.write("#{root}/flags-#{process_id}", "#{ARGV[0]} #{ARGV[1]}")
gate = Process.spawn(ENV.fetch("FLEEK_PROBE_GATE_SPINEL"), "-E", "test/check_runner_probe_gate.rb",
  out: "/dev/null", err: "/dev/null")
Process.waitpid2(gate)
File.write("#{root}/finished-#{process_id}", "finished")
