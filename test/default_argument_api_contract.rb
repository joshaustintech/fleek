# Compares default argument and method API findings with pinned Reek.
require_relative "analysis_runner"

# Compares supported argument checks and configuration against Reek.
class DefaultArgumentApiContract
  SOURCE = "test/fixtures/long_parameter_list.rb"

  # :reek:TooManyStatements
  def self.run
    reference = run_reek
    actual = run_fleek
    verify_run_coverage(actual)
    AnalysisRunner.assert_detector_findings(actual, reference, "LongParameterList")
    verify_initializer_override
    verify_boolean_parameter
    verify_long_yield_list
    verify_default_detector("ControlParameter", "test/fixtures/control_parameter.rb")
    verify_default_detector("UnusedParameters", "test/fixtures/unused_parameters.rb")
    verify_default_detector("UtilityFunction", "test/fixtures/utility_function.rb")
    verify_utility_configuration_limit
    verify_control_parameter_suppression
    verify_control_parameter_logical_condition
    verify_control_parameter_branch_logical_body
    verify_utility_instance_call
    verify_long_parameter_block_limit
    verify_discovered_unused_private_disable
    verify_long_parameter_configuration
    verify_long_yield_configuration
    verify_explicit_long_parameter_list
    verify_unused_private_opt_in
    puts "Default argument and method API contract: pass"
  end

  def self.verify_boolean_parameter
    verify_default_detector("BooleanParameter", "test/fixtures/boolean_parameter.rb")
  end

  def self.verify_long_yield_list
    verify_default_detector("LongYieldList", "test/fixtures/long_yield_list.rb")
    verify_default_detector("LongYieldList", "test/fixtures/yield_inside_block.rb")
  end

  def self.verify_long_yield_configuration
    source = "test/fixtures/long_yield_list.rb"
    config = "test/fixtures/config_long_yield_list.yml"
    reference = run_reek(source, "LongYieldList", config)
    actual = run_fleek(source, config)
    verify_configuration_parity(actual, reference, "LongYieldList")
  end

  def self.verify_explicit_long_parameter_list
    reference = run_reek
    actual = run_fleek(SOURCE, "", "reek:LongParameterList")
    AnalysisRunner.assert_detector_findings(actual, reference, "LongParameterList")
  end

  def self.verify_utility_configuration_limit
    actual = run_fleek("test/fixtures/utility_function.rb", "test/fixtures/config_utility_public_methods.yml")
    verify(actual[0] == 1, "UtilityFunction visibility configuration did not remain incomplete")
    verify(actual[2].include?("UtilityFunction supports"), "UtilityFunction configuration limit was not reported")
  end

  def self.verify_unused_private_opt_in
    actual = run_fleek("test/fixtures/unused_private_method.rb", "", "reek:UnusedPrivateMethod")
    verify(actual[0] == 1, "selected UnusedPrivateMethod did not remain incomplete")
    verify(actual[1].include?("Checks unsupported: reek:UnusedPrivateMethod"), "selected UnusedPrivateMethod was omitted from coverage")
    verify_unused_private_disabled
  end

  def self.verify_unused_private_disabled
    disabled = run_fleek("test/fixtures/unused_private_method.rb", "test/fixtures/config_unused_private_disabled.yml", "reek:UnusedPrivateMethod")
    verify(disabled[0] == 0, "configured disabled UnusedPrivateMethod did not stay clean")
    verify(disabled[1].include?("Checks disabled: reek:UnusedPrivateMethod"), "configured disabled UnusedPrivateMethod was not reported disabled")
  end

  # :reek:TooManyStatements
  def self.verify_discovered_unused_private_disable
    directory = "/tmp/fleek-opt-in-config-#{Process.pid}"
    Dir.mkdir(directory)
    File.write("#{directory}/.reek.yml", File.read("test/fixtures/config_unused_private_disabled.yml"))
    source = File.expand_path("test/fixtures/unused_private_method.rb")
    process_id = Process.spawn(File.expand_path("../build/fleek", __dir__), "--checks", "reek:UnusedPrivateMethod", source,
      out: "/tmp/fleek-opt-in-discovered.out", err: "/tmp/fleek-opt-in-discovered.err", chdir: directory)
    _, status = Process.waitpid2(process_id)
    output = File.read("/tmp/fleek-opt-in-discovered.out")
    verify(status.exitstatus == 0, "discovered disabled UnusedPrivateMethod did not stay clean")
    verify(output.include?("Checks disabled: reek:UnusedPrivateMethod"), "discovered disabled UnusedPrivateMethod was not reported disabled")
  ensure
    File.delete("#{directory}/.reek.yml") if directory && File.file?("#{directory}/.reek.yml")
    Dir.rmdir(directory) if directory && Dir.exist?(directory)
  end

  def self.verify_control_parameter_suppression
    verify_default_detector("ControlParameter", "test/fixtures/control_parameter_used_in_body.rb")
  end

  def self.verify_control_parameter_logical_condition
    verify_default_detector("ControlParameter", "test/fixtures/control_parameter_logical.rb")
  end

  def self.verify_control_parameter_branch_logical_body
    verify_default_detector("ControlParameter", "test/fixtures/control_parameter_branch_logical.rb")
  end

  def self.verify_utility_instance_call
    verify_default_detector("UtilityFunction", "test/fixtures/utility_instance_method_call.rb")
  end

  def self.verify_long_parameter_block_limit
    actual = run_fleek("test/fixtures/long_parameter_block.rb")
    verify(actual[0] == 1, "LongParameterList block scope appeared clean")
    verify(actual[2].include?("LongParameterList supports"), "LongParameterList block scope was not reported unsupported")
  end

  def self.verify_long_parameter_configuration
    config = "test/fixtures/config_long_parameter_list.yml"
    reference = run_reek(SOURCE, "LongParameterList", config)
    actual = run_fleek(SOURCE, config)
    verify_configuration_parity(actual, reference, "LongParameterList")
  end

  def self.verify_configuration_parity(actual, reference, detector)
    verify(reference[0] == 0 && reference[2].empty?, "pinned #{detector} configuration failed")
    verify(!actual[2].include?("Reek configuration"), "Fleek rejected #{detector} configuration")
    AnalysisRunner.assert_detector_findings(actual, reference, detector)
  end

  def self.verify_default_detector(detector, source)
    reference = run_reek(source, detector)
    actual = run_fleek(source)
    verify_default_coverage(actual, detector)
    AnalysisRunner.assert_detector_findings(actual, reference, detector)
  end

  def self.verify_initializer_override
    source = "test/fixtures/initialize_parameter_list.rb"
    reference = run_reek(source)
    actual = run_fleek(source)
    AnalysisRunner.assert_detector_findings(actual, reference, "LongParameterList")
  end

  def self.verify_run_coverage(actual)
    verify_default_coverage(actual, "LongParameterList")
  end

  def self.verify_default_coverage(actual, detector)
    output = actual[1]
    checks = output_line(output, "Checks run:")
    verify(checks&.include?("reek:#{detector}"), "default invocation did not run #{detector}")
    unsupported = output_line(output, "Checks unsupported:")
    verify(!unsupported&.include?("reek:#{detector}"), "#{detector} remained unsupported")
  end

  def self.output_line(output, prefix)
    output.lines.find { |line| line.start_with?(prefix) }
  end

  def self.run_reek(source = SOURCE, detector = "LongParameterList", config = "")
    bundle = ENV["BUNDLE"] || "bundle"
    process_id = if config.empty?
                   Process.spawn(bundle, "exec", "reek", "--smell", detector, source, out: "/tmp/fleek-argument-reek.out", err: "/tmp/fleek-argument-reek.err")
                 else
                   Process.spawn(bundle, "exec", "reek", "--smell", detector, "--config", config, source, out: "/tmp/fleek-argument-reek.out", err: "/tmp/fleek-argument-reek.err")
                 end
    AnalysisRunner.observe(process_id, "/tmp/fleek-argument-reek.out", "/tmp/fleek-argument-reek.err")
  end

  # :reek:TooManyStatements
  def self.run_fleek(source = SOURCE, config = "", check = "")
    has_check = !check.empty?
    has_config = !config.empty?
    process_id = if has_check && has_config
                   Process.spawn("build/fleek", "--checks", check, "--reek-config", config, source, out: "/tmp/fleek-argument-fleek.out", err: "/tmp/fleek-argument-fleek.err")
                 elsif has_check
                   Process.spawn("build/fleek", "--checks", check, source, out: "/tmp/fleek-argument-fleek.out", err: "/tmp/fleek-argument-fleek.err")
                 elsif !has_config
                   Process.spawn("build/fleek", source, out: "/tmp/fleek-argument-fleek.out", err: "/tmp/fleek-argument-fleek.err")
                 else
                   Process.spawn("build/fleek", "--reek-config", config, source, out: "/tmp/fleek-argument-fleek.out", err: "/tmp/fleek-argument-fleek.err")
                 end
    AnalysisRunner.observe(process_id, "/tmp/fleek-argument-fleek.out", "/tmp/fleek-argument-fleek.err")
  end

  # :reek:ControlParameter
  def self.verify(condition, message)
    raise message unless condition
  end
end

DefaultArgumentApiContract.run
