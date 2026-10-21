# Compares Fleek object-scope detector output with pinned Reek 6.6.0.
require_relative "analysis_runner"

# Verifies default object-scope detector parity and configuration.
class DefaultObjectScopeContract
  SOURCE = "test/fixtures/attribute.rb"
  DEFAULT_DETECTORS = {
    "InstanceVariableAssumption" => "test/fixtures/instance_variable_assumption.rb",
    "SubclassedFromCoreClass" => "test/fixtures/subclassed_from_core_class.rb",
    "ModuleInitialize" => "test/fixtures/module_initialize.rb"
  }.freeze

  # :reek:TooManyStatements
  def self.run
    reference = run_reek
    actual = run_fleek
    verify_attribute_default(reference, actual)
    verify_attribute_explicit(reference)
    verify_attribute_settings
    verify_attribute_alias
    verify_attribute_nested_class
    verify_attribute_deeper_and_wrapped_scopes
    verify_nested_instance_variable_assumption
    verify_deeper_instance_variable_assumption
    verify_unsupported_shapes
    verify_nested_module_initialize
    verify_comment_overflow
    verify_other_detectors
    puts "Default object-scope contract: pass"
  end

  # :reek:TooManyStatements
  def self.verify_attribute_default(reference, actual)
    reference_output = reference[1]
    actual_output = actual[1]
    actual_lines = actual_output.lines
    verify(reference[0] == 2 && reference_output.include?("[2]:Attribute:") && reference_output.include?("[3]:Attribute:"), "pinned Reek Attribute fixture changed")
    verify(actual_lines.any? { |line| line.start_with?("Checks run:") && line.include?("reek:Attribute") }, "default invocation did not run Attribute")
    AnalysisRunner.assert_detector_findings(actual, reference, "Attribute")
    verify(!actual_lines.find { |line| line.start_with?("Checks unsupported:") }.include?("reek:Attribute"), "implemented Attribute detector remained unsupported")
  end

  def self.verify_attribute_explicit(reference)
    explicit = run_fleek_explicit
    AnalysisRunner.assert_status(explicit, reference, "explicit Attribute selection")
    AnalysisRunner.assert_detector_findings(explicit, reference, "Attribute")
  end

  def self.verify_attribute_settings
    verify_attribute_exclusion_config
    verify_attribute_disabled
    verify_attribute_scope_precedence
  end

  def self.verify_other_detectors
    DEFAULT_DETECTORS.each { |detector, source| verify_default_detector(detector, source) }
    verify_instance_variable_exclusion
    verify_irresponsible_module("test/fixtures/irresponsible_module.rb")
  end

  def self.verify_nested_module_initialize
    source = "test/fixtures/module_initialize_nested.rb"
    reference = run_reek_for("ModuleInitialize", source)
    actual = run_fleek_check("ModuleInitialize", source)
    verify(reference[0] == 2 && reference[1].include?("[2]:ModuleInitialize: Outer::InitializerMixin has initialize method"), "pinned nested ModuleInitialize finding changed")
    AnalysisRunner.assert_status(actual, reference, "nested ModuleInitialize")
    AnalysisRunner.assert_detector_findings(actual, reference, "nested ModuleInitialize")
    verify_nested_module_initialize_exclusion(source)
  end

  def self.verify_nested_module_initialize_exclusion(source)
    config = "test/fixtures/config_module_initialize_nested_exclusion.yml"
    reference = run_reek_config_for("ModuleInitialize", source, config)
    actual = run_fleek_check_config("ModuleInitialize", source, config)
    output = actual[1]
    verify(reference[0] == 0, "pinned nested ModuleInitialize exclusion changed")
    verify(actual[0] == 0 && actual[2].empty? && output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded") && output.include?("Status: complete"), "nested ModuleInitialize exclusion did not stay complete")
    AnalysisRunner.assert_detector_findings(actual, reference, "nested ModuleInitialize exclusion")
  end

  def self.verify_unsupported_shapes
    verify_subclassed_class_new_assignment
    verify_irresponsible_class_new_assignment
    verify_class_new_method_call
  end

  # :reek:TooManyStatements
  def self.verify_irresponsible_class_new_assignment
    source = "test/fixtures/class_new_assignment.rb"
    reference = run_reek_for("IrresponsibleModule", source)
    actual = run_fleek_check("IrresponsibleModule", source)
    verify(reference[0] == 2 && reference[1].include?("[1]:IrresponsibleModule: RecordSet has no descriptive comment"), "pinned undocumented Class.new finding changed")
    AnalysisRunner.assert_status(actual, reference, "undocumented Class.new")
    AnalysisRunner.assert_detector_findings(actual, reference, "undocumented Class.new")
    verify_described_class_new_assignment
    verify_class_new_irresponsible_exclusion(source)
    verify_dynamic_class_new_irresponsible_incomplete
  end

  # :reek:TooManyStatements
  def self.verify_described_class_new_assignment
    source = "test/fixtures/class_new_described_assignment.rb"
    reference = run_reek_for("IrresponsibleModule", source)
    actual = run_fleek_check("IrresponsibleModule", source)
    output = actual[1]
    verify(reference[0] == 0, "pinned descriptive Class.new control changed")
    verify(actual[0] == 0 && actual[2].empty? && output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded") && output.include?("Status: complete"), "described Class.new was not analyzed cleanly")
    AnalysisRunner.assert_detector_findings(actual, reference, "described Class.new")
  end

  # :reek:TooManyStatements
  def self.verify_class_new_irresponsible_exclusion(source)
    config = "test/fixtures/config_irresponsible_class_new_exclusion.yml"
    reference = run_reek_config_for("IrresponsibleModule", source, config)
    actual = run_fleek_check_config("IrresponsibleModule", source, config)
    output = actual[1]
    verify(reference[0] == 0, "pinned Class.new exclusion changed")
    verify(actual[0] == 0 && actual[2].empty? && output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded") && output.include?("Status: complete"), "Class.new exclusion did not stay complete")
    AnalysisRunner.assert_detector_findings(actual, reference, "Class.new exclusion")
  end

  def self.verify_dynamic_class_new_irresponsible_incomplete
    source = "test/fixtures/class_new_dynamic_superclass_assignment.rb"
    reference = run_reek_for("IrresponsibleModule", source)
    actual = run_fleek_check("IrresponsibleModule", source)
    verify(reference[0] == 2, "pinned dynamic Class.new IrresponsibleModule result changed")
    AnalysisRunner.assert_unsupported(actual, "dynamic Class.new IrresponsibleModule")
  end

  # :reek:TooManyStatements
  def self.verify_subclassed_class_new_assignment
    source = "test/fixtures/class_new_assignment.rb"
    reference = run_reek_for("SubclassedFromCoreClass", source)
    actual = run_fleek_check("SubclassedFromCoreClass", source)
    verify(reference[0] == 2 && reference[1].include?("[1]:SubclassedFromCoreClass: RecordSet inherits from core class 'Array'"), "pinned Class.new(Array) finding changed")
    AnalysisRunner.assert_status(actual, reference, "Class.new(Array)")
    AnalysisRunner.assert_detector_findings(actual, reference, "Class.new(Array)")

    custom_source = "test/fixtures/class_new_custom_assignment.rb"
    custom_reference = run_reek_for("SubclassedFromCoreClass", custom_source)
    custom_actual = run_fleek_check("SubclassedFromCoreClass", custom_source)
    custom_output = custom_actual[1]
    verify(custom_reference[0] == 0, "pinned Class.new(custom class) clean control changed")
    verify(custom_actual[0] == 0 && custom_actual[2].empty? && custom_output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded") && custom_output.include?("Status: complete"), "Class.new(custom class) was not analyzed cleanly")
    AnalysisRunner.assert_detector_findings(custom_actual, custom_reference, "Class.new(custom class)")

    dynamic_source = "test/fixtures/class_new_dynamic_superclass_assignment.rb"
    dynamic_reference = run_reek_for("SubclassedFromCoreClass", dynamic_source)
    dynamic_actual = run_fleek_check("SubclassedFromCoreClass", dynamic_source)
    dynamic_output = dynamic_actual[1]
    verify(dynamic_reference[0] == 0, "pinned dynamic Class.new superclass control changed")
    verify(dynamic_actual[0] == 1 && dynamic_output.include?("Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded") && dynamic_output.include?("Status: incomplete"), "dynamic Class.new superclass was not reported as incomplete")
    AnalysisRunner.assert_detector_findings(dynamic_actual, dynamic_reference, "dynamic Class.new superclass")

    config = "test/fixtures/config_subclassed_from_core_class_exclusion.yml"
    excluded_reference = run_reek_config_for("SubclassedFromCoreClass", source, config)
    excluded_actual = run_fleek_check_config("SubclassedFromCoreClass", source, config)
    excluded_output = excluded_actual[1]
    verify(excluded_reference[0] == 0, "pinned Class.new(Array) exclusion changed")
    verify(excluded_actual[0] == 0 && excluded_actual[2].empty? && excluded_output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded") && excluded_output.include?("Status: complete"), "Class.new(Array) exclusion did not remain complete and clean")
    AnalysisRunner.assert_detector_findings(excluded_actual, excluded_reference, "Class.new(Array) exclusion")
  end

  def self.verify_attribute_alias
    source = "test/fixtures/attribute_visibility_method.rb"
    verify_expected_finding("Attribute", source, "[2]:")
    verify_supported_clean_detector("Attribute", "test/fixtures/attribute_read_only.rb")
  end

  # :reek:TooManyStatements
  def self.verify_attribute_nested_class
    source = "test/fixtures/attribute_nested_class.rb"
    reference = run_reek_for("Attribute", source)
    actual = run_fleek_check("Attribute", source)
    verify_nested_attribute_findings(reference, actual)
    config = "test/fixtures/config_attribute_nested_exclusion.yml"
    excluded_reference = run_reek_config_for("Attribute", source, config)
    excluded_actual = run_fleek_check_config("Attribute", source, config)
    verify_nested_attribute_exclusion(excluded_reference, excluded_actual)
  end

  # :reek:TooManyStatements
  def self.verify_attribute_deeper_and_wrapped_scopes
    verify_attribute_incomplete_scope("test/fixtures/attribute_deep_nested_class.rb",
      ["[5]:Attribute: Profile::Credentials#secret is a writable attribute",
        "[6]:Attribute: Profile::Credentials#token is a writable attribute",
        "[13]:Attribute: Profile::Credentials::Secrets#visible is a writable attribute"])
    verify_attribute_incomplete_scope("test/fixtures/attribute_wrapped_namespace.rb",
      ["[9]:Attribute: Profile::Credentials#secret is a writable attribute"])
  end

  def self.verify_attribute_incomplete_scope(source, expected_findings)
    verify_attribute_reference_incomplete(run_reek_for("Attribute", source), expected_findings, source)
    verify_attribute_report_incomplete(run_fleek_check("Attribute", source), source)
  end

  def self.verify_attribute_reference_incomplete(reference, expected_findings, source)
    reference_output = reference[1]
    verify(reference[0] == 2 && attribute_reference_matches(reference_output, expected_findings), "pinned Reek nested/wrapped Attribute findings changed for #{source}")
  end

  def self.attribute_reference_matches(output, expected_findings)
    matches = expected_findings.all? { |finding| output.include?(finding) }
    finding_count = output.lines.count { |line| line.include?(":Attribute:") }
    matches && finding_count == expected_findings.length
  end

  def self.verify_attribute_report_incomplete(actual, source)
    output = actual[1]
    coverage = output.include?("Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded")
    incomplete = output.include?("Status: incomplete")
    verify(actual[0] == 1 && coverage && incomplete && actual[2].include?("Attribute supports"), "unsupported Attribute scope was not reported incomplete for #{source}")
  end

  def self.verify_nested_attribute_findings(reference, actual)
    reference_output = reference[1]
    verify(reference[0] == 2 && reference_output.include?("[5]:Attribute:") && reference_output.include?("[6]:Attribute:") && !reference_output.include?("[7]:Attribute:"), "pinned Reek nested Attribute visibility changed")
    verify_nested_attribute_result(actual, reference, "nested Attribute")
  end

  def self.verify_nested_attribute_exclusion(reference, actual)
    verify_attribute_exclusion_findings(reference, 5, 6)
    verify_nested_attribute_result(actual, reference, "nested Attribute exclusion")
  end

  def self.verify_nested_attribute_result(actual, reference, label)
    output = actual[1]
    AnalysisRunner.assert_status(actual, reference, label)
    verify(output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded") && output.include?("Status: findings") && actual[2].empty?, "#{label} coverage or streams changed")
    AnalysisRunner.assert_detector_findings(actual, reference, label)
  end

  # :reek:TooManyStatements
  def self.verify_nested_instance_variable_assumption
    source = "test/fixtures/instance_variable_assumption_nested_class.rb"
    reference = run_reek_for("InstanceVariableAssumption", source)
    actual = run_fleek_check("InstanceVariableAssumption", source)
    reference_output = reference[1]
    verify(reference[0] == 2 && reference_output.include?("[2]:InstanceVariableAssumption:") && reference_output.include?("Profile::Credentials"), "pinned nested InstanceVariableAssumption finding changed")
    AnalysisRunner.assert_detector_findings(actual, reference, "nested InstanceVariableAssumption")
    AnalysisRunner.assert_status(actual, reference, "nested InstanceVariableAssumption")
    verify_nested_instance_variable_clean_control
    verify_nested_instance_variable_exclusion(source)
  end

  def self.verify_nested_instance_variable_clean_control
    source = "test/fixtures/instance_variable_assumption_nested_initialized.rb"
    reference = run_reek_for("InstanceVariableAssumption", source)
    actual = run_fleek_check("InstanceVariableAssumption", source)
    verify(reference[0] == 0, "pinned nested InstanceVariableAssumption clean control changed")
    verify_nested_instance_variable_clean_result(actual, reference, "nested InstanceVariableAssumption clean control")
  end

  def self.verify_nested_instance_variable_exclusion(source)
    config = "test/fixtures/config_instance_variable_nested_exclusion.yml"
    reference = run_reek_config_for("InstanceVariableAssumption", source, config)
    actual = run_fleek_check_config("InstanceVariableAssumption", source, config)
    verify(reference[0] == 0, "pinned nested InstanceVariableAssumption exclusion changed")
    verify_nested_instance_variable_clean_result(actual, reference, "nested InstanceVariableAssumption exclusion")
  end

  def self.verify_nested_instance_variable_clean_result(actual, reference, label)
    output = actual[1]
    status = actual[0]
    verify(status == reference[0] && status == 0 && actual[2].empty? && output.include?("Status: complete"), "#{label} status or streams changed")
    AnalysisRunner.assert_detector_findings(actual, reference, "InstanceVariableAssumption")
  end

  # :reek:TooManyStatements
  def self.verify_deeper_instance_variable_assumption
    verify_instance_variable_incomplete_scope("test/fixtures/instance_variable_assumption_deeper_nested.rb",
      "[3]:InstanceVariableAssumption: Profile::Account::Credentials assumes too much for instance variable '@name'")
    verify_instance_variable_incomplete_scope("test/fixtures/instance_variable_assumption_wrapped_class.rb",
      "[2]:InstanceVariableAssumption: Profiles::Credentials assumes too much for instance variable '@name'")
    verify_instance_variable_clean_reference("test/fixtures/instance_variable_assumption_deeper_initialized.rb")
    verify_instance_variable_excluded_scope("test/fixtures/instance_variable_assumption_deeper_nested.rb")
    verify_instance_variable_excluded_scope("test/fixtures/instance_variable_assumption_wrapped_class.rb")
  end

  def self.verify_instance_variable_incomplete_scope(source, expected_finding)
    reference = run_reek_for("InstanceVariableAssumption", source)
    actual = run_fleek_check("InstanceVariableAssumption", source)
    verify(reference[0] == 2 && reference[1].include?(expected_finding), "pinned deeper InstanceVariableAssumption finding changed for #{source}")
    verify_instance_variable_incomplete_report(actual, source)
  end

  def self.verify_instance_variable_clean_reference(source)
    reference = run_reek_for("InstanceVariableAssumption", source)
    actual = run_fleek_check("InstanceVariableAssumption", source)
    verify(reference[0] == 0 && reference[1].empty?, "pinned initialized InstanceVariableAssumption control changed")
    verify_instance_variable_incomplete_report(actual, source)
  end

  def self.verify_instance_variable_excluded_scope(source)
    config = "test/fixtures/config_instance_variable_assumption_deep_exclusion.yml"
    reference = run_reek_config_for("InstanceVariableAssumption", source, config)
    actual = run_fleek_check_config("InstanceVariableAssumption", source, config)
    verify(reference[0] == 0 && reference[1].empty?, "pinned deeper InstanceVariableAssumption exclusion changed for #{source}")
    verify_instance_variable_incomplete_report(actual, source)
  end

  def self.verify_instance_variable_incomplete_report(actual, source)
    status, output, = actual
    coverage = "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded"
    verify(status == 1 && output.include?(coverage) && output.include?("Status: incomplete"),
      "unsupported InstanceVariableAssumption scope was not reported incomplete for #{source}")
  end

  def self.verify_expected_finding(detector, source, line)
    reference = run_reek_for("Attribute", source)
    actual = run_fleek_check("Attribute", source)
    verify_reek_finding(reference, line, "pinned Reek #{detector} fixture changed")
    AnalysisRunner.assert_detector_findings(actual, reference, "Attribute")
  end

  def self.verify_class_new_method_call
    source = "test/fixtures/class_new_method_call.rb"
    verify_supported_clean_detector("SubclassedFromCoreClass", source)
    verify_supported_clean_detector("IrresponsibleModule", source)
  end

  def self.verify_supported_clean_detector(detector, source)
    reference = run_reek_for(detector, source)
    actual = run_fleek_check(detector, source)
    verify(reference[0] == 0, "pinned Reek #{detector} clean fixture changed")
    verify(actual[0] == 0 && actual[2].empty?, "#{detector} clean syntax became unsupported")
  end

  def self.verify_unsupported_detector(detector, source, reference_finding)
    reference = run_reek_for(detector, source)
    actual = run_fleek_check(detector, source)
    verify_reek_finding(reference, reference_finding, "pinned Reek #{detector} unsupported-shape behavior changed")
    AnalysisRunner.assert_unsupported(actual, detector)
  end

  def self.verify_comment_overflow
    source = "/tmp/fleek-object-many-comments.rb"
    File.write(source, ("# note\n" * 129) + "class Profile\nend\n")
    actual = run_fleek_check("IrresponsibleModule", source)
    verify(actual[0] == 1 && actual[2].include?("unsupported"), "comment overflow appeared clean")
  ensure
    File.delete(source) if File.file?(source)
  end

  def self.verify_reek_finding(reference, marker, message)
    verify(reference[0] == 2 && reference[1].include?(marker), message)
  end

  # :reek:TooManyStatements
  def self.verify_attribute_exclusion_findings(reference, excluded_line, included_line)
    output = reference[1]
    verify(reference[0] == 2 && !output.include?("[#{excluded_line}]:Attribute:") && output.include?("[#{included_line}]:Attribute:"), "pinned Reek Attribute exclusion changed")
  end

  def self.verify_attribute_exclusion_config
    config = "test/fixtures/config_attribute_exclusion.yml"
    reference = run_reek_config(config)
    actual = run_fleek_config(config)
    verify_attribute_exclusion_findings(reference, 2, 3)
    AnalysisRunner.assert_detector_findings(actual, reference, "Attribute")
  end

  def self.verify_attribute_disabled
    config = "test/fixtures/config_attribute_disabled.yml"
    actual = run_fleek_disabled(config)
    verify(actual[0] == 1 && actual[2].include?("Reek Attribute is disabled by configuration"), "explicit Attribute selection ignored configured disablement")
  end

  # :reek:TooManyStatements
  def self.verify_attribute_scope_precedence
    config = "test/fixtures/config_attribute_scope.yml"
    disabled = "test/fixtures/attribute.rb"
    enabled = "test/fixtures/attribute_enabled/attribute.rb"
    reference = run_reek_paths("Attribute", config, disabled, enabled)
    actual = run_fleek_paths(config, disabled, enabled)
    reference_output = reference[1]
    verify(reference[0] == 2 && reference_output.include?("Profile#name"), "pinned Reek Attribute scope precedence changed")
    AnalysisRunner.assert_detector_findings(actual, reference, "Attribute")
    verify(actual[1].include?("#{disabled}\" scope=disabled"), "Fleek did not report a detector-disabled source")
  end

  # :reek:TooManyStatements
  def self.verify_instance_variable_exclusion
    source = "test/fixtures/instance_variable_assumption.rb"
    config = "test/fixtures/config_instance_variable_exclusion.yml"
    reference = run_reek_config_for("InstanceVariableAssumption", source, config)
    actual = run_fleek_config_for(source, config)
    verify(reference[0] == 0, "pinned InstanceVariableAssumption exclusion changed")
    AnalysisRunner.assert_detector_findings(actual, reference, "InstanceVariableAssumption")
  end

  def self.verify_default_detector(detector, source)
    reference = run_reek_for(detector, source)
    actual = run_fleek_for(source)
    verify_default_detector_output(detector, reference, actual)
    AnalysisRunner.assert_detector_findings(actual, reference, detector)
  end

  def self.verify_irresponsible_module(source)
    reference = run_reek_for("IrresponsibleModule", source)
    actual = run_fleek_for(source)
    verify_default_detector_output("IrresponsibleModule", reference, actual)
    AnalysisRunner.assert_detector_findings(actual, reference, "IrresponsibleModule")

    verify_descriptive_module_comment
  end

  # :reek:TooManyStatements
  def self.verify_default_detector_output(detector, reference, actual)
    output = actual[1]
    reports = output.lines.select { |line| line.start_with?("Checks run:") || line.start_with?("Checks unsupported:") }
    checks, unsupported = reports
    verify(reference[0] == 2 && reference[1].include?("[1]:#{detector}:"), "pinned #{detector} fixture changed")
    verify(checks&.include?("reek:#{detector}"), "default invocation did not run #{detector}")
    verify(!unsupported&.include?("reek:#{detector}"), "implemented #{detector} remained unsupported")
  end

  def self.verify_descriptive_module_comment
    verify_described_profile_comment
    verify_directive_option_comment
  end

  def self.verify_described_profile_comment
    described = "test/fixtures/described_profile.rb"
    described_reference = run_reek_for("IrresponsibleModule", described)
    described_actual = run_fleek_for(described)
    verify(described_reference[0] == 0, "pinned descriptive comment behavior changed")
    AnalysisRunner.assert_detector_findings(described_actual, described_reference, "IrresponsibleModule")
  end

  def self.verify_directive_option_comment
    source = "test/fixtures/directive_options_profile.rb"
    reference = run_reek_for("IrresponsibleModule", source)
    actual = run_fleek_for(source)
    AnalysisRunner.assert_detector_findings(actual, reference, "IrresponsibleModule")
  end

  def self.run_reek
    process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "reek", "--smell", "Attribute", SOURCE, out: "/tmp/fleek-object-reek.out", err: "/tmp/fleek-object-reek.err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-object-reek.out", "/tmp/fleek-object-reek.err")
  end

  def self.run_reek_for(detector, source)
    AnalysisRunner.observe(spawn_reek(detector, source), "/tmp/fleek-object-reek.out", "/tmp/fleek-object-reek.err")
  end

  def self.spawn_reek(detector, source)
    Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "reek", "--smell", detector, source, out: "/tmp/fleek-object-reek.out", err: "/tmp/fleek-object-reek.err")
  end

  def self.run_reek_config_for(detector, source, config)
    process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "reek", "--smell", detector, "--config", config, source, out: "/tmp/fleek-object-reek.out", err: "/tmp/fleek-object-reek.err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-object-reek.out", "/tmp/fleek-object-reek.err")
  end

  # :reek:LongParameterList
  def self.run_reek_paths(detector, config, first, second)
    process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "reek", "--smell", detector, "--config", config, first, second, out: "/tmp/fleek-object-reek.out", err: "/tmp/fleek-object-reek.err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-object-reek.out", "/tmp/fleek-object-reek.err")
  end

  def self.run_fleek_config_for(source, config)
    process_id = Process.spawn("build/fleek", "--reek-config", config, source, out: "/tmp/fleek-object-fleek.out", err: "/tmp/fleek-object-fleek.err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-object-fleek.out", "/tmp/fleek-object-fleek.err")
  end

  def self.run_fleek_paths(config, first, second)
    process_id = Process.spawn("build/fleek", "--reek-config", config, first, second, out: "/tmp/fleek-object-fleek.out", err: "/tmp/fleek-object-fleek.err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-object-fleek.out", "/tmp/fleek-object-fleek.err")
  end

  def self.run_reek_config(config)
    process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "reek", "--smell", "Attribute", "--config", config, SOURCE, out: "/tmp/fleek-object-reek.out", err: "/tmp/fleek-object-reek.err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-object-reek.out", "/tmp/fleek-object-reek.err")
  end

  def self.run_fleek
    process_id = Process.spawn("build/fleek", SOURCE, out: "/tmp/fleek-object-fleek.out", err: "/tmp/fleek-object-fleek.err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-object-fleek.out", "/tmp/fleek-object-fleek.err")
  end

  def self.run_fleek_for(source)
    process_id = Process.spawn("build/fleek", source, out: "/tmp/fleek-object-fleek.out", err: "/tmp/fleek-object-fleek.err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-object-fleek.out", "/tmp/fleek-object-fleek.err")
  end

  def self.run_fleek_check(detector, source)
    process_id = Process.spawn("build/fleek", "--checks", "reek:#{detector}", source, out: "/tmp/fleek-object-fleek.out", err: "/tmp/fleek-object-fleek.err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-object-fleek.out", "/tmp/fleek-object-fleek.err")
  end

  def self.run_fleek_check_config(detector, source, config)
    process_id = Process.spawn("build/fleek", "--checks", "reek:#{detector}", "--reek-config", config, source, out: "/tmp/fleek-object-fleek.out", err: "/tmp/fleek-object-fleek.err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-object-fleek.out", "/tmp/fleek-object-fleek.err")
  end

  def self.run_fleek_explicit
    process_id = Process.spawn("build/fleek", "--checks", "reek:Attribute", SOURCE, out: "/tmp/fleek-object-fleek.out", err: "/tmp/fleek-object-fleek.err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-object-fleek.out", "/tmp/fleek-object-fleek.err")
  end

  def self.run_fleek_config(config)
    process_id = Process.spawn("build/fleek", "--reek-config", config, SOURCE, out: "/tmp/fleek-object-fleek.out", err: "/tmp/fleek-object-fleek.err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-object-fleek.out", "/tmp/fleek-object-fleek.err")
  end

  def self.run_fleek_disabled(config)
    process_id = Process.spawn("build/fleek", "--checks", "reek:Attribute", "--reek-config", config, SOURCE, out: "/tmp/fleek-object-fleek.out", err: "/tmp/fleek-object-fleek.err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-object-fleek.out", "/tmp/fleek-object-fleek.err")
  end

  # :reek:ControlParameter
  def self.verify(condition, message)
    raise message unless condition
  end
end

DefaultObjectScopeContract.run
