# Verifies omitted selection and sources use the documented default CLI policy.
class DefaultInvocationContract
  DIRECTORY = "/tmp/fleek-default-invocation-#{Process.pid}"
  OUTPUT = "/tmp/fleek-default-invocation-#{Process.pid}.out"
  ERROR = "/tmp/fleek-default-invocation-#{Process.pid}.err"

  def self.run
    create_sources
    verify_default_findings(run_default)
    verify_clean_default_status
    verify_empty_default_scan
    puts "Default invocation contract: pass"
  ensure
    cleanup
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
    verify(output.include?("Checks run: flay:StructuralDuplication,reek:ClassVariable"), "supported default checks did not run")
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
