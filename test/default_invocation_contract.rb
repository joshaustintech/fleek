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
    opt_in_present = output.include?("reek:UnusedPrivateMethod")
    verify(!selected.include?("reek:Attribute"), "disabled default detector remained selected")
    verify(opt_in_present, "configured opt-in detector was not selected")
    verify(output.include?("Checks disabled: reek:Attribute"), "configured disabled detector was not identified")
    verify(output.include?("Checks unsupported:") && opt_in_present, "configured unsupported opt-in detector was hidden")
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
    verify(output.include?(expected_checks), "default enabled check list differs")
    verify(error.include?("unsupported Flay candidate syntax"), "supported check diagnostic was lost")
    verify_default_sections(output)
  end

  def self.verify_default_sections(output)
    verify(output.include?("Checks run: flay:StructuralDuplication,reek:Attribute,reek:BooleanParameter,reek:ClassVariable,reek:ControlParameter,reek:InstanceVariableAssumption,reek:IrresponsibleModule,reek:LongParameterList,reek:LongYieldList,reek:ModuleInitialize,reek:SubclassedFromCoreClass,reek:UnusedParameters,reek:UtilityFunction"), "supported default checks did not run")
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

  def self.verify_clean_result(result)
    status, output, error = result
    verify(status == 1, "clean default run did not remain incomplete")
    verify(output.include?("Overall status: incomplete"), "unsupported defaults did not keep a clean run incomplete")
    verify(error.empty?, "clean default run wrote an unexpected diagnostic: #{error}")
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

  def self.run_process
    process_id = Process.spawn(File.expand_path("../build/fleek", __dir__), chdir: DIRECTORY, out: OUTPUT, err: ERROR)
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read(OUTPUT), File.read(ERROR)]
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
    remove_if_present("#{DIRECTORY}/counter.rb")
    remove_if_present("#{DIRECTORY}/.hidden/ignored.rb")
    remove_if_present("#{DIRECTORY}/real/linked.rb")
    remove_if_present("#{DIRECTORY}/alias")
    remove_if_present("#{DIRECTORY}/.reek.yml")
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
