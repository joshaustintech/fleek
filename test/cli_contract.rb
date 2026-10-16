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
raise "help supported coverage missing" unless help_result[1].include?("Supported checks: reek:Attribute, reek:ClassVariable, reek:InstanceVariableAssumption, reek:IrresponsibleModule, reek:ModuleInitialize, reek:SubclassedFromCoreClass, and flay:StructuralDuplication")
raise "help Flay mass option missing" unless help_result[1].include?("flay:StructuralDuplication [--mass MASS] SOURCE")
raise "help unsupported capabilities missing" unless help_result[1].include?("machine formats are unsupported")
raise "help explicit selection missing" unless help_result[1].include?("Analysis requires --checks")
raise "help report contract missing" unless help_result[1].include?("stable text v1")
raise "help stderr" unless help_result[2] == ""

version_result = cli_process.with_argument("--version")
raise "version status" unless version_result[0] == 0
raise "version references" unless version_result[1].include?("Flay 2.14.4")
raise "version coverage missing" unless version_result[1].include?("supported checks: reek:Attribute, reek:ClassVariable, reek:InstanceVariableAssumption, reek:IrresponsibleModule, reek:ModuleInitialize, reek:SubclassedFromCoreClass, flay:StructuralDuplication")
raise "version unsupported capabilities missing" unless version_result[1].include?("machine formats are rejected")
raise "version explicit selection missing" unless version_result[1].include?("requires explicit --checks selection")
raise "version report contract missing" unless version_result[1].include?("report: text v1")

unsupported_result = cli_process.with_unknown_check
raise "unsupported check status" unless unsupported_result[0] == 1
raise "unsupported check diagnostic" unless unsupported_result[2].include?("unsupported")


puts "CLI contract: pass"
