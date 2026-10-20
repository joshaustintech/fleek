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

  def self.cleanup_contract_outputs(paths, actual_output_path)
    cleanup_paths = ENV.key?("FLEEK_TEMP_ROOT") ? paths : paths + [actual_output_path]
    cleanup_paths.each { |file| File.delete(file) if file && File.file?(file) }
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

# Compares one compiled Flay method-candidate report with pinned Flay.
class FlayMethodCandidateContract
  # :reek:TooManyStatements
  def self.verify_unsupported(path, label, reference_score)
    root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
    actual_output_path = "#{root}/#{label}-actual.out"
    actual_error_path = "#{root}/#{label}-actual.err"
    reference_output_path = "#{root}/#{label}-reference.out"
    reference_error_path = "#{root}/#{label}-reference.err"
    actual_status = run_fleek(path, actual_output_path, actual_error_path)
    reference_status = run_flay(path, reference_output_path, reference_error_path)
    actual_output = File.read(actual_output_path)
    reference_output = File.read(reference_output_path)
    actual_valid = actual_status == 1 && actual_output.include?("Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded") && actual_output.include?("Status: incomplete") && File.read(actual_error_path).include?("unsupported Flay candidate syntax")
    reference_valid = reference_status.success? && reference_output.include?("code found in :defn") && reference_output.include?("#{path}:1") && reference_output.include?("#{path}:5") && reference_output.include?("Total score (lower is better) = #{reference_score}")
    raise "#{label} unsupported result differed from Flay: #{actual_output} #{reference_output}" unless actual_valid && reference_valid
    puts "#{label} contract: pass"
  ensure
    AnalysisRunner.cleanup_contract_outputs([actual_error_path, reference_output_path, reference_error_path], actual_output_path)
  end

  # :reek:TooManyStatements
  def self.verify_no_group(path, label)
    root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
    actual_output_path = "#{root}/#{label}-actual.out"
    actual_error_path = "#{root}/#{label}-actual.err"
    reference_output_path = "#{root}/#{label}-reference.out"
    reference_error_path = "#{root}/#{label}-reference.err"
    actual_status = run_fleek(path, actual_output_path, actual_error_path)
    reference_status = run_flay(path, reference_output_path, reference_error_path)
    actual_output = File.read(actual_output_path)
    reference_output = File.read(reference_output_path)
    coverage = "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded"
    actual_valid = actual_status.zero? && !actual_output.include?("Group:") && actual_output.include?(coverage) && actual_output.include?("Status: complete") && actual_output.include?("Total duplication score: 0")
    reference_valid = reference_status.success? && !reference_output.include?("code found in :defn") && reference_output.include?("Total score (lower is better) = 0")
    raise "#{label} clean result differed from Flay: #{actual_output} #{reference_output}" unless actual_valid && reference_valid
    puts "#{label} contract: pass"
  ensure
    AnalysisRunner.cleanup_contract_outputs([actual_error_path, reference_output_path, reference_error_path], actual_output_path)
  end

  # :reek:LongParameterList
  # :reek:TooManyStatements
  def self.verify(path, label, mass, first_line, second_line)
    root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
    actual_output_path = "#{root}/#{label}-actual.out"
    actual_error_path = "#{root}/#{label}-actual.err"
    reference_output_path = "#{root}/#{label}-reference.out"
    reference_error_path = "#{root}/#{label}-reference.err"
    actual_status = run_fleek(path, actual_output_path, actual_error_path)
    reference_status = run_flay(path, reference_output_path, reference_error_path)
    actual_output = File.read(actual_output_path)
    reference_output = File.read(reference_output_path)
    actual_error = File.read(actual_error_path)
    reference_error = File.read(reference_error_path)
    reference_group = reference_output.lines.find { |line| line.include?("code found in :defn") }
    raise "#{label} Flay reference failed: #{reference_output} #{reference_error}" unless reference_status.success? && reference_group
    raise "#{label} Flay mass differed: #{reference_group}" unless reference_mass(reference_group) == mass
    raise "#{label} methods were not analyzed: #{actual_output} #{actual_error}" unless actual_status == 2
    kind = reference_group.include?("IDENTICAL code") ? "identical" : "similar"
    score = kind == "identical" ? mass * 2 : mass
    locations = [first_line, second_line].map { |line| "#{path}:#{line}" }.join(",")
    reference_fields = ["#{path}:#{first_line}", "#{path}:#{second_line}", "Total score (lower is better) = #{score}"]
    raise "#{label} Flay locations or score differed: #{reference_output}" unless reference_fields.all? { |field| reference_output.include?(field) }
    actual_group = actual_output.lines.find { |line| line.include?('node="defn"') }
    expected = ["kind=\"#{kind}\"", "locations=\"#{locations}\"", "mass=#{mass} score=#{score}"]
    raise "#{label} kind, mass, or locations differed from Flay: #{actual_group}" unless actual_group && expected.all? { |field| actual_group.include?(field) }
    coverage = "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded"
    raise "#{label} coverage was incomplete: #{actual_output}" unless actual_output.include?(coverage) && actual_output.include?("Status: findings")
    puts "#{label} contract: pass"
  ensure
    AnalysisRunner.cleanup_contract_outputs([actual_error_path, reference_output_path, reference_error_path], actual_output_path)
  end

  # :reek:TooManyStatements
  def self.verify_empty_stderr(path, label)
    root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
    actual_output_path = "#{root}/#{label}-actual.out"
    actual_error_path = "#{root}/#{label}-actual.err"
    reference_output_path = "#{root}/#{label}-reference.out"
    reference_error_path = "#{root}/#{label}-reference.err"
    run_fleek(path, actual_output_path, actual_error_path)
    run_flay(path, reference_output_path, reference_error_path)
    actual_error = File.read(actual_error_path)
    reference_error = File.read(reference_error_path)
    raise "#{label} wrote to stderr: #{actual_error} #{reference_error}" unless actual_error.empty? && reference_error.empty?
  ensure
    AnalysisRunner.cleanup_contract_outputs([actual_error_path, reference_output_path, reference_error_path], actual_output_path)
  end

  def self.run_fleek(path, output, error)
    process_id = spawn_fleek(path, output, error)
    _, status = Process.waitpid2(process_id)
    status.exitstatus
  end

  def self.spawn_fleek(path, output, error)
    Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", "3", path,
      out: output, err: error)
  end

  def self.run_flay(path, output, error)
    process_id = spawn_flay(path, output, error)
    _, status = Process.waitpid2(process_id)
    status
  end

  def self.spawn_flay(path, output, error)
    Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "flay", "--mass", "3", path,
      out: output, err: error)
  end

  def self.reference_mass(group)
    mass = group[/mass = (\d+)/, 1]
    return mass.to_i if mass
    group[/mass\*2 = (\d+)/, 1].to_i / 2
  end
end
