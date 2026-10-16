require_relative "analysis_runner"

# Confirms configured Reek opt-in defaults match the pinned detector behavior.
class DefaultConfigurationContract
  OUTPUT = "/tmp/fleek-default-config.out"
  ERROR = "/tmp/fleek-default-config.err"
  SOURCE = "test/fixtures/unused_private_method.rb"
  SCOPED_SOURCE = "test/fixtures/disabled_scope/unused_private_method.rb"

  def self.run
    verify_reek_opt_in_reference
    verify_fleek_profile
    verify_scope_precedence
    puts "Default configuration contract: pass"
  ensure
    File.delete(OUTPUT) if File.exist?(OUTPUT)
    File.delete(ERROR) if File.exist?(ERROR)
  end

  def self.verify_reek_opt_in_reference
    enabled = run_reek("test/fixtures/config_unused_private_enabled.yml")
    disabled = run_reek("test/fixtures/config_unused_private_disabled.yml")
    verify(enabled[0] == 2 && enabled[1].include?("UnusedPrivateMethod"), "pinned Reek opt-in configuration changed")
    verify(disabled[0] == 0 && !disabled[1].include?("UnusedPrivateMethod"), "pinned Reek disabled configuration changed")
  end

  def self.verify_fleek_profile
    result = run_fleek("test/fixtures/config_unused_private_enabled.yml", SOURCE)
    selected, unsupported = profile_lines(result[1])
    verify(result[0] == 1, "configured unsupported default did not remain incomplete")
    verify(selected.include?("reek:UnusedPrivateMethod"), "configured Reek opt-in detector was not selected")
    verify(unsupported.include?("reek:UnusedPrivateMethod"), "configured Reek opt-in detector was hidden from coverage")
  end

  def self.verify_scope_precedence
    verify_reference_scope_precedence
    verify_fleek_scope_precedence
  end

  def self.verify_reference_scope_precedence
    enabled = run_reek("test/fixtures/config_unused_private_scope.yml", SCOPED_SOURCE)
    disabled = run_reek("test/fixtures/config_unused_private_scope.yml", SOURCE)
    verify(enabled[0] == 2 && enabled[1].include?("UnusedPrivateMethod"), "pinned Reek directory override precedence changed")
    verify(disabled[0] == 0 && !disabled[1].include?("UnusedPrivateMethod"), "pinned Reek parent directory disablement changed")
  end

  def self.verify_fleek_scope_precedence
    enabled = run_fleek("test/fixtures/config_unused_private_scope.yml", SCOPED_SOURCE)
    selected, unsupported = profile_lines(enabled[1])
    verify(enabled[0] == 1 && selected.include?("reek:UnusedPrivateMethod"), "Fleek did not apply the most specific Reek enablement")
    verify(unsupported.include?("reek:UnusedPrivateMethod"), "directory-enabled unsupported detector was hidden")
    verify_fleek_scope_disable
  end

  def self.verify_fleek_scope_disable
    disabled = run_fleek("test/fixtures/config_unused_private_scope.yml", SOURCE)
    selected, = profile_lines(disabled[1])
    verify(disabled[0] == 1 && !selected.include?("reek:UnusedPrivateMethod"), "Fleek ignored the parent directory disablement")
  end

  def self.run_fleek(config, source)
    process_id = Process.spawn(File.expand_path("../build/fleek", __dir__), "--reek-config", config, source, out: OUTPUT, err: ERROR)
    _, status = Process.waitpid2(process_id)
    output = File.read(OUTPUT)
    [status.exitstatus, output]
  end

  def self.profile_lines(output)
    [report_line(output, "Checks selected:"), report_line(output, "Checks unsupported:")]
  end

  def self.report_line(output, prefix)
    output.lines.find { |line| line.start_with?(prefix) }
  end

  def self.run_reek(config, source = SOURCE)
    process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "reek", "--smell", "UnusedPrivateMethod", "--config", config, source, out: OUTPUT, err: ERROR)
    AnalysisRunner.observe(process_id, OUTPUT, ERROR)
  end

  # :reek:ControlParameter
  def self.verify(condition, message)
    raise message unless condition
  end
end

DefaultConfigurationContract.run
