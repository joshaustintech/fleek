# frozen_string_literal: true

require_relative "analysis_runner"

# Checks Flay timeout controls and truthful incomplete reporting.
# :reek:DuplicateMethodCall
# :reek:TooManyStatements
class DuplicationTimeoutContract
  PATH = "test/fixtures/duplication_class_methods_rails_pair.rb"
  BUNDLE = ENV["BUNDLE"] || "bundle"

  def self.run
    verify_zero_and_positive
    verify_invalid_value
    verify_negative_value
    verify_last_value
    verify_combined_positive_value
    verify_combined_negative_value
    verify_timeout_expiry
    verify_per_file_timeout_continuation
    verify_timer_command_is_not_exposed
    puts "Flay timeout contract: pass"
  end

  def self.verify_zero_and_positive
    ["0", "60"].each do |timeout|
      reference = invoke("flay", ["--timeout", timeout])
      actual = invoke("fleek", ["--timeout", timeout])
      AnalysisRunner.assert_report_contains(reference, [0, ["Total score (lower is better) = 48", "mass = 48"], "Flay --timeout #{timeout} reference changed"])
      AnalysisRunner.assert_report_contains(actual, [2, ["Total duplication score: 48", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"], "Fleek --timeout #{timeout} changed complete analysis"])
      raise "Flay --timeout #{timeout} wrote to stderr" unless reference[2].empty?
      raise "Fleek --timeout #{timeout} wrote to stderr" unless actual[2].empty?
    end
  end

  def self.verify_invalid_value
    reference = invoke("flay", ["--timeout", "invalid"])
    actual = invoke("fleek", ["--timeout", "invalid"])
    assert_timeout_result(reference, [1, [], "invalid argument", "Flay malformed timeout was accepted"])
    assert_timeout_result(actual, [1, [], "--timeout requires an integer number of seconds", "Fleek malformed timeout was accepted"])
  end

  def self.verify_negative_value
    reference = invoke("flay", ["--timeout", "-1"])
    actual = invoke("fleek", ["--timeout", "-1"])
    assert_timeout_result(reference, [0, ["Total score (lower is better) = 0"], "Timeout sec must be a non-negative number", "Flay negative timeout behavior changed"])
    assert_timeout_result(actual, [1, ["Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"], "timeout", "negative timeout was not reported as incomplete"])
  end

  def self.verify_last_value
    reference = invoke("flay", ["--timeout", "-1", "--timeout", "0"])
    actual = invoke("fleek", ["--timeout", "-1", "--timeout", "0"])
    assert_timeout_result(reference, [0, ["Total score (lower is better) = 48"], "", "Flay repeated timeout did not use its last value"])
    assert_timeout_result(actual, [2, ["Total duplication score: 48", "Status: findings"], "", "Fleek repeated timeout did not use its last value"])
  end

  def self.verify_combined_negative_value
    output = "/tmp/flay-timeout-combined-#{Process.pid}.out"
    error = "/tmp/flay-timeout-combined-#{Process.pid}.err"
    process_id = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication,reek:ClassVariable", "--timeout", "-1", PATH, out: output, err: error)
    actual = AnalysisRunner.observe(process_id, output, error)
    AnalysisRunner.assert_report_contains(actual, [1, ["Duplication coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Smell coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Overall status: incomplete"], "combined negative timeout did not preserve incomplete coverage"])
    raise "combined negative timeout omitted its diagnostic" unless actual[2].include?("timeout")
  end

  def self.verify_combined_positive_value
    output = "/tmp/flay-timeout-combined-positive-#{Process.pid}.out"
    error = "/tmp/flay-timeout-combined-positive-#{Process.pid}.err"
    process_id = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication,reek:ClassVariable", "--timeout", "60", PATH, out: output, err: error)
    actual = AnalysisRunner.observe(process_id, output, error)
    AnalysisRunner.assert_report_contains(actual, [2, ["Total duplication score: 48", "Duplication coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Smell coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Overall status: findings"], "combined positive timeout changed analysis"])
    raise "combined positive timeout wrote to stderr" unless actual[2].empty?
  end

  def self.verify_timeout_expiry
    path = "/tmp/flay-timeout-slow-#{Process.pid}.rb"
    write_timeout_source(path)
    actual = invoke("fleek", ["--timeout", "1"], path)
    assert_timeout_result(actual, [1, ["Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"], "timeout after 1 seconds", "positive timeout did not interrupt native parsing"])
  ensure
    File.delete(path) if File.file?(path)
  end

  # :reek:TooManyStatements
  def self.verify_per_file_timeout_continuation
    slow_path = "/tmp/flay-timeout-slow-pair-#{Process.pid}.rb"
    write_timeout_source(slow_path)
    paths = [slow_path, PATH]
    reference = invoke("flay", ["--timeout", "1"], paths)
    raise "Flay did not retain the fast source result after timeout" unless reference[0] == 0 &&
      reference[1].include?("Total score (lower is better) = 48") &&
      reference[2].include?("TIMEOUT parsing #{slow_path}. Skipping.")

    actual = invoke("fleek", ["--timeout", "1"], paths)
    AnalysisRunner.assert_report_contains(actual, [1, [
      "Source: #{slow_path.inspect} scope=failed",
      "Source: #{PATH.inspect} scope=included",
      "Total duplication score: 48",
      "Group: check=\"flay:StructuralDuplication\" node=\"defn\" kind=\"similar\" locations=\"#{PATH}:2,#{PATH}:9\" mass=48 score=48",
      "Coverage: 2 selected; 1 analyzed; 1 failed; 0 excluded",
      "Status: incomplete"
    ], "Fleek per-file timeout did not retain the completed source result"])
    raise "Fleek per-file timeout omitted the skipped source diagnostic" unless actual[2].include?("#{slow_path}") && actual[2].include?("timeout")
  ensure
    File.delete(slow_path) if slow_path && File.file?(slow_path)
  end

  def self.write_timeout_source(path)
    body = "x\n" * 8_000_000
    File.write(path, "def first\n#{body}end\ndef second\n#{body}end\n")
  end

  def self.verify_timer_command_is_not_exposed
    process_id = Process.spawn("/bin/sleep", "10", out: "/dev/null", err: "/dev/null")
    output = "/tmp/flay-timeout-internal-#{Process.pid}.out"
    error = "/tmp/flay-timeout-internal-#{Process.pid}.err"
    fleek = File.expand_path("../build/fleek", __dir__)
    command_id = Process.spawn(fleek, "--timeout-killer", process_id.to_s, "1", output, out: output, err: error)
    _, status = Process.waitpid2(command_id)
    raise "internal timer command was exposed" unless status.exitstatus == 1
    Process.kill(0, process_id)
  rescue SystemCallError
    raise "internal timer command killed a user process"
  ensure
    stop_test_process(process_id) if process_id
    [output, error].each { |path| File.delete(path) if path && File.file?(path) }
  end

  def self.stop_test_process(process_id)
    Process.kill("KILL", process_id)
    Process.waitpid2(process_id)
  rescue SystemCallError
    nil
  end

  def self.assert_timeout_result(result, expectation)
    status, fields, diagnostic, label = expectation
    AnalysisRunner.assert_report_contains(result, [status, fields, label])
    raise label unless result[2].index(diagnostic) != nil
  end

  def self.invoke(tool, options, path = PATH)
    output = "/tmp/flay-timeout-#{tool}-#{Process.pid}.out"
    error = "/tmp/flay-timeout-#{tool}-#{Process.pid}.err"
    executable = File.expand_path("../build/fleek", __dir__)
    paths = path.is_a?(Array) ? path : [path]
    process_id = if tool == "flay" && options.length == 2 && paths.length == 1
      Process.spawn(BUNDLE, "exec", "flay", options[0], options[1], paths[0], out: output, err: error)
    elsif tool == "flay" && options.length == 2
      Process.spawn(BUNDLE, "exec", "flay", options[0], options[1], paths[0], paths[1], out: output, err: error)
    elsif tool == "flay"
      Process.spawn(BUNDLE, "exec", "flay", options[0], options[1], options[2], options[3], paths[0], out: output, err: error)
    elsif options.length == 2 && paths.length == 1
      Process.spawn(executable, "--checks", "flay:StructuralDuplication", options[0], options[1], paths[0], out: output, err: error)
    elsif options.length == 2
      Process.spawn(executable, "--checks", "flay:StructuralDuplication", options[0], options[1], paths[0], paths[1], out: output, err: error)
    else
      Process.spawn(executable, "--checks", "flay:StructuralDuplication", options[0], options[1], options[2], options[3], paths[0], out: output, err: error)
    end
    AnalysisRunner.observe(process_id, output, error)
  end
end

DuplicationTimeoutContract.run
