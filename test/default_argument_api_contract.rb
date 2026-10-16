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
    verify_default_detector("DuplicateMethodCall", "test/fixtures/duplicate_method_call.rb")
    verify_configured_detector("DuplicateMethodCall", "test/fixtures/duplicate_method_call.rb", "test/fixtures/config_duplicate_method_call.yml")
    verify_configured_detector("DuplicateMethodCall", "test/fixtures/duplicate_method_call.rb", "test/fixtures/config_duplicate_method_call_allow.yml")
    verify_configured_detector("DuplicateMethodCall", "test/fixtures/duplicate_method_call.rb", "test/fixtures/config_duplicate_method_call_multiple_allow.yml")
    verify_default_detector("ManualDispatch", "test/fixtures/manual_dispatch.rb")
    verify_default_detector("NilCheck", "test/fixtures/nil_check.rb")
    verify_default_detector("MissingSafeMethod", "test/fixtures/missing_safe_method.rb")
    verify_configured_detector("MissingSafeMethod", "test/fixtures/missing_safe_method.rb", "test/fixtures/config_missing_safe_method_exclude.yml")
    verify_configured_detector("MissingSafeMethod", "test/fixtures/missing_safe_method.rb", "test/fixtures/config_missing_safe_method_multiple_exclude.yml")
    verify_default_detector("RepeatedConditional", "test/fixtures/repeated_conditional.rb")
    verify_configured_detector("RepeatedConditional", "test/fixtures/repeated_conditional.rb", "test/fixtures/config_repeated_conditional.yml")
    verify_default_detector("NestedIterators", "test/fixtures/nested_iterators.rb")
    verify_configured_detector("NestedIterators", "test/fixtures/nested_iterators.rb", "test/fixtures/config_nested_iterators.yml")
    verify_configured_detector("NestedIterators", "test/fixtures/nested_iterators.rb", "test/fixtures/config_nested_iterators_ignore.yml")
    verify_configured_detector("NestedIterators", "test/fixtures/nested_iterators.rb", "test/fixtures/config_nested_iterators_multiple_ignore.yml")
    verify_default_detector("FeatureEnvy", "test/fixtures/feature_envy.rb")
    verify_supported_default_detector("DataClump", "test/fixtures/data_clump.rb")
    verify_supported_default_detector("DataClump", "test/fixtures/data_clump_after_empty_method.rb")
    verify_supported_default_detector("DataClump", "test/fixtures/data_clump_multiple_groups.rb")
    verify_data_clump_preserves_supported_findings
    verify_supported_default_detector("TooManyConstants", "test/fixtures/too_many_constants.rb")
    verify_supported_default_detector("TooManyInstanceVariables", "test/fixtures/too_many_instance_variables.rb")
    verify_supported_default_detector("TooManyMethods", "test/fixtures/too_many_methods.rb")
    verify_supported_default_detector("TooManyStatements", "test/fixtures/too_many_statements.rb")
    verify_too_many_statements_class_method
    verify_unsupported_singleton_class_methods
    verify_configured_detector("TooManyStatements", "test/fixtures/too_many_statements.rb", "test/fixtures/config_too_many_statements.yml")
    verify_configured_detector("DataClump", "test/fixtures/data_clump.rb", "test/fixtures/config_data_clump.yml")
    verify_configured_detector("TooManyConstants", "test/fixtures/too_many_constants.rb", "test/fixtures/config_too_many_constants.yml")
    verify_configured_detector("TooManyInstanceVariables", "test/fixtures/too_many_instance_variables.rb", "test/fixtures/config_too_many_instance_variables.yml")
    verify_configured_detector("TooManyMethods", "test/fixtures/too_many_methods.rb", "test/fixtures/config_too_many_methods.yml")
    verify_configured_detector("DataClump", "test/fixtures/data_clump.rb", "test/fixtures/config_data_and_size_exclusions.yml")
    verify_configured_detector("TooManyConstants", "test/fixtures/too_many_constants.rb", "test/fixtures/config_data_and_size_exclusions.yml")
    verify_configured_detector("TooManyInstanceVariables", "test/fixtures/too_many_instance_variables.rb", "test/fixtures/config_data_and_size_exclusions.yml")
    verify_configured_detector("TooManyMethods", "test/fixtures/too_many_methods.rb", "test/fixtures/config_data_and_size_exclusions.yml")
    verify_unsupported_data_and_size_scopes
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

  def self.verify_configured_detector(detector, source, config)
    reference = run_reek(source, detector, config)
    actual = run_fleek(source, config)
    verify_configuration_parity(actual, reference, detector)
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
    verify_detector_parity(detector, source, false)
  end

  def self.verify_supported_default_detector(detector, source)
    verify_detector_parity(detector, source, true)
  end

  def self.verify_unsupported_data_and_size_scopes
    source = "test/fixtures/class_variable_nested.rb"
    detectors = %w[DataClump TooManyConstants TooManyInstanceVariables TooManyMethods TooManyStatements]
    detectors.each do |detector|
      result = run_fleek(source, "", "reek:#{detector}")
      AnalysisRunner.assert_unsupported(result, detector)
    end
  end

  def self.verify_too_many_statements_class_method
    verify_detector_parity("TooManyStatements", "test/fixtures/too_many_statements.rb", true)
    verify_class_method_finding
  end

  def self.verify_class_method_finding
    reference = run_reek("test/fixtures/too_many_statements.rb", "TooManyStatements")
    findings = AnalysisRunner.detector_warnings(reference, "TooManyStatements")
    verify(findings.any? { |finding| finding.include?("Workflow#self.dispatch") }, "pinned Reek class-method fixture has no finding")
  end

  def self.verify_unsupported_singleton_class_methods
    source = "test/fixtures/too_many_statements_singleton_class.rb"
    reference = run_reek(source, "TooManyStatements")
    actual = run_fleek(source, "", "reek:TooManyStatements")
    verify(reference[0] == 2 && !AnalysisRunner.detector_warnings(reference, "TooManyStatements").empty?, "pinned Reek singleton-class fixture has no finding")
    AnalysisRunner.assert_unsupported(actual, "TooManyStatements singleton-class method")
  end

  def self.verify_data_clump_preserves_supported_findings
    verify_data_clump_mixed_syntax_parity
  end

  def self.verify_data_clump_mixed_syntax_parity
    actual, reference = data_clump_mixed_syntax_runs
    verify_data_clump_mixed_result(actual, reference)
  end

  def self.data_clump_mixed_syntax_runs
    source = "test/fixtures/data_clump_with_unsupported_method.rb"
    reference = run_reek(source, "DataClump")
    actual = run_fleek(source, "", "reek:DataClump")
    [actual, reference]
  end

  def self.verify_data_clump_mixed_result(actual, reference)
    verify_data_clump_mixed_findings(actual, reference)
    AnalysisRunner.assert_unsupported(actual, "DataClump unsupported method")
    verify(actual[1].include?("Status: incomplete"), "DataClump mixed syntax did not report incomplete status")
  end

  def self.verify_data_clump_mixed_findings(actual, reference)
    AnalysisRunner.assert_detector_findings(actual, reference, "DataClump")
  end

  # :reek:ControlParameter
  # :reek:TooManyStatements
  def self.verify_detector_parity(detector, source, require_finding)
    reference = run_reek(source, detector)
    actual = run_fleek(source)
    explicit = run_fleek(source, "", "reek:#{detector}")
    verify_default_coverage(actual, detector)
    AnalysisRunner.assert_detector_findings(actual, reference, detector)
    AnalysisRunner.assert_detector_findings(explicit, reference, detector)
    return unless require_finding

    expected = AnalysisRunner.detector_warnings(reference, detector)
    verify(!expected.empty?, "pinned #{detector} fixture has no finding")
    verify(AnalysisRunner.detector_warnings(actual, detector).sort == expected.sort, "#{detector} finding was not preserved")
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
