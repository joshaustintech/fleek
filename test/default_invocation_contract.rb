require_relative "analysis_runner"
# Verifies omitted selection and sources use the documented default CLI policy.
class DefaultInvocationContract
  DIRECTORY = "/tmp/fleek-default-invocation-#{Process.pid}"
  OUTPUT = "/tmp/fleek-default-invocation-#{Process.pid}.out"
  ERROR = "/tmp/fleek-default-invocation-#{Process.pid}.err"

  # :reek:TooManyStatements
  def self.run
    create_sources
    verify_default_findings(run_default)
    verify_configuration_profiles
    verify_clean_default_status
    verify_supported_clean_profile
    verify_supported_findings_status
    verify_explicit_default_subset
    verify_configured_opt_in_runs
    verify_empty_default_scan
    puts "Default invocation contract: pass"
  ensure
    cleanup
  end

  def self.verify_disabled_default_detector
    result = run_with_config(File.expand_path("fixtures/config_disabled.yml", __dir__))
    output = result[1]
    selected = output.lines.find { |line| line.start_with?("Checks selected:") }
    verify_disabled_profile(selected, output)
  end

  def self.verify_disabled_profile(selected, output)
    verify(!selected.include?("reek:ClassVariable"), "disabled supported detector remained selected")
    verify(output.include?("Checks disabled: reek:ClassVariable"), "disabled supported detector was not identified")
    verify(!output.include?("Smell coverage:"), "disabled supported detector still ran")
  end

  def self.verify_configuration_profiles
    verify_configured_default_profile
    verify_disabled_default_detector
  end

  def self.verify_configured_default_profile
    verify_configured_result(run_configured_default_profile)
  end

  def self.verify_configured_result(result)
    status, output, error = result
    verify(status == 1, "configured opt-in default did not remain incomplete")
    verify_configured_coverage_line(output)
    verify_exclusion_independence(error)
  end

  def self.verify_configured_coverage_line(output)
    selected = output.lines.find { |line| line.start_with?("Checks selected:") }
    verify_configured_coverage(selected, output)
  end

  def self.run_configured_default_profile
    File.write("#{DIRECTORY}/.reek.yml", "detectors:\n  Attribute:\n    enabled: false\n  UnusedPrivateMethod:\n    enabled: true\nexclude_paths:\n  - counter.rb\n")
    result = run_default
    File.delete("#{DIRECTORY}/.reek.yml")
    result
  end

  def self.verify_configured_coverage(selected, output)
    verify(configured_opt_in_profile?(selected, output.lines, output), "configured opt-in detector profile differed")
  end

  def self.configured_opt_in_profile?(selected, lines, output)
    check = "reek:UnusedPrivateMethod"
    run, unsupported = lines.select { |line| line.start_with?("Checks run:", "Checks unsupported:") }
    !selected.include?("reek:Attribute") && output.include?("Checks disabled: reek:Attribute") && run.include?(check) && !unsupported.include?(check)
  end

  def self.verify_exclusion_independence(error)
    verify(error.include?("unsupported Flay candidate syntax"), "Reek path exclusion changed independent Flay analysis")
  end

  def self.create_sources
    create_tree
    create_files
    File.symlink("#{DIRECTORY}/real", "#{DIRECTORY}/alias")
    verify(File.file?("#{DIRECTORY}/real/linked.rb"), "directory source setup failed")
  end

  def self.create_tree
    Dir.mkdir(DIRECTORY)
    Dir.mkdir("#{DIRECTORY}/.hidden")
    Dir.mkdir("#{DIRECTORY}/real")
  end

  def self.create_files
    File.write("#{DIRECTORY}/counter.rb", "class Counter\n  @@count = 1\nend\n")
    File.write("#{DIRECTORY}/.hidden/ignored.rb", "class Hidden\n  @@count = 1\nend\n")
    File.write("#{DIRECTORY}/real/linked.rb", "def linked\n  3\nend\n")
  end

  def self.verify_default_findings(result)
    status, output, error = result
    verify(status == 1, "default run did not remain incomplete for unsupported enabled defaults")
    verify(output.include?(expected_checks) && !output.include?("reek:UnusedPrivateMethod"), "default enabled check list differs or included an opt-in detector")
    verify(error.include?("unsupported Flay candidate syntax"), "supported check diagnostic was lost")
    verify_default_sections(output)
  end

  def self.verify_default_sections(output)
    verify(output.include?("Checks run: flay:StructuralDuplication,reek:Attribute,reek:BooleanParameter,reek:ClassVariable,reek:ControlParameter,reek:DataClump,reek:DuplicateMethodCall,reek:FeatureEnvy,reek:InstanceVariableAssumption,reek:IrresponsibleModule,reek:LongParameterList,reek:LongYieldList,reek:ManualDispatch,reek:MissingSafeMethod,reek:ModuleInitialize,reek:NestedIterators,reek:NilCheck,reek:RepeatedConditional,reek:SubclassedFromCoreClass,reek:TooManyConstants,reek:TooManyInstanceVariables,reek:TooManyMethods,reek:TooManyStatements,reek:UncommunicativeMethodName,reek:UncommunicativeModuleName,reek:UncommunicativeParameterName,reek:UncommunicativeVariableName,reek:UnusedParameters,reek:UtilityFunction"), "supported default checks did not run")
    verify(output.include?("Checks disabled: none"), "disabled default checks were not reported")
    verify(output.include?("Overall status: incomplete"), "unsupported defaults did not keep the report incomplete")
    verify_default_sources(output)
  end

  def self.verify_default_sources(output)
    verify(output.include?("counter.rb") && output.include?("@@count"), "CWD source findings were lost")
    verify(!output.include?("ignored.rb"), "hidden directory source was scanned")
    verify(!output.include?("alias/linked.rb"), "directory symlink was scanned")
  end

  def self.expected_checks
    "Checks selected: flay:StructuralDuplication,reek:Attribute,reek:BooleanParameter,reek:ClassVariable,reek:ControlParameter,reek:DataClump,reek:DuplicateMethodCall,reek:FeatureEnvy,reek:InstanceVariableAssumption,reek:IrresponsibleModule,reek:LongParameterList,reek:LongYieldList,reek:ManualDispatch,reek:MissingSafeMethod,reek:ModuleInitialize,reek:NestedIterators,reek:NilCheck,reek:RepeatedConditional,reek:SubclassedFromCoreClass,reek:TooManyConstants,reek:TooManyInstanceVariables,reek:TooManyMethods,reek:TooManyStatements,reek:UncommunicativeMethodName,reek:UncommunicativeModuleName,reek:UncommunicativeParameterName,reek:UncommunicativeVariableName,reek:UnusedParameters,reek:UtilityFunction"
  end

  def self.verify_clean_default_status
    File.delete("#{DIRECTORY}/real/linked.rb")
    File.write("#{DIRECTORY}/counter.rb", "def alpha\n  1\nend\n\ndef beta\n  2\nend\n")
    verify_clean_result(run_default)
  end

  # :reek:TooManyStatements
  def self.verify_supported_clean_profile
    path = File.expand_path("fixtures/default_full_profile_clean.rb", __dir__)
    actual = run_process([path])
    status, output, error = actual
    verify(status == 0, "supported clean default profile did not succeed")
    verify(output.include?("Checks unsupported: none") && output.include?("Overall status: complete"), "supported clean default profile was incomplete")
    verify(!output.include?("reek:UnusedPrivateMethod"), "opt-in detector appeared in a supported default run")
    verify_default_flay_metrics(actual, AnalysisRunner.flay(path))
    verify(error.empty?, "supported clean default profile wrote an unexpected diagnostic: #{error}")
  end

  def self.verify_default_flay_metrics(actual, reference)
    native = actual[1].match(/Total duplication score: (\d+)/)
    upstream = reference[1].match(/Total score \(lower is better\) = (\d+)/)
    verify(reference[0] == 0 && native && upstream && native[1] == upstream[1], "default Flay score differs from pinned Flay")
  end

  def self.verify_clean_result(result)
    status, output, error = result
    verify(status == 0, "clean default run did not succeed")
    verify(output.include?("Overall status: complete"), "clean default run remained incomplete")
    verify(error.empty?, "clean default run wrote an unexpected diagnostic: #{error}")
  end

  # :reek:TooManyStatements
  def self.verify_supported_findings_status
    path = File.expand_path("fixtures/default_full_profile_findings.rb", __dir__)
    actual = run_process([path])
    status, output, error = actual
    reference = AnalysisRunner.reek_default(path)
    verify(status == 2, "supported default findings did not return findings status")
    verify(output.include?("Checks unsupported: none") && output.include?("Overall status: findings"), "supported default findings did not complete")
    verify_ordered_default_findings(actual, reference)
    verify(error.empty?, "supported default findings wrote an unexpected diagnostic: #{error}")
  end

  def self.verify_ordered_default_findings(actual, reference)
    native = fleek_finding_records(actual[1])
    upstream = reek_finding_records(reference[1])
    verify(reference[0] == 2 && native == upstream, "default findings, locations, or ordering differ from Reek")
  end

  # :reek:TooManyStatements
  def self.fleek_finding_records(output)
    output.lines.select { |line| line.include?("Finding:") }.map do |line|
      detector = report_field(line, "check").delete_prefix("reek:")
      location = report_field(line, "lines")
      message = report_field(line, "message").match(/^\[.*?\]:[^:]+: (.*)$/)
      raise "Fleek finding message is malformed" unless message
      [detector, location, message[1]]
    end
  end

  # :reek:TooManyStatements
  def self.reek_finding_records(output)
    output.lines.filter_map do |line|
      finding = line.match(/^\s*\[(.*?)\]:([^:]+): (.*)$/)
      if finding
        location = finding[1]
        detector = finding[2]
        message = finding[3]
        [detector, location, message]
      end
    end
  end

  def self.report_field(line, name)
    match = line.match(/#{name}="([^"]*)"/)
    raise "Fleek finding is missing #{name}" unless match
    match[1]
  end

  def self.verify_explicit_default_subset
    status, output, = run_process(["--checks", "reek:UncommunicativeModuleName", File.expand_path("fixtures/default_full_profile_findings.rb", __dir__)])
    verify(status == 2, "explicit default subset did not preserve findings status")
    verify(output.include?("Checks selected: reek:UncommunicativeModuleName\nChecks run: reek:UncommunicativeModuleName\n"), "explicit checks did not remain a subset")
  end

  def self.verify_configured_opt_in_runs
    result = run_configured_opt_in
    verify_configured_opt_in_status(result)
    output = result[1]
    verify_configured_opt_in_finding(output)
    File.delete("#{DIRECTORY}/private.rb")
  end

  def self.run_configured_opt_in
    File.write("#{DIRECTORY}/.reek.yml", "detectors:\n  UnusedPrivateMethod:\n    enabled: true\n")
    File.write("#{DIRECTORY}/private.rb", "class ConfiguredPrivate\n  private\n  def hidden\n    1\n  end\nend\n")
    run_default
  end

  def self.verify_configured_opt_in_status(result)
    output = result[1]
    checks = [result[0] == 1, output.include?("Checks run:"), !output.lines.find { |line| line.start_with?("Checks unsupported:") }.include?("reek:UnusedPrivateMethod")]
    verify(checks.all?, "configured opt-in check did not run as a supported default")
  end

  def self.verify_configured_opt_in_finding(output)
    verify(output.include?('Finding: check="reek:UnusedPrivateMethod"') && output.include?('name="hidden"'), "configured opt-in default omitted its private-method finding")
  end

  def self.verify_empty_default_scan
    File.delete("#{DIRECTORY}/counter.rb")
    result = run_default
    verify(result[0] == 1, "empty default scan was successful")
    verify(result[2].include?("No Ruby source files discovered"), "empty default scan diagnostic was lost")
  end

  # :reek:ControlParameter
  def self.verify(condition, message)
    raise message unless condition
  end

  def self.run_default
    run_process
  end

  def self.run_with_config(config)
    File.write("#{DIRECTORY}/.reek.yml", File.read(config))
    run_process
  ensure
    File.delete("#{DIRECTORY}/.reek.yml") if File.file?("#{DIRECTORY}/.reek.yml")
  end

  def self.run_process(arguments = [])
    executable = File.expand_path("../build/fleek", __dir__)
    process_id = spawn_process(executable, arguments)
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read(OUTPUT), File.read(ERROR)]
  end

  # :reek:TooManyStatements
  def self.spawn_process(executable, arguments)
    count = arguments.length
    first = arguments[0]
    second = arguments[1]
    third = arguments[2]
    case count
    when 1 then spawn_one(executable, first)
    when 3 then spawn_subset(executable, first, second, third)
    else spawn_default(executable)
    end
  end

  def self.spawn_default(executable)
    Process.spawn(executable, chdir: DIRECTORY, out: OUTPUT, err: ERROR)
  end

  def self.spawn_one(executable, path)
    Process.spawn(executable, path, chdir: DIRECTORY, out: OUTPUT, err: ERROR)
  end

  # :reek:LongParameterList
  def self.spawn_subset(executable, option, checks, path)
    Process.spawn(executable, option, checks, path, chdir: DIRECTORY, out: OUTPUT, err: ERROR)
  end

  def self.cleanup
    cleanup_sources
    File.delete(OUTPUT) if File.exist?(OUTPUT)
    File.delete(ERROR) if File.exist?(ERROR)
  end

  def self.cleanup_sources
    cleanup_files
    cleanup_directories
  end

  def self.cleanup_files
    ["#{DIRECTORY}/counter.rb", "#{DIRECTORY}/private.rb", "#{DIRECTORY}/.hidden/ignored.rb",
     "#{DIRECTORY}/real/linked.rb", "#{DIRECTORY}/alias", "#{DIRECTORY}/.reek.yml"].each do |path|
      remove_if_present(path)
    end
  end

  # :reek:ControlParameter
  def self.remove_if_present(path)
    File.delete(path) if File.exist?(path)
  end

  def self.cleanup_directories
    Dir.rmdir("#{DIRECTORY}/real") if Dir.exist?("#{DIRECTORY}/real")
    Dir.rmdir("#{DIRECTORY}/.hidden") if Dir.exist?("#{DIRECTORY}/.hidden")
    Dir.rmdir(DIRECTORY) if Dir.exist?(DIRECTORY)
  end
end

DefaultInvocationContract.run
