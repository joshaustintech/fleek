# frozen_string_literal: true
# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:IrresponsibleModule
# :reek:LongParameterList
# :reek:RepeatedConditional
# :reek:TooManyStatements

class CheckRunnerSchedulerContract
  def self.run
    verify_case(false)
    verify_case(true)
    puts "Check runner scheduler contract: pass"
  end

  def self.verify_case(failure)
    root = "#{ENV.fetch('FLEEK_TEMP_ROOT')}/scheduler-probe-#{Process.pid}-#{failure}"
    Dir.mkdir(root)
    output = "#{root}/runner.out"
    error = "#{root}/runner.err"
    process_id = launch_runner(root, output, error, failure)
    third_started_before_release = wait_for_marker("#{root}/started-third")
    File.write("#{root}/release-slow", "release")
    _, status = Process.waitpid2(process_id)
    verify_case_output(root, output, error, status, failure, third_started_before_release)
    verify_worker_cleanup(root)
  ensure
    File.write("#{root}/release-slow", "release") if root && Dir.exist?(root)
  end

  def self.launch_runner(root, output, error, failure)
    if failure
      Process.spawn("env", "JOBS=2", "SPINEL=#{ENV.fetch('SPINEL')}", "SPINEL_ROOT=#{ENV.fetch('SPINEL_ROOT')}",
        "FLEEK_RUNNER_PROBE_ROOT=#{root}", "FLEEK_RUNNER_PROBE_FAILURE=1", ENV.fetch("SPINEL"), "-E",
        "bin/check_runner.rb", "runner-probe", out: output, err: error)
    else
      Process.spawn("env", "JOBS=2", "SPINEL=#{ENV.fetch('SPINEL')}", "SPINEL_ROOT=#{ENV.fetch('SPINEL_ROOT')}",
        "FLEEK_RUNNER_PROBE_ROOT=#{root}", ENV.fetch("SPINEL"), "-E", "bin/check_runner.rb", "runner-probe",
        out: output, err: error)
    end
  end

  def self.wait_for_marker(path)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
    until File.exist?(path)
      return false if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
    end
    true
  end

  def self.verify_case_output(root, output, error, status, failure, third_started_before_release)
    expect(third_started_before_release, "third task started after slow task release")
    stdout = File.read(output)
    stderr = File.read(error)
    expect(File.exist?("#{root}/finished-slow"), "slow task was not reaped")
    second_task = failure ? "fail" : "fast"
    expect(File.exist?("#{root}/finished-#{second_task}"), "second task was not reaped")
    expect(File.exist?("#{root}/finished-third"), "third task was not reaped")
    if failure
      expect(!status.success?, "runner lost out-of-order failure status")
      expect(stdout.include?("Check probe fail: FAIL"), "failure was not attributed to failing task")
      expect(stdout.include?("Check probe slow: pass"), "slow task status was misattributed")
      expect(stdout.include?("Check probe third: pass"), "third task status was misattributed")
    else
      expect(status.success?, "successful runner probe failed: #{stderr}")
      expect(stdout.include?("Check probe fast: pass"), "fast task status was misattributed")
    end
  end

  def self.verify_worker_cleanup(root)
    process_id = Integer(File.read("#{root}/runner-pid"), 10)
    1.upto(3) do |serial|
      path = "/tmp/fleek-check-#{process_id}-#{serial}"
      expect(!Dir.exist?(path), "worker directory survived teardown: #{serial}")
      temporary_root = "/tmp/fleek-worker-#{process_id}-#{serial}"
      expect(!Dir.exist?(temporary_root), "worker temp directory survived teardown: #{serial}")
    end
  end

  def self.expect(condition, message)
    raise message unless condition
  end
end

CheckRunnerSchedulerContract.run
