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

  def with_inapplicable_option(check, option_arguments)
    process_id = Process.spawn("build/fleek", "--checks", check, option_arguments[0], option_arguments[1], option_arguments[2], out: @output_path, err: @error_path)
    observe(process_id)
  end

  def with_inapplicable_flag(check, flag, path)
    process_id = Process.spawn("build/fleek", "--checks", check, flag, path, out: @output_path, err: @error_path)
    observe(process_id)
  end

  def with_combined_liberal(path)
    process_id = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication,reek:ClassVariable", "--liberal", path,
      out: @output_path, err: @error_path)
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
raise "help Flay options missing" unless help_result[1].include?("flay:StructuralDuplication [--mass MASS] [--timeout SECONDS] [--liberal] [--fuzzy [DIFF]] [--legacy] [-#] [--only NODE] SOURCE")
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

inapplicable_mass = cli_process.with_inapplicable_option("reek:ClassVariable", ["--mass", "16", "test/fixtures/class_variable.rb"])
raise "inapplicable Flay mass status" unless inapplicable_mass[0] == 1
raise "inapplicable Flay mass was not rejected before Reek analysis" unless inapplicable_mass[2].include?("--mass applies only to flay:StructuralDuplication") && inapplicable_mass[1].empty?
inapplicable_only = cli_process.with_inapplicable_option("reek:ClassVariable", ["--only", "defn", "test/fixtures/class_variable.rb"])
raise "inapplicable Flay only status" unless inapplicable_only[0] == 1
raise "inapplicable Flay only was not rejected before Reek analysis" unless inapplicable_only[2].include?("--only applies only to flay:StructuralDuplication") && inapplicable_only[1].empty?

inapplicable_liberal = cli_process.with_inapplicable_flag("reek:ClassVariable", "--liberal", "test/fixtures/class_variable.rb")
raise "inapplicable Flay liberal status" unless inapplicable_liberal[0] == 1
raise "inapplicable Flay liberal was not rejected before Reek analysis" unless inapplicable_liberal[2].include?("--liberal applies only to flay:StructuralDuplication") && inapplicable_liberal[1].empty?

inapplicable_reek_config = cli_process.with_inapplicable_option("flay:StructuralDuplication", ["--reek-config", "test/fixtures/reference.rb", "test/fixtures/reference.rb"])
raise "inapplicable Reek config status" unless inapplicable_reek_config[0] == 1
raise "inapplicable Reek config was not rejected before Flay analysis" unless inapplicable_reek_config[2].include?("--reek-config applies only to Reek checks") && inapplicable_reek_config[1].empty?

combined_liberal = cli_process.with_combined_liberal("test/fixtures/duplication_class_methods_rails_pair.rb")
raise "combined Flay liberal status" unless combined_liberal[0] == 2
raise "combined Flay liberal routing" unless combined_liberal[1].include?("Duplication section:") && combined_liberal[1].include?("Smell section:") &&
  combined_liberal[1].include?("Total duplication score: 48") && combined_liberal[1].include?("Overall status: findings") && combined_liberal[2].empty?


puts "CLI contract: pass"
