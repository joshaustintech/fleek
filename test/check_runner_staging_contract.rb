# frozen_string_literal: true

require_relative "../bin/workspace_stager"

# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:IrresponsibleModule
# :reek:TooManyStatements

class CheckRunnerStagingContract
  def self.run
    root = "#{ENV.fetch('FLEEK_TEMP_ROOT')}/staging-contract-#{Process.pid}"
    source = "#{root}/source"
    destination = "#{root}/worker"
    create_source(source)
    expect(WorkspaceStager.copy(source, destination), "workspace staging failed")
    verify_required_inputs(destination)
    verify_exclusions(destination)
    verify_source_isolation(source, destination)
    puts "Check runner staging contract: pass"
  ensure
    cleanup(root) if root
  end

  def self.create_source(source)
    [source, "#{source}/test", "#{source}/test/fixtures", "#{source}/.githooks", "#{source}/.git",
      "#{source}/dist", "#{source}/build", "#{source}/build/mutation-reference-cache"].each do |path|
      process_id = Process.spawn("mkdir", "-p", path, out: "/dev/null", err: "/dev/null")
      _, status = Process.waitpid2(process_id)
      expect(status.success?, "could not prepare staging fixture")
    end
    File.write("#{source}/README.md", "edited tracked source marker")
    File.write("#{source}/test/fixtures/untracked.rb", "new untracked fixture marker")
    File.write("#{source}/.githooks/commit-msg", "required hook marker")
    File.write("#{source}/.gitignore", "required hidden config marker")
    File.write("#{source}/AGENTS.md", "required instructions marker")
    File.write("#{source}/build/fleek", "baseline executable marker")
    File.write("#{source}/.git/config", "git metadata sentinel")
    File.write("#{source}/dist/release.tar.gz", "release archive sentinel")
    File.write("#{source}/build/mutation-reference-cache/contract", "cache sentinel")
  end

  def self.verify_required_inputs(destination)
    expect(File.read("#{destination}/README.md") == "edited tracked source marker", "edited source was not staged")
    expect(File.read("#{destination}/test/fixtures/untracked.rb") == "new untracked fixture marker",
      "untracked fixture was not staged")
    expect(File.file?("#{destination}/.githooks/commit-msg"), "required hidden hook was not staged")
    expect(File.file?("#{destination}/.gitignore"), "required hidden configuration was not staged")
    expect(File.file?("#{destination}/AGENTS.md"), "agent instructions were not staged")
    expect(File.file?("#{destination}/build/fleek"), "baseline executable was not staged")
  end

  def self.verify_exclusions(destination)
    expect(!Dir.exist?("#{destination}/.git"), "Git metadata sentinel reached worker")
    expect(!Dir.exist?("#{destination}/dist"), "release archive sentinel reached worker")
    expect(!Dir.exist?("#{destination}/build/mutation-reference-cache"), "contract cache sentinel reached worker")
  end

  def self.verify_source_isolation(source, destination)
    File.write("#{destination}/README.md", "worker edit")
    expect(File.read("#{source}/README.md") == "edited tracked source marker", "worker source was hard-linked")
  end

  def self.cleanup(root)
    process_id = Process.spawn("rm", "-rf", root, out: "/dev/null", err: "/dev/null")
    _, status = Process.waitpid2(process_id)
    expect(status.success?, "could not clean staging contract")
  end

  def self.expect(condition, message)
    raise message unless condition
  end
end

CheckRunnerStagingContract.run
