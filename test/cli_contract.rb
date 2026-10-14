# Captures native process output for public CLI behavior checks.
class CliProcess
  def initialize
    @output_path = "/tmp/fleek-cli-contract-out"
    @error_path = "/tmp/fleek-cli-contract-err"
  end

  def with_argument(argument)
    process_id = Process.spawn("build/fleek", argument, out: @output_path, err: @error_path)
    observe(process_id)
  end

  def without_arguments
    process_id = Process.spawn("build/fleek", out: @output_path, err: @error_path)
    observe(process_id)
  end

  def with_unknown_check
    process_id = Process.spawn("build/fleek", "--checks", "flay:default", ".", out: @output_path, err: @error_path)
    observe(process_id)
  end

  def observe(process_id)
    finished_pid, process_status = Process.waitpid2(process_id)
    [process_status.exitstatus, File.read(@output_path), File.read(@error_path)]
  end
end

cli_process = CliProcess.new
help_result = cli_process.with_argument("--help")
raise "help status" unless help_result[0] == 0
raise "help usage" unless help_result[1].include?("Usage:")
raise "help parser prototype" unless help_result[1].include?("--parse-ruby4 SOURCE")
raise "help named stdin" unless help_result[1].include?("--stdin SOURCE [PATH...]")
raise "help Reek config" unless help_result[1].include?("--reek-config FILE")
raise "help stderr" unless help_result[2] == ""

usage_result = cli_process.without_arguments
raise "empty invocation status" unless usage_result[0] == 1
raise "empty invocation stdout" unless usage_result[1] == ""
raise "empty invocation usage" unless usage_result[2].include?("Usage:")

version_result = cli_process.with_argument("--version")
raise "version status" unless version_result[0] == 0
raise "version references" unless version_result[1].include?("Flay 2.14.4")

unsupported_result = cli_process.with_unknown_check
raise "unsupported check status" unless unsupported_result[0] == 1
raise "unsupported check diagnostic" unless unsupported_result[2].include?("unsupported")


puts "CLI contract: pass"
