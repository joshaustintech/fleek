# frozen_string_literal: true

root = ENV.fetch("FLEEK_RUNNER_PROBE_ROOT")
task = ENV.fetch("FLEEK_RUNNER_PROBE_TASK")
File.write("#{root}/started-#{task}", "started")

if task == "slow"
  gate = Process.spawn(ENV.fetch("FLEEK_PROBE_GATE_SPINEL"), "-E", "test/check_runner_probe_gate.rb",
    out: "/dev/null", err: "/dev/null")
  Process.waitpid2(gate)
  raise "active worker source was removed early" unless File.file?("test/check_runner_probe_child.rb")
end

File.write("#{root}/finished-#{task}", "finished")
exit 1 if task == "fail"
