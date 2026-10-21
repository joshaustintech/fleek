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
    verify_boolean_parameter_singleton
    verify_long_yield_list
    verify_default_detector("ControlParameter", "test/fixtures/control_parameter.rb")
    verify_default_detector("UnusedParameters", "test/fixtures/unused_parameters.rb")
    verify_unused_parameter_block_shadowing
    verify_default_detector("UtilityFunction", "test/fixtures/utility_function.rb")
    verify_default_detector("DuplicateMethodCall", "test/fixtures/duplicate_method_call.rb")
    verify_configured_detector("DuplicateMethodCall", "test/fixtures/duplicate_method_call.rb", "test/fixtures/config_duplicate_method_call.yml")
    verify_configured_detector("DuplicateMethodCall", "test/fixtures/duplicate_method_call.rb", "test/fixtures/config_duplicate_method_call_allow.yml")
    verify_configured_detector("DuplicateMethodCall", "test/fixtures/duplicate_method_call.rb", "test/fixtures/config_duplicate_method_call_multiple_allow.yml")
    verify_duplicate_method_call_nested_branches
    verify_default_detector("ManualDispatch", "test/fixtures/manual_dispatch.rb")
    verify_nil_check_nested_block
    verify_default_detector("NilCheck", "test/fixtures/nil_check.rb")
    verify_default_detector("MissingSafeMethod", "test/fixtures/missing_safe_method.rb")
    verify_missing_safe_method_singleton_companions
    verify_configured_detector("MissingSafeMethod", "test/fixtures/missing_safe_method.rb", "test/fixtures/config_missing_safe_method_exclude.yml")
    verify_configured_detector("MissingSafeMethod", "test/fixtures/missing_safe_method.rb", "test/fixtures/config_missing_safe_method_multiple_exclude.yml")
    verify_manual_dispatch_nested_guard
    verify_default_detector("RepeatedConditional", "test/fixtures/repeated_conditional.rb")
    verify_configured_detector("RepeatedConditional", "test/fixtures/repeated_conditional.rb", "test/fixtures/config_repeated_conditional.yml")
    verify_repeated_conditional_nested_classes
    verify_nested_iterator_ignored_name
    verify_default_detector("NestedIterators", "test/fixtures/nested_iterators.rb")
    verify_configured_detector("NestedIterators", "test/fixtures/nested_iterators.rb", "test/fixtures/config_nested_iterators.yml")
    verify_configured_detector("NestedIterators", "test/fixtures/nested_iterators.rb", "test/fixtures/config_nested_iterators_ignore.yml")
    verify_configured_detector("NestedIterators", "test/fixtures/nested_iterators.rb", "test/fixtures/config_nested_iterators_multiple_ignore.yml")
    verify_default_detector("FeatureEnvy", "test/fixtures/feature_envy.rb")
    verify_feature_envy_block_receivers
    verify_supported_default_detector("DataClump", "test/fixtures/data_clump.rb")
    verify_data_clump_singleton_methods
    verify_supported_default_detector("DataClump", "test/fixtures/data_clump_after_empty_method.rb")
    verify_supported_default_detector("DataClump", "test/fixtures/data_clump_multiple_groups.rb")
    verify_data_clump_preserves_supported_findings
    verify_supported_default_detector("TooManyConstants", "test/fixtures/too_many_constants.rb")
    verify_too_many_constants_nested_modules
    verify_supported_default_detector("TooManyInstanceVariables", "test/fixtures/too_many_instance_variables.rb")
    verify_supported_default_detector("TooManyInstanceVariables", "test/fixtures/too_many_instance_variable_operator_writes.rb")
    verify_too_many_instance_variables_nested_classes
    verify_supported_default_detector("TooManyMethods", "test/fixtures/too_many_methods.rb")
    verify_too_many_methods_nested_classes
    verify_too_many_methods_mixed_nested_definition
    verify_supported_default_detector("TooManyStatements", "test/fixtures/too_many_statements.rb")
    verify_supported_default_detector("UncommunicativeMethodName", "test/fixtures/uncommunicative_method_name.rb")
    verify_configured_detector("UncommunicativeMethodName", "test/fixtures/uncommunicative_method_name.rb", "test/fixtures/config_uncommunicative_method_name.yml")
    verify_supported_default_detector("UncommunicativeModuleName", "test/fixtures/uncommunicative_module_name.rb")
    verify_configured_detector("UncommunicativeModuleName", "test/fixtures/uncommunicative_module_name.rb", "test/fixtures/config_uncommunicative_module_name.yml")
    verify_supported_default_detector("UncommunicativeParameterName", "test/fixtures/uncommunicative_parameter_name.rb")
    verify_configured_detector("UncommunicativeParameterName", "test/fixtures/uncommunicative_parameter_name.rb", "test/fixtures/config_uncommunicative_parameter_name.yml")
    verify_supported_default_detector("UncommunicativeVariableName", "test/fixtures/uncommunicative_variable_name.rb")
    verify_configured_detector("UncommunicativeVariableName", "test/fixtures/uncommunicative_variable_name.rb", "test/fixtures/config_uncommunicative_variable_name.yml")
    verify_unsupported_naming_scopes
    verify_too_many_statements_class_method
    verify_unsupported_singleton_class_methods
    verify_configured_detector("TooManyStatements", "test/fixtures/too_many_statements_singleton_class.rb", "test/fixtures/config_too_many_statements.yml")
    verify_too_many_statements_mixed_unsupported_body
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
    verify_nested_control_parameter_loop
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

  # :reek:TooManyStatements
  def self.verify_boolean_parameter_singleton
    source = "test/fixtures/boolean_parameter_singleton_positional.rb"
    reference = run_reek(source, "BooleanParameter")
    actual = run_fleek(source, "", "reek:BooleanParameter")
    verify(reference[0] == 2 && reference[1].include?("[2]:BooleanParameter: Parcel#self.requeue has boolean parameter 'force'"), "pinned singleton BooleanParameter finding changed")
    AnalysisRunner.assert_status(actual, reference, "singleton BooleanParameter")
    AnalysisRunner.assert_detector_findings(actual, reference, "singleton BooleanParameter")
    verify_boolean_parameter_singleton_disabled(source)
  end

  def self.verify_boolean_parameter_singleton_disabled(source)
    config = "test/fixtures/config_boolean_parameter_disabled.yml"
    reference = run_reek(source, "BooleanParameter", config)
    actual = run_fleek(source, config, "reek:BooleanParameter")
    verify(reference[0] == 0 && AnalysisRunner.warning_lines(reference[1]).empty?, "pinned BooleanParameter disablement changed")
    verify(actual[0] == 1 && actual[2].include?("BooleanParameter is disabled by configuration"), "explicit BooleanParameter disablement was ignored")
  end

  # :reek:TooManyStatements
  def self.verify_too_many_constants_nested_modules
    source = "test/fixtures/too_many_constants_nested_modules.rb"
    reference = run_reek(source, "TooManyConstants")
    actual = run_fleek(source, "", "reek:TooManyConstants")
    findings = AnalysisRunner.detector_warnings(reference, "TooManyConstants")
    verify(reference[0] == 2 && findings.size == 1 && findings.first.include?("Fleet::Shipment has 6 constants"),
      "pinned TooManyConstants nested module isolation changed")
    AnalysisRunner.assert_status(actual, reference, "nested TooManyConstants default threshold")
    AnalysisRunner.assert_detector_findings(actual, reference, "nested TooManyConstants default threshold")
    unsupported = run_fleek("test/fixtures/too_many_constants_deep_modules.rb", "", "reek:TooManyConstants")
    unsupported_output = unsupported[1]
    verify(unsupported[0] == 1 && unsupported_output.include?("Status: incomplete") &&
      unsupported_output.include?("Scope limits:") && unsupported_output.include?("Coverage: 1 selected; 0 analyzed; 1 failed"),
      "unsupported nested TooManyConstants scope was not reported incomplete")

    config = "test/fixtures/config_too_many_constants_nested_threshold.yml"
    configured_reference = run_reek(source, "TooManyConstants", config)
    configured_actual = run_fleek(source, config, "reek:TooManyConstants")
    configured_output = configured_actual[1]
    verify(configured_reference[0] == 0 && configured_actual[0] == 0 &&
      AnalysisRunner.warning_lines(configured_reference[1]).empty? && AnalysisRunner.warning_lines(configured_output).empty? &&
      configured_output.include?("Status: complete"),
      "pinned configured TooManyConstants nested threshold changed")
    AnalysisRunner.assert_detector_findings(configured_actual, configured_reference, "nested TooManyConstants configured threshold")
  end

  # :reek:TooManyStatements
  def self.verify_too_many_instance_variables_nested_classes
    source = "test/fixtures/too_many_instance_variables_nested_classes.rb"
    reference = run_reek(source, "TooManyInstanceVariables")
    actual = run_fleek(source, "", "reek:TooManyInstanceVariables")
    findings = AnalysisRunner.detector_warnings(reference, "TooManyInstanceVariables")
    verify(reference[0] == 2 && findings.size == 1 && findings.first.include?("Fleet::Shipment has at least 5 instance variables"),
      "pinned TooManyInstanceVariables nested class isolation changed")
    AnalysisRunner.assert_status(actual, reference, "nested TooManyInstanceVariables default threshold")
    AnalysisRunner.assert_detector_findings(actual, reference, "nested TooManyInstanceVariables default threshold")
    unsupported = run_fleek("test/fixtures/too_many_instance_variables_deep_classes.rb", "", "reek:TooManyInstanceVariables")
    unsupported_output = unsupported[1]
    verify(unsupported[0] == 1 && unsupported_output.include?("Status: incomplete") &&
      unsupported_output.include?("Coverage: 1 selected; 0 analyzed; 1 failed"),
      "unsupported nested TooManyInstanceVariables scope was not reported incomplete")

    config = "test/fixtures/config_too_many_instance_variables_nested_threshold.yml"
    configured_reference = run_reek(source, "TooManyInstanceVariables", config)
    configured_actual = run_fleek(source, config, "reek:TooManyInstanceVariables")
    configured_output = configured_actual[1]
    verify(configured_reference[0] == 0 && configured_actual[0] == 0 &&
      AnalysisRunner.warning_lines(configured_reference[1]).empty? && AnalysisRunner.warning_lines(configured_output).empty? &&
      configured_output.include?("Status: complete"),
      "pinned configured TooManyInstanceVariables nested threshold changed")
    AnalysisRunner.assert_detector_findings(configured_actual, configured_reference, "nested TooManyInstanceVariables configured threshold")
  end

  # :reek:TooManyStatements
  def self.verify_too_many_methods_nested_classes
    source = "test/fixtures/too_many_methods_nested_classes.rb"
    reference = run_reek(source, "TooManyMethods")
    actual = run_fleek(source, "", "reek:TooManyMethods")
    findings = AnalysisRunner.detector_warnings(reference, "TooManyMethods")
    verify(reference[0] == 2 && findings.size == 1 && findings.first.include?("Fleet::Shipment has at least 16 methods"),
      "pinned TooManyMethods nested class counts changed")
    AnalysisRunner.assert_status(actual, reference, "nested TooManyMethods default threshold")
    AnalysisRunner.assert_detector_findings(actual, reference, "nested TooManyMethods default threshold")
    mixed_source = "test/fixtures/too_many_methods_nested_classes_mixed.rb"
    mixed_reference = run_reek(mixed_source, "TooManyMethods")
    mixed_actual = run_fleek(mixed_source, "", "reek:TooManyMethods")
    AnalysisRunner.assert_detector_findings(mixed_actual, mixed_reference, "nested TooManyMethods mixed unsupported input")
    AnalysisRunner.assert_unsupported(mixed_actual, "nested TooManyMethods mixed unsupported input")
    verify(mixed_actual[1].include?("Status: incomplete") && AnalysisRunner.detector_warnings(mixed_actual, "TooManyMethods").any?,
      "nested TooManyMethods dropped supported findings beside unsupported input")
    unsupported = run_fleek("test/fixtures/too_many_methods_deep_classes.rb", "", "reek:TooManyMethods")
    unsupported_output = unsupported[1]
    verify(unsupported[0] == 1 && unsupported_output.include?("Status: incomplete") &&
      unsupported_output.include?("Coverage: 1 selected; 0 analyzed; 1 failed"),
      "unsupported nested TooManyMethods scope was not reported incomplete")

    config = "test/fixtures/config_too_many_methods_nested_threshold.yml"
    configured_reference = run_reek(source, "TooManyMethods", config)
    configured_actual = run_fleek(source, config, "reek:TooManyMethods")
    configured_output = configured_actual[1]
    verify(configured_reference[0] == 0 && configured_actual[0] == 0 &&
      AnalysisRunner.warning_lines(configured_reference[1]).empty? && AnalysisRunner.warning_lines(configured_output).empty? &&
      configured_output.include?("Status: complete"),
      "pinned configured TooManyMethods nested threshold changed")
    AnalysisRunner.assert_detector_findings(configured_actual, configured_reference, "nested TooManyMethods configured threshold")
  end

  def self.verify_long_yield_list
    verify_default_detector("LongYieldList", "test/fixtures/long_yield_list.rb")
    verify_default_detector("LongYieldList", "test/fixtures/yield_inside_block.rb")
    verify_nested_long_yield_boundaries
  end

  # :reek:TooManyStatements
  def self.verify_nested_long_yield_boundaries
    source = "test/fixtures/long_yield_nested_blocks.rb"
    reference = run_reek(source, "LongYieldList")
    actual = run_fleek(source, "", "reek:LongYieldList")
    reference_output = reference[1]
    verify(reference[0] == 2 && reference_output.include?("[7]:LongYieldList: Parcel#over_default_limit yields 4 parameters") && reference_output.include?("[11]:LongYieldList: Parcel#over_configured_limit yields 5 parameters"), "pinned nested LongYieldList boundaries changed")
    AnalysisRunner.assert_status(actual, reference, "nested LongYieldList default threshold")
    AnalysisRunner.assert_detector_findings(actual, reference, "nested LongYieldList default threshold")
    verify_configured_nested_long_yield_boundary(source)
  end

  # :reek:TooManyStatements
  def self.verify_configured_nested_long_yield_boundary(source)
    config = "test/fixtures/config_long_yield_list.yml"
    reference = run_reek(source, "LongYieldList", config)
    actual = run_fleek(source, config, "reek:LongYieldList")
    reference_output = reference[1]
    verify(reference[0] == 2 && !reference_output.include?("over_default_limit yields 4 parameters") && reference_output.include?("[11]:LongYieldList: Parcel#over_configured_limit yields 5 parameters"), "pinned configured nested LongYieldList threshold changed")
    AnalysisRunner.assert_status(actual, reference, "nested LongYieldList configured threshold")
    AnalysisRunner.assert_detector_findings(actual, reference, "nested LongYieldList configured threshold")
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
    source = "test/fixtures/utility_function_visibility.rb"
    verify_utility_public_method_boundary(source)
    verify_utility_public_method_configuration(source, "test/fixtures/config_utility_public_methods.yml", "true", [
      "[2]:UtilityFunction: Parcel#public_normalize doesn't depend on instance state"])
    verify_utility_public_method_configuration(source, "test/fixtures/config_utility_public_methods_false.yml", "false", [
      "[2]:UtilityFunction: Parcel#public_normalize doesn't depend on instance state",
      "[8]:UtilityFunction: Parcel#private_normalize doesn't depend on instance state"])
    AnalysisRunner.assert_unsupported(run_fleek("test/fixtures/utility_function_top_level.rb",
      "test/fixtures/config_utility_public_methods.yml", "reek:UtilityFunction"), "top-level public_methods_only visibility")
  end

  # :reek:TooManyStatements
  def self.verify_utility_public_method_boundary(source)
    reference = run_reek(source, "UtilityFunction")
    actual = run_fleek(source, "", "reek:UtilityFunction")
    findings = AnalysisRunner.detector_warnings(reference, "UtilityFunction")
    findings_text = findings.join("\n")
    verify(findings.size == 2 && findings_text.include?("Parcel#public_normalize") && findings_text.include?("Parcel#private_normalize"), "pinned UtilityFunction visibility default changed")
    AnalysisRunner.assert_status(actual, reference, "UtilityFunction default visibility")
    AnalysisRunner.assert_detector_findings(actual, reference, "UtilityFunction default visibility")
  end

  # :reek:TooManyStatements
  # :reek:LongParameterList
  # :reek:NestedIterators
  def self.verify_utility_public_method_configuration(source, config, setting, expected_findings)
    reference = run_reek(source, "UtilityFunction", config)
    actual = run_fleek(source, config, "reek:UtilityFunction")
    findings = AnalysisRunner.detector_warnings(reference, "UtilityFunction")
    actual_findings_text = findings.join("\n")
    verify(reference[0] == 2 && expected_findings.all? { |expected| actual_findings_text.include?(expected) } && findings.size == expected_findings.size,
      "pinned UtilityFunction public_methods_only=#{setting} behavior changed")
    AnalysisRunner.assert_status(actual, reference, "UtilityFunction public_methods_only=#{setting}")
    AnalysisRunner.assert_detector_findings(actual, reference, "UtilityFunction")
  end

  def self.verify_unused_private_opt_in
    verify_unused_private_visibility_cases
    verify_unused_private_call_cases
    verify_unused_private_disabled
  end

  def self.verify_unused_private_visibility_cases
    verify_unused_private_finding_parity
    verify_unused_private_symbol_visibility
    verify_unused_private_public_visibility
  end

  def self.verify_unused_private_call_cases
    verify_unused_private_call_from_private
    verify_called_private_method_is_clean
    verify_dynamic_private_method_call_is_incomplete
  end

  def self.verify_unused_private_symbol_visibility
    verify_unused_private_case("test/fixtures/unused_private_method_symbol_visibility.rb", 2)
  end

  def self.verify_unused_private_public_visibility
    actual = verify_unused_private_case("test/fixtures/unused_private_method_public_visibility.rb", 2)
    verify_unused_private_finding_names(actual[1], %w[hidden visible], "public visibility change")
  end

  def self.verify_unused_private_call_from_private
    actual = verify_unused_private_case("test/fixtures/unused_private_method_called_from_private.rb", 2)
    verify_unused_private_finding_names(actual[1], %w[caller helper], "call from another private method")
  end

  def self.verify_unused_private_finding_names(output, names, behavior)
    required, excluded = names
    checks = [output.include?("name=\"#{required}\""), !output.include?("name=\"#{excluded}\"")]
    verify(checks.all?, "UnusedPrivateMethod ignored #{behavior}")
  end

  def self.verify_unused_private_finding_parity
    actual = verify_unused_private_case("test/fixtures/unused_private_method.rb", 2)
    verify_private_method_location(actual[1])
  end

  def self.verify_called_private_method_is_clean
    verify_unused_private_case("test/fixtures/unused_private_method_called.rb", 0)
  end

  def self.verify_dynamic_private_method_call_is_incomplete
    actual = run_fleek("test/fixtures/unused_private_method_dynamic_call.rb", "", "reek:UnusedPrivateMethod")
    checks = [actual[0] == 1, actual[2].include?("UnusedPrivateMethod supports"), actual[1].include?("Status: incomplete")]
    verify(checks.all?, "dynamic private method call was treated as complete")
  end

  def self.verify_private_method_location(output)
    verify(output.include?('lines="4" context="PrivateThing" name="hidden"'), "UnusedPrivateMethod context or line differs")
  end

  def self.verify_unused_private_case(source, expected_status)
    actual, reference = unused_private_method_reports(source)
    verify_unused_private_result(actual, reference, expected_status)
    actual
  end

  def self.unused_private_method_reports(source)
    config = "test/fixtures/config_unused_private_enabled.yml"
    reference = run_reek(source, "UnusedPrivateMethod", config)
    actual = run_fleek(source, "", "reek:UnusedPrivateMethod")
    [actual, reference]
  end

  def self.verify_unused_private_result(actual, reference, expected_status)
    AnalysisRunner.assert_detector_findings(actual, reference, "UnusedPrivateMethod")
    verify([actual[0], reference[0]] == [expected_status, expected_status], "UnusedPrivateMethod status differs from Reek")
    verify(actual[1].include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded") && actual[2].empty?, "UnusedPrivateMethod coverage or stderr differs")
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

  # :reek:TooManyStatements
  def self.verify_unused_parameter_block_shadowing
    source = "test/fixtures/unused_parameters_block_shadowing.rb"
    reference = run_reek(source, "UnusedParameters")
    actual = run_fleek(source, "", "reek:UnusedParameters")
    reference_output = reference[1]
    verify(reference[0] == 2 && reference_output.include?("[14]:UnusedParameters: Parcel#unused has unused parameter 'value'") &&
      !reference_output.include?("Parcel#shadowed") && !reference_output.include?("Parcel#captured"), "pinned UnusedParameters block shadowing boundary changed")
    verify(actual[1].include?("Scope limits: simple method parameter lists and supported method bodies with one iterator block"), "UnusedParameters block scope limit was not reported")
    AnalysisRunner.assert_status(actual, reference, "UnusedParameters block shadowing")
    AnalysisRunner.assert_detector_findings(actual, reference, "UnusedParameters block shadowing")
    verify_unused_parameter_block_exclusion(source)
    AnalysisRunner.assert_unsupported(run_fleek("test/fixtures/control_parameter_multiple_blocks.rb", "", "reek:UnusedParameters"), "multiple iterator blocks")
  end

  def self.verify_unused_parameter_block_exclusion(source)
    config = "test/fixtures/config_unused_parameters_block_exclusion.yml"
    reference = run_reek(source, "UnusedParameters", config)
    actual = run_fleek(source, config, "reek:UnusedParameters")
    verify(reference[0] == 0 && !reference[1].include?("UnusedParameters:"), "pinned UnusedParameters block exclusion changed")
    verify_configuration_parity(actual, reference, "UnusedParameters")
  end

  # :reek:TooManyStatements
  def self.verify_nested_control_parameter_loop
    source = "test/fixtures/control_parameter_nested_loop.rb"
    reference = run_reek(source, "ControlParameter")
    actual = run_fleek(source, "", "reek:ControlParameter")
    reference_output = reference[1]
    verify(reference[0] == 2 && reference_output.include?("[4]:ControlParameter: Parcel#choose is controlled by argument 'flag'") && !reference_output.include?("choose_with_data"), "pinned nested ControlParameter finding or suppression changed")
    verify(actual[1].include?("Scope limits: simple methods with direct conditionals and one iterator block"), "ControlParameter scope limit was not reported")
    AnalysisRunner.assert_status(actual, reference, "nested ControlParameter loop")
    AnalysisRunner.assert_detector_findings(actual, reference, "nested ControlParameter loop")
    verify_nested_control_parameter_exclusion(source)
    AnalysisRunner.assert_unsupported(run_fleek("test/fixtures/control_parameter_multiple_blocks.rb", "", "reek:ControlParameter"), "multiple iterator blocks")
  end

  # :reek:TooManyStatements
  def self.verify_nested_control_parameter_exclusion(source)
    config = "test/fixtures/config_control_parameter_nested_exclusion.yml"
    reference = run_reek(source, "ControlParameter", config)
    actual = run_fleek(source, config, "reek:ControlParameter")
    reference_output = reference[1]
    verify(reference[0] == 0 && !reference_output.include?("ControlParameter:"), "pinned nested ControlParameter exclusion changed")
    verify_configuration_parity(actual, reference, "ControlParameter")
  end

  def self.verify_utility_instance_call
    verify_default_detector("UtilityFunction", "test/fixtures/utility_instance_method_call.rb")
  end

  # :reek:TooManyStatements
  def self.verify_duplicate_method_call_nested_branches
    source = "test/fixtures/duplicate_method_call_nested_branches.rb"
    reference = run_reek(source, "DuplicateMethodCall")
    actual = run_fleek(source, "", "reek:DuplicateMethodCall")
    reference_output = reference[1]
    verify(reference[0] == 2 && reference_output.include?("[4, 6]:DuplicateMethodCall: Parcel#calculate calls 'order.total(:net)' 2 times") &&
      !reference_output.include?("order.total(:gross)"), "pinned nested DuplicateMethodCall grouping changed")
    AnalysisRunner.assert_status(actual, reference, "nested DuplicateMethodCall branches")
    AnalysisRunner.assert_detector_findings(actual, reference, "DuplicateMethodCall")
    verify_duplicate_method_call_nested_allow(source)
  end

  # :reek:TooManyStatements
  def self.verify_duplicate_method_call_nested_allow(source)
    config = "test/fixtures/config_duplicate_method_call_nested_allow.yml"
    reference = run_reek(source, "DuplicateMethodCall", config)
    actual = run_fleek(source, config, "reek:DuplicateMethodCall")
    actual_output = actual[1]
    verify(reference[0] == 0 && AnalysisRunner.detector_warnings(reference, "DuplicateMethodCall").empty?, "pinned nested DuplicateMethodCall allow_calls changed")
    verify(actual[0] == 0 && actual_output.include?("Status: complete") && actual_output.include?("1 analyzed; 0 failed"), "nested DuplicateMethodCall allow_calls was not complete and clean")
    AnalysisRunner.assert_detector_findings(actual, reference, "DuplicateMethodCall")
  end

  # :reek:TooManyStatements
  def self.verify_manual_dispatch_nested_guard
    source = "test/fixtures/manual_dispatch_nested_guard.rb"
    reference = run_reek(source, "ManualDispatch")
    actual = run_fleek(source, "", "reek:ManualDispatch")
    reference_output = reference[1]
    verify(reference[0] == 2 && reference_output.include?("[3]:ManualDispatch: Parcel#guarded_dispatch manually dispatches method call") &&
      !reference_output.include?("Parcel#unguarded_dispatch"), "pinned nested ManualDispatch guard boundary changed")
    AnalysisRunner.assert_status(actual, reference, "nested ManualDispatch guard")
    AnalysisRunner.assert_detector_findings(actual, reference, "ManualDispatch")
    verify_manual_dispatch_exclusion(source)
  end

  # :reek:TooManyStatements
  def self.verify_manual_dispatch_exclusion(source)
    config = "test/fixtures/config_manual_dispatch_exclusion.yml"
    reference = run_reek(source, "ManualDispatch", config)
    actual = run_fleek(source, config, "reek:ManualDispatch")
    verify(reference[0] == 0 && AnalysisRunner.detector_warnings(reference, "ManualDispatch").empty?, "pinned ManualDispatch context exclusion changed")
    verify(actual[0] == 0 && actual[1].include?("Status: complete"), "ManualDispatch context exclusion was not complete and clean")
    AnalysisRunner.assert_detector_findings(actual, reference, "ManualDispatch")
  end

  # :reek:TooManyStatements
  def self.verify_nil_check_nested_block
    source = "test/fixtures/nil_check_nested_block.rb"
    reference = run_reek(source, "NilCheck")
    actual = run_fleek(source, "", "reek:NilCheck")
    reference_output = reference[1]
    verify(reference[0] == 2 && reference_output.include?("[4, 5]:NilCheck: Parcel#retrieve performs a nil-check") &&
      !reference_output.include?("value&.save"), "pinned nested NilCheck lines or safe-navigation control changed")
    AnalysisRunner.assert_status(actual, reference, "nested NilCheck block")
    AnalysisRunner.assert_detector_findings(actual, reference, "NilCheck")
    verify_nil_check_block_exclusion(source)
    AnalysisRunner.assert_unsupported(run_fleek("test/fixtures/control_parameter_multiple_blocks.rb", "", "reek:NilCheck"), "multiple NilCheck blocks")
  end

  # :reek:TooManyStatements
  def self.verify_nil_check_block_exclusion(source)
    config = "test/fixtures/config_nil_check_nested_exclusion.yml"
    reference = run_reek(source, "NilCheck", config)
    actual = run_fleek(source, config, "reek:NilCheck")
    verify(reference[0] == 0 && AnalysisRunner.detector_warnings(reference, "NilCheck").empty?, "pinned NilCheck block exclusion changed")
    verify(actual[0] == 0 && actual[1].include?("Status: complete"), "NilCheck block exclusion was not clean and complete")
    AnalysisRunner.assert_detector_findings(actual, reference, "NilCheck")
  end

  # :reek:TooManyStatements
  def self.verify_missing_safe_method_singleton_companions
    source = "test/fixtures/missing_safe_method_singleton.rb"
    reference = run_reek(source, "MissingSafeMethod")
    actual = run_fleek(source, "", "reek:MissingSafeMethod")
    verify(reference[1].include?("[7]:MissingSafeMethod: Parcel has missing safe method 'deliver!'"),
      "pinned singleton MissingSafeMethod finding or line changed")
    AnalysisRunner.assert_status(actual, reference, "singleton MissingSafeMethod")
    AnalysisRunner.assert_detector_findings(actual, reference, "MissingSafeMethod")
    verify_configured_detector("MissingSafeMethod", source, "test/fixtures/config_missing_safe_method_singleton_exclude.yml")
  end

  # :reek:TooManyStatements
  def self.verify_repeated_conditional_nested_classes
    source = "test/fixtures/repeated_conditional_nested_classes.rb"
    clean_config = "test/fixtures/config_repeated_conditional_nested_classes.yml"
    clean_reference = run_reek(source, "RepeatedConditional", clean_config)
    clean_actual = run_fleek(source, clean_config, "reek:RepeatedConditional")
    verify(AnalysisRunner.detector_warnings(clean_reference, "RepeatedConditional").empty?,
      "pinned per-class RepeatedConditional threshold changed")
    verify(clean_actual[0] == 0 && clean_actual[1].include?("Status: complete"),
      "per-class RepeatedConditional threshold was not clean and complete")
    AnalysisRunner.assert_detector_findings(clean_actual, clean_reference, "RepeatedConditional")

    finding_config = "test/fixtures/config_repeated_conditional_nested_classes_finding.yml"
    reference = run_reek(source, "RepeatedConditional", finding_config)
    actual = run_fleek(source, finding_config, "reek:RepeatedConditional")
    verify(AnalysisRunner.detector_warnings(reference, "RepeatedConditional").length == 2,
      "pinned per-class RepeatedConditional findings were merged")
    AnalysisRunner.assert_status(actual, reference, "per-class RepeatedConditional")
    AnalysisRunner.assert_detector_findings(actual, reference, "RepeatedConditional")
  end

  # :reek:TooManyStatements
  def self.verify_nested_iterator_ignored_name
    source = "test/fixtures/nested_iterators_ignored_name.rb"
    reference = run_reek(source, "NestedIterators")
    actual = run_fleek(source, "test/fixtures/config_nested_iterators.yml", "reek:NestedIterators")
    verify(AnalysisRunner.detector_warnings(reference, "NestedIterators").length == 1 &&
      reference[1].include?("[5]:NestedIterators: Parcel#walk contains iterators nested 3 deep"),
      "pinned three-level NestedIterators finding changed")
    AnalysisRunner.assert_status(actual, reference, "three-level NestedIterators")
    AnalysisRunner.assert_detector_findings(actual, reference, "NestedIterators")

    config = "test/fixtures/config_nested_iterators_ignore_map.yml"
    ignored_reference = run_reek(source, "NestedIterators", config)
    ignored_actual = run_fleek(source, config, "reek:NestedIterators")
    verify(AnalysisRunner.detector_warnings(ignored_reference, "NestedIterators").empty?,
      "pinned ignored map nesting depth changed")
    verify(ignored_actual[0] == 0 && ignored_actual[1].include?("Status: complete"),
      "ignored map did not produce a complete clean result")
    AnalysisRunner.assert_detector_findings(ignored_actual, ignored_reference, "NestedIterators")
  end

  # :reek:TooManyStatements
  def self.verify_feature_envy_block_receivers
    source = "test/fixtures/feature_envy_block_receivers.rb"
    reference = run_reek(source, "FeatureEnvy")
    actual = run_fleek(source, "", "reek:FeatureEnvy")
    verify(AnalysisRunner.detector_warnings(reference, "FeatureEnvy").length == 1 &&
      reference[1].include?("[5, 6, 7]:FeatureEnvy: Parcel#price refers to 'item' more than self"),
      "pinned block FeatureEnvy receiver counts or context changed")
    AnalysisRunner.assert_status(actual, reference, "FeatureEnvy block receiver")
    AnalysisRunner.assert_detector_findings(actual, reference, "FeatureEnvy")
    verify_configured_detector("FeatureEnvy", source, "test/fixtures/config_feature_envy_block_exclude.yml")
    AnalysisRunner.assert_unsupported(run_fleek("test/fixtures/feature_envy_multiple_blocks.rb", "", "reek:FeatureEnvy"),
      "multiple FeatureEnvy blocks")
  end

  # :reek:TooManyStatements
  def self.verify_data_clump_singleton_methods
    source = "test/fixtures/data_clump_singleton_methods.rb"
    reference = run_reek(source, "DataClump")
    actual = run_fleek(source, "", "reek:DataClump")
    warnings = AnalysisRunner.detector_warnings(reference, "DataClump")
    verify(warnings.length == 2 && warnings[0].include?("to 8 methods") && warnings[1].include?("to 9 methods") &&
      warnings.none? { |warning| warning.include?("[10]") },
      "pinned DataClump singleton participation groups changed")
    AnalysisRunner.assert_status(actual, reference, "singleton DataClump")
    AnalysisRunner.assert_detector_findings(actual, reference, "DataClump")

    config = "test/fixtures/config_data_clump_singleton_minimum.yml"
    configured_reference = run_reek(source, "DataClump", config)
    configured_actual = run_fleek(source, config, "reek:DataClump")
    verify(AnalysisRunner.detector_warnings(configured_reference, "DataClump").length == 1,
      "pinned singleton DataClump minimum size changed")
    AnalysisRunner.assert_status(configured_actual, configured_reference, "singleton DataClump minimum size")
    AnalysisRunner.assert_detector_findings(configured_actual, configured_reference, "DataClump")
  end

  def self.verify_configured_detector(detector, source, config)
    reference = run_reek(source, detector, config)
    actual = run_fleek(source, config)
    verify_configuration_parity(actual, reference, detector)
  end

  # :reek:TooManyStatements
  def self.verify_long_parameter_block_limit
    source = "test/fixtures/long_parameter_block.rb"
    reference = run_reek(source)
    actual = run_fleek(source, "", "reek:LongParameterList")
    output = actual[1]
    verify(reference[0] == 0, "pinned block-parameter-only source changed")
    verify(actual[0] == 0 && actual[2].empty? && output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded") && output.include?("Status: complete"), "block-parameter-only method was not analyzed cleanly")
    AnalysisRunner.assert_detector_findings(actual, reference, "block-parameter-only source")
    verify_long_parameter_block_boundaries
  end

  # :reek:TooManyStatements
  def self.verify_long_parameter_block_boundaries
    source = "test/fixtures/long_parameter_block_boundary.rb"
    reference = run_reek(source)
    actual = run_fleek(source, "", "reek:LongParameterList")
    reference_output = reference[1]
    verify(reference[0] == 2 && reference_output.include?("[6]:LongParameterList: Parcel#over_default_limit has 4 parameters") && reference_output.include?("[10]:LongParameterList: Parcel#over_configured_limit has 5 parameters"), "pinned default block-body threshold boundaries changed")
    AnalysisRunner.assert_status(actual, reference, "default block-body threshold")
    AnalysisRunner.assert_detector_findings(actual, reference, "default block-body threshold")
    verify_configured_long_parameter_block_boundary(source)
  end

  # :reek:TooManyStatements
  def self.verify_configured_long_parameter_block_boundary(source)
    config = "test/fixtures/config_long_parameter_list.yml"
    reference = run_reek(source, "LongParameterList", config)
    actual = run_fleek(source, config, "reek:LongParameterList")
    reference_output = reference[1]
    verify(reference[0] == 2 && !reference_output.include?("over_default_limit has 4 parameters") && reference_output.include?("[10]:LongParameterList: Parcel#over_configured_limit has 5 parameters"), "pinned configured block-body threshold changed")
    AnalysisRunner.assert_status(actual, reference, "configured block-body threshold")
    AnalysisRunner.assert_detector_findings(actual, reference, "configured block-body threshold")
  end

  def self.verify_long_parameter_configuration
    config = "test/fixtures/config_long_parameter_list.yml"
    reference = run_reek(SOURCE, "LongParameterList", config)
    actual = run_fleek(SOURCE, config)
    verify_configuration_parity(actual, reference, "LongParameterList")
  end

  def self.verify_configuration_parity(actual, reference, detector)
    verify([0, 2].include?(reference[0]) && reference[2].empty?, "pinned #{detector} configuration failed")
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

  def self.verify_unsupported_naming_scopes
    source = "test/fixtures/uncommunicative_names_unsupported.rb"
    verify_unsupported_names(source)
    verify_partial_variable_names
  end

  def self.verify_partial_variable_names
    variable_result = run_fleek("test/fixtures/uncommunicative_variable_name_partial.rb", "", "reek:UncommunicativeVariableName")
    AnalysisRunner.assert_unsupported(variable_result, "UncommunicativeVariableName block arguments")
    verify(AnalysisRunner.detector_warnings(variable_result, "UncommunicativeVariableName").any? { |finding| finding.include?("Worker#work") && finding.include?("x") }, "UncommunicativeVariableName discarded a supported finding beside block arguments")
  end

  def self.verify_unsupported_names(source)
    %w[UncommunicativeMethodName UncommunicativeModuleName UncommunicativeParameterName].each do |detector|
      AnalysisRunner.assert_unsupported(run_fleek(source, "", "reek:#{detector}"), detector)
    end
    module_result = run_fleek(source, "", "reek:UncommunicativeModuleName")
    verify(AnalysisRunner.detector_warnings(module_result, "UncommunicativeModuleName").none? { |finding| finding.include?("'B'") || finding.include?("'C'") }, "UncommunicativeModuleName reported an unqualified nested finding")
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

  # :reek:TooManyStatements
  def self.verify_unsupported_singleton_class_methods
    source = "test/fixtures/too_many_statements_singleton_class.rb"
    reference = run_reek(source, "TooManyStatements")
    actual = run_fleek(source, "", "reek:TooManyStatements")
    findings = AnalysisRunner.detector_warnings(reference, "TooManyStatements")
    verify(reference[0] == 2 && findings.size == 1 && findings.first.include?("Workflow#dispatch has approx 6 statements"),
      "pinned Reek singleton-class threshold boundary changed")
    AnalysisRunner.assert_status(actual, reference, "TooManyStatements singleton-class methods")
    AnalysisRunner.assert_detector_findings(actual, reference, "TooManyStatements singleton-class methods")
    verify_too_many_statements_mixed_singleton_scope
    verify_too_many_statements_mixed_singleton_body
  end

  # :reek:TooManyStatements
  def self.verify_too_many_statements_mixed_singleton_scope
    source = "test/fixtures/too_many_statements_mixed_singleton_class.rb"
    reference = run_reek(source, "TooManyStatements")
    actual = run_fleek(source, "", "reek:TooManyStatements")
    AnalysisRunner.assert_status(actual, reference, "mixed singleton-class method scope")
    AnalysisRunner.assert_detector_findings(actual, reference, "mixed singleton-class method scope")
  end

  # :reek:TooManyStatements
  def self.verify_too_many_statements_mixed_singleton_body
    source = "test/fixtures/too_many_statements_singleton_class_mixed_unsupported_body.rb"
    reference = run_reek(source, "TooManyStatements")
    actual = run_fleek(source, "", "reek:TooManyStatements")
    reference_findings = AnalysisRunner.detector_warnings(reference, "TooManyStatements")
    actual_findings = AnalysisRunner.detector_warnings(actual, "TooManyStatements")
    supported_context = "Workflow#supported"
    reference_text = reference_findings.join("\n")
    actual_text = actual_findings.join("\n")
    verify(reference_text.include?(supported_context), "pinned mixed singleton method fixture lost supported finding")
    verify(actual_text.include?(supported_context), "Fleek dropped singleton-class finding beside unsupported method body")
    AnalysisRunner.assert_unsupported(actual, "TooManyStatements mixed singleton method body")
  end

  def self.mixed_too_many_statements_finding?(result)
    AnalysisRunner.detector_warnings(result, "TooManyStatements").any? { |finding| finding.include?("Workflow#supported") }
  end

  # :reek:TooManyStatements
  def self.verify_too_many_statements_mixed_unsupported_body
    verify_too_many_statements_partial_findings("test/fixtures/too_many_statements_mixed_unsupported_body.rb", "unsupported method body")
  end

  # :reek:TooManyStatements
  def self.verify_too_many_statements_partial_findings(source, unsupported_shape)
    reference = run_reek(source, "TooManyStatements")
    actual = run_fleek(source, "", "reek:TooManyStatements")
    verify(mixed_too_many_statements_finding?(reference), "pinned Reek #{unsupported_shape} fixture lost supported finding")
    verify(mixed_too_many_statements_finding?(actual), "Fleek dropped supported finding beside #{unsupported_shape}")
    AnalysisRunner.assert_unsupported(actual, "TooManyStatements #{unsupported_shape}")
  end

  # :reek:TooManyStatements
  def self.verify_too_many_methods_mixed_nested_definition
    source = "test/fixtures/too_many_methods_mixed_nested_definition.rb"
    reference = run_reek(source, "TooManyMethods")
    actual = run_fleek(source, "", "reek:TooManyMethods")
    verify(AnalysisRunner.detector_warnings(reference, "TooManyMethods").any?, "pinned Reek nested-method fixture lost supported finding")
    verify(AnalysisRunner.detector_warnings(actual, "TooManyMethods").any?, "Fleek dropped TooManyMethods finding beside nested definition")
    AnalysisRunner.assert_unsupported(actual, "TooManyMethods nested method")
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
