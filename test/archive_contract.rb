# Verifies the extracted arm64 archive without Ruby or reference analyzers on PATH.
class ArchiveContract
  # Describes the public status and report fields of an installed Flay example.
  FlayExampleExpectation = Struct.new(:status, :fields, :message)
  # :reek:ControlParameter
  def self.verify(condition, message)
    raise message unless condition
  end

  def self.observe(process_id, output_path, error_path)
    status = Process.waitpid2(process_id)[1].exitstatus
    output = File.read(output_path)
    error = File.read(error_path)
    [status, output, error]
  end

  def self.output_path
    "/tmp/fleek-archive-contract-#{Process.pid}-out"
  end

  def self.error_path
    "/tmp/fleek-archive-contract-#{Process.pid}-err"
  end

  # :reek:ControlParameter
  # :reek:TooManyStatements
  def self.run(executable, arguments)
    output = output_path
    error = error_path
    directory = File.dirname(executable)
    first_argument = arguments[0]
    process_id = if first_argument == "--checks"
                   Process.spawn("env", "PATH=", executable, "--checks", arguments[1], arguments[2], chdir: directory, out: output, err: error)
                 else
                   Process.spawn("env", "PATH=", executable, first_argument, chdir: directory, out: output, err: error)
                 end
    observe(process_id, output, error)
  end

  def self.extract(archive, destination)
    Dir.mkdir(destination)
    result = extract_result(archive, destination)
    verify(result[0] == 0, "archive extraction failed")
    File.join(destination, "fleek-0.2.0-macos-arm64")
  end

  def self.extract_result(archive, destination)
    output = output_path
    error = error_path
    process_id = Process.spawn("tar", "-xzf", archive, "-C", destination, out: output, err: error)
    observe(process_id, output, error)
  end

  def self.verify_fields(report, fields, message)
    fields.each { |field| verify(report.include?(field), message) }
  end

  # :reek:TooManyStatements
  def self.verify_architecture(executable)
    output = output_path
    error = error_path
    process_id = Process.spawn("file", executable, out: output, err: error)
    result = observe(process_id, output, error)
    verify(result[0] == 0 && result[1].include?("arm64"), "installed executable architecture differs")
  end

  # :reek:TooManyStatements
  def self.verify_linkage(executable)
    output = output_path
    error = error_path
    process_id = Process.spawn("otool", "-L", executable, out: output, err: error)
    result = observe(process_id, output, error)
    libraries = result[1].lines.select { |line| line.include?(".dylib") }
    verify(result[0] == 0 && libraries.length == 1 && libraries[0].include?("/usr/lib/libSystem.B.dylib"), "installed native linkage differs")
  end

  # :reek:TooManyStatements
  def self.verify_signature(executable)
    output = output_path
    error = error_path
    process_id = Process.spawn("codesign", "-dv", "--verbose=4", executable, out: output, err: error)
    result = observe(process_id, output, error)
    verify(result[0] == 0, "installed signature inspection failed")
    verify_fields(result[2], ["Signature=adhoc", "TeamIdentifier=not set"], "installed signature status differs")
  end

  def self.verify_identity(executable)
    verify_architecture(executable)
    verify_linkage(executable)
    verify_signature(executable)
    verify_version(executable)
    verify_help(executable)
  end

  def self.verify_version(executable)
    version = run(executable, ["--version"])
    verify(version[0] == 0 && version[2].empty?, "installed version status differs")
    verify_fields(version[1], ["Fleek 0.2.0", "Spinel 2026.09.12"], "installed version identity differs")
  end

  def self.verify_help(executable)
    help = run(executable, ["--help"])
    verify(help[0] == 0 && help[2].empty?, "installed help status differs")
    verify_fields(help[1], ["Supported checks:", "Analysis requires --checks", "uncovered checks are reported as not run"], "installed help differs")
  end

  def self.verify_clean_example(executable, source)
    result = run(executable, ["--checks", "flay:StructuralDuplication,reek:ClassVariable", source])
    verify(result[0] == 0 && result[1].include?("Overall status: complete"), "installed clean checks differed")
  end

  def self.verify_finding_example(executable, source)
    result = run(executable, ["--checks", "reek:ClassVariable", source])
    verify(result[0] == 2, "installed finding exit status differed")
    verify_fields(result[1], ["lines=\"2\"", "context=\"Counter\"", "name=\"@@count\"", "Status: findings"], "installed finding fields differed")
  end

  def self.verify_flay_example(executable, source, expectation)
    result = run(executable, ["--checks", "flay:StructuralDuplication", source])
    message = expectation.message
    verify(result[0] == expectation.status, message)
    verify_fields(result[1], expectation.fields, message)
  end

  # :reek:TooManyStatements
  def self.verify_examples(root, executable)
    examples = File.join(root, "examples")
    verify_clean_example(executable, File.join(examples, "clean.rb"))
    verify_finding_example(executable, File.join(examples, "finding.rb"))
    incomplete_fields = ["examples/incomplete.rb:4", "examples/incomplete.rb:15", "mass=48 score=48",
      "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete", "scope=partial"]
    incomplete = FlayExampleExpectation.new(1, incomplete_fields, "installed incomplete example differed")
    verify_flay_example(executable, File.join(examples, "incomplete.rb"), incomplete)
    module_fields = ["kind=\"similar\"", "module-methods.rb:2,", "module-methods.rb:9\"", "mass=48 score=48",
      "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
    module_example = FlayExampleExpectation.new(2, module_fields, "installed module-method example differed")
    verify_flay_example(executable, File.join(examples, "module-methods.rb"), module_example)
  end

  def self.verify_notices(root)
    fleek_license = File.read(File.join(root, "LICENSE-Fleek.txt"))
    prism_license = File.read(File.join(root, "LICENSE-Prism.txt"))
    verify(fleek_license.include?("Apache License") && prism_license.include?("Copyright 2022-present, Shopify Inc."), "required license notices missing")
    readme = File.read(File.join(root, "README.txt"))
    verify(readme.include?("partial") && readme.include?("ad hoc linker signature") && readme.include?("not notarized"), "archive scope or signing status missing")
  end
end

archive = "dist/fleek-0.2.0-macos-arm64.tar.gz"
checksum = "#{archive}.sha256"
ArchiveContract.verify(File.file?(archive) && File.file?(checksum), "versioned archive or checksum missing")
output = ArchiveContract.output_path
error = ArchiveContract.error_path
checksum_process = Process.spawn("shasum", "-a", "256", "-c", checksum, out: output, err: error)
integrity = ArchiveContract.observe(checksum_process, output, error)
ArchiveContract.verify(integrity[0] == 0, "archive checksum verification failed")
destination = "/tmp/fleek-archive-contract-#{Process.pid}"
root = ArchiveContract.extract(archive, destination)
executable = File.join(root, "fleek")
ArchiveContract.verify(File.file?(executable), "extracted executable missing")
ArchiveContract.verify_identity(executable)
ArchiveContract.verify_examples(root, executable)
ArchiveContract.verify_notices(root)

puts "Standalone macOS arm64 archive contract: pass"
