# frozen_string_literal: true

require_relative "../bin/workspace_stager"
require_relative "contract_support"

# :reek:IrresponsibleModule
# :reek:TooManyStatements
class CheckRunnerStagingContract
  def self.run
    root = "#{ENV.fetch('FLEEK_TEMP_ROOT')}/staging-contract-#{Process.pid}"
    source = "#{root}/source"
    destination = "#{root}/worker"
    create_source(source)
    ContractSupport.expect(WorkspaceStager.copy(source, destination), "workspace staging failed")
    verify_required_inputs(destination)
    verify_exclusions(destination)
    verify_source_isolation(source, destination)
    puts "Check runner staging contract: pass"
  ensure
    ContractSupport.cleanup(root, "staging contract") if root
  end

  def self.create_source(source)
    ContractSupport.create_test_directories(source, "staging")
    File.write("#{source}/README.md", "edited tracked source marker")
    File.write("#{source}/test/fixtures/untracked.rb", "new untracked fixture marker")
    File.write("#{source}/.githooks/commit-msg", "required hook marker")
    File.write("#{source}/.gitignore", "required hidden config marker")
    File.write("#{source}/AGENTS.md", "required instructions marker")
    File.write("#{source}/build/fleek", "baseline executable marker")
    File.write("#{source}/.git/config", "git metadata sentinel")
    File.write("#{source}/dist/release.tar.gz", "release archive sentinel")
    File.write("#{source}/build/mutation-reference-cache/contract", "cache sentinel")
    ContractSupport.create_directories(["#{source}/build/mutation-contract-cache"])
    File.write("#{source}/build/mutation-contract-cache/contract", "persistent cache sentinel")
  end

  def self.verify_required_inputs(destination)
    ContractSupport.expect(File.read("#{destination}/README.md") == "edited tracked source marker", "edited source was not staged")
    ContractSupport.expect(File.read("#{destination}/test/fixtures/untracked.rb") == "new untracked fixture marker",
      "untracked fixture was not staged")
    ContractSupport.expect(File.file?("#{destination}/.githooks/commit-msg"), "required hidden hook was not staged")
    ContractSupport.expect(File.file?("#{destination}/.gitignore"), "required hidden configuration was not staged")
    ContractSupport.expect(File.file?("#{destination}/AGENTS.md"), "agent instructions were not staged")
    ContractSupport.expect(File.file?("#{destination}/build/fleek"), "baseline executable was not staged")
  end

  def self.verify_exclusions(destination)
    ContractSupport.expect(!Dir.exist?("#{destination}/.git"), "Git metadata sentinel reached worker")
    ContractSupport.expect(!Dir.exist?("#{destination}/dist"), "release archive sentinel reached worker")
    ContractSupport.expect(!Dir.exist?("#{destination}/build/mutation-reference-cache"), "contract cache sentinel reached worker")
    ContractSupport.expect(!Dir.exist?("#{destination}/build/mutation-contract-cache"), "persistent contract cache reached worker")
  end

  def self.verify_source_isolation(source, destination)
    File.write("#{destination}/README.md", "worker edit")
    ContractSupport.expect(File.read("#{source}/README.md") == "edited tracked source marker", "worker source was hard-linked")
  end
end

CheckRunnerStagingContract.run
