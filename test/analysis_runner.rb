# Runs Fleek and Reek for CLI comparison contracts.
class AnalysisRunner
  # Defines expected public report status and coverage fields.
  ReportExpectation = Struct.new(:status, :coverage, :state, :label)
  def self.fleek(path)
    process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", path, out: "/tmp/fleek-contract-out", err: "/tmp/fleek-contract-err")
    observe(process_id, "/tmp/fleek-contract-out", "/tmp/fleek-contract-err")
  end

  def self.fleek_with_check(check, path)
    process_id = Process.spawn("build/fleek", "--checks", check, path, out: "/tmp/fleek-contract-out", err: "/tmp/fleek-contract-err")
    observe(process_id, "/tmp/fleek-contract-out", "/tmp/fleek-contract-err")
  end

  def self.reek(path)
    run_reek_command(path, "ClassVariable")
  end

  def self.reek_default(path)
    run_reek_command(path, nil)
  end

  def self.run_reek_command(path, smell)
    command = [ENV["BUNDLE"] || "bundle", "exec", "reek"]
    command.concat(["--smell", smell]) if smell
    command << path
    process_id = Process.spawn(*command, out: "/tmp/reek-contract-out", err: "/tmp/reek-contract-err")
    observe(process_id, "/tmp/reek-contract-out", "/tmp/reek-contract-err")
  end

  def self.flay(path)
    process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "flay", path, out: "/tmp/flay-contract-out", err: "/tmp/flay-contract-err")
    observe(process_id, "/tmp/flay-contract-out", "/tmp/flay-contract-err")
  end

  # :reek:ControlParameter
  def self.repeated(tool, path)
    if tool == "fleek"
      process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", path, path, out: "/tmp/fleek-contract-out", err: "/tmp/fleek-contract-err")
      observe(process_id, "/tmp/fleek-contract-out", "/tmp/fleek-contract-err")
    else
      process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "reek", "--smell", "ClassVariable", path, path, out: "/tmp/reek-contract-out", err: "/tmp/reek-contract-err")
      observe(process_id, "/tmp/reek-contract-out", "/tmp/reek-contract-err")
    end
  end

  def self.observe(process_id, output_path, error_path)
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read(output_path), File.read(error_path)]
  end

  def self.assert_report_contains(result, expectation)
    status, fields, label = expectation
    raise label unless result[0] == status && fields.all? { |field| result[1].index(field) != nil }
  end

  def self.assert_reference(actual, reference, label)
    assert_status(actual, reference, label)
    assert_findings(actual, reference, label)
  end

  def self.assert_same_report(actual, reference, label)
    raise "#{label} status differs from Reek" unless actual[0] == reference[0]
    assert_findings(actual, reference, label)
    actual
  end

  def self.assert_report_state(result, expectation)
    output = result[1]
    valid = result[0] == expectation.status && output.include?(expectation.coverage) && output.include?("Status: #{expectation.state}")
    raise "#{expectation.label} report status or coverage differs" unless valid
  end

  def self.assert_unsupported(result, label)
    raise "#{label} unsupported shape appeared clean" unless result[0] == 1 && result[2].include?("unsupported")
  end

  def self.assert_findings(actual, reference, label)
    reports = [actual, reference].map { |result| warning_lines(result[1]) }
    raise "#{label} findings differ from Reek" unless reports[0] == reports[1]
  end

  def self.assert_detector_findings(actual, reference, detector)
    reports = [detector_warnings(actual, detector), detector_warnings(reference, detector)]
    raise "#{detector} findings differ from Reek" unless reports[0].sort == reports[1].sort
  end

  def self.detector_warnings(result, detector)
    warning_lines(result[1]).select { |warning| warning.include?(":#{detector}:") }
  end

  def self.assert_status(actual, reference, label)
    actual_status = actual[0]
    raise "#{label} status differs from Reek" unless actual_status == reference[0] && actual_status == 2
  end

  def self.finding_lines(output)
    output.lines.select { |line| line.include?("Source:") || line.include?("Finding:") || line.include?("Coverage:") || line.include?("Status:") }
  end

  def self.warning_lines(output)
    output.lines.map { |line| warning_from_line(line) }.compact
  end

  def self.warning_from_line(line)
    if line.include?("Finding:")
      marker = line.index(" message=")
      return unless marker
      value = line[(marker + 9)..].strip
      value[1...-1]
    elsif line.include?("ClassVariable:") || line.include?("Attribute:") || line.include?("InstanceVariableAssumption:") || line.include?("SubclassedFromCoreClass:") || line.include?("ModuleInitialize:") || line.include?("IrresponsibleModule:") || line.include?("LongParameterList:") || line.include?("BooleanParameter:") || line.include?("LongYieldList:") || line.include?("ControlParameter:") || line.include?("UnusedParameters:") || line.include?("UtilityFunction:") || line.include?("DuplicateMethodCall:") || line.include?("ManualDispatch:") || line.include?("NilCheck:") || line.include?("MissingSafeMethod:") || line.include?("RepeatedConditional:") || line.include?("NestedIterators:") || line.include?("FeatureEnvy:") || line.include?("DataClump:") || line.include?("TooManyConstants:") || line.include?("TooManyInstanceVariables:") || line.include?("TooManyMethods:") || line.include?("TooManyStatements:") || line.include?("UncommunicativeMethodName:") || line.include?("UncommunicativeModuleName:") || line.include?("UncommunicativeParameterName:") || line.include?("UncommunicativeVariableName:")
      line.strip
    end
  end
end
