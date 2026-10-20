# frozen_string_literal: true

root = ENV.fetch("FLEEK_RUNNER_PROBE_ROOT")
task = ENV.fetch("FLEEK_RUNNER_PROBE_TASK")
File.write("#{root}/started-#{task}", "started")

if task == "slow"
  deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 20
  until File.exist?("#{root}/release-slow")
    raise "slow runner probe timed out" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
  end
  raise "active worker source was removed early" unless File.file?("test/check_runner_probe_child.rb")
end

File.write("#{root}/finished-#{task}", "finished")
exit 1 if task == "fail"
