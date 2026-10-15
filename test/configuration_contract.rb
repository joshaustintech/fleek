require_relative "analysis_runner"
# Verifies imported Reek settings through compiled CLI processes.
class ConfigurationProcess
  # Describes one reference-comparison invocation.
  Input = Struct.new(:path, :config, :label, :stdin, :tool)

  def self.run_fleek_stdin(input)
    process_id = Process.spawn(File.expand_path("build/fleek"), "--checks", "reek:ClassVariable", "--reek-config", input.config, "--stdin", input.path, in: input.stdin, out: "/tmp/fleek-config-out", err: "/tmp/fleek-config-err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-config-out", "/tmp/fleek-config-err")
  end

  def self.invoke(input)
    tool = input.tool
    if input.stdin.empty?
      process_id = run_file(input)
      AnalysisRunner.observe(process_id, "/tmp/#{tool}-config-out", "/tmp/#{tool}-config-err")
    elsif tool == "fleek"
      run_fleek_stdin(input)
    else
      run_reek_stdin(input)
    end
  end

  def self.run_file(input)
    input.tool == "fleek" ? spawn_fleek_file(input) : spawn_reek_file(input)
  end

  def self.spawn_fleek_file(input)
    executable = File.expand_path("build/fleek")
    path = input.path
    config = input.config
    if config.empty?
      Process.spawn(executable, "--checks", "reek:ClassVariable", path, in: "/dev/null", out: "/tmp/fleek-config-out", err: "/tmp/fleek-config-err")
    else
      Process.spawn(executable, "--checks", "reek:ClassVariable", "--reek-config", config, path, in: "/dev/null", out: "/tmp/fleek-config-out", err: "/tmp/fleek-config-err")
    end
  end

  def self.spawn_reek_file(input)
    executable = ENV["BUNDLE"] || "bundle"
    path = input.path
    config = input.config
    if config.empty?
      Process.spawn(executable, "exec", "reek", "--smell", "ClassVariable", path, in: "/dev/null", out: "/tmp/reek-config-out", err: "/tmp/reek-config-err")
    else
      Process.spawn(executable, "exec", "reek", "--smell", "ClassVariable", "--config", config, path, in: "/dev/null", out: "/tmp/reek-config-out", err: "/tmp/reek-config-err")
    end
  end

  def self.run_reek_stdin(input)
    process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "reek", "--smell", "ClassVariable", "--config", input.config, "--stdin-filename", input.path, in: input.stdin, out: "/tmp/reek-config-out", err: "/tmp/reek-config-err")
    AnalysisRunner.observe(process_id, "/tmp/reek-config-out", "/tmp/reek-config-err")
  end

  def self.assert_reference(input)
    actual, reference = run_reference_pair(input)
    AnalysisRunner.assert_same_report(actual, reference, input.label)
  end

  def self.run_reference_pair(input)
    path, config, label, stdin = input.to_a
    [invoke(Input.new(path, config, label, stdin, "fleek")), invoke(Input.new(path, config, label, stdin, "reek"))]
  end

  def self.assert_rejected(result, diagnostic, label)
    raise "#{label} was not rejected before analysis" unless result[0] == 1 && result[1].empty? && result[2].include?(diagnostic)
  end

  def self.compare_discovery_and_explicit(path, explicit_config)
    File.write(".reek.yml", File.read("test/fixtures/config_disabled.yml"))
    [invoke(Input.new(path, "", "discovered", "", "fleek")), invoke(Input.new(path, "", "discovered", "", "reek")), invoke(Input.new(path, explicit_config, "explicit", "", "fleek")), invoke(Input.new(path, explicit_config, "explicit", "", "reek"))]
  ensure
    File.delete(".reek.yml") if File.file?(".reek.yml")
  end
end

source = File.expand_path("test/fixtures/class_variable.rb")
discovered, discovered_reference, explicit, explicit_reference = ConfigurationProcess.compare_discovery_and_explicit(source, "test/fixtures/config_enabled.yml")
raise "discovered disabled check implied success" unless discovered[0] == 1 && discovered[2].include?("disabled")
raise "reference discovery behavior changed" unless discovered_reference[0] == 0
AnalysisRunner.assert_same_report(explicit, explicit_reference, "explicit config precedence")

disabled = ConfigurationProcess.invoke(ConfigurationProcess::Input.new(source, "test/fixtures/config_disabled.yml", "disabled", "", "fleek"))
disabled_reference = ConfigurationProcess.invoke(ConfigurationProcess::Input.new(source, "test/fixtures/config_disabled.yml", "disabled", "", "reek"))
ConfigurationProcess.assert_rejected(disabled, "ClassVariable", "disabled selected check")
raise "Reek disabled check behavior changed" unless disabled_reference[0] == 0 && AnalysisRunner.warning_lines(disabled_reference[1]).empty?

unsupported = ConfigurationProcess.invoke(ConfigurationProcess::Input.new(source, "test/fixtures/config_unsupported.yml", "unsupported", "", "fleek"))
ConfigurationProcess.assert_rejected(unsupported, "LongParameterList", "unsupported enabled detector")
malformed = ConfigurationProcess.invoke(ConfigurationProcess::Input.new(source, "test/fixtures/config_malformed.yml", "malformed", "", "fleek"))
ConfigurationProcess.assert_rejected(malformed, "unsupported Reek YAML key", "malformed YAML")
bad_mapping = ConfigurationProcess.invoke(ConfigurationProcess::Input.new(source, "test/fixtures/config_bad_mapping.yml", "bad mapping", "", "fleek"))
ConfigurationProcess.assert_rejected(bad_mapping, "malformed YAML mapping", "malformed YAML mapping")
bad_list_mapping = ConfigurationProcess.invoke(ConfigurationProcess::Input.new(source, "test/fixtures/config_bad_list_mapping.yml", "bad list mapping", "", "fleek"))
ConfigurationProcess.assert_rejected(bad_list_mapping, "unsupported YAML scalar", "malformed YAML list mapping")
missing = ConfigurationProcess.invoke(ConfigurationProcess::Input.new(source, "test/fixtures/missing-config.yml", "missing", "", "fleek"))
ConfigurationProcess.assert_rejected(missing, "file cannot be read", "missing config")

ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(source, "test/fixtures/config_enabled.yml", "enabled configuration", ""))

excluded = ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(source, "test/fixtures/config_exclude.yml", "context exclusion", ""))
raise "context exclusion did not remove finding" unless excluded[0] == 0

scoped_source = "test/fixtures/config_scope/visible.rb"
directory_config = "test/fixtures/config_directory_override.yml"
scoped = ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(scoped_source, directory_config, "directory config override", ""))
raise "directory override did not re-enable selected check" unless scoped[0] == 2
scoped_disabled = ConfigurationProcess.invoke(ConfigurationProcess::Input.new(scoped_source, "test/fixtures/config_directory_disabled.yml", "scoped disabled", "", "fleek"))
ConfigurationProcess.assert_rejected(scoped_disabled, "disabled", "directory-disabled selected check")
ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(scoped_source, "test/fixtures/config_directory_glob.yml", "directory glob override", ""))
ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(scoped_source, "test/fixtures/config_directory_exclusions.yml", "directory exclusion override", ""))

ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new("test/fixtures/config_scope", "test/fixtures/config_path_exclusion.yml", "directory path exclusion", ""))
explicit_excluded = ConfigurationProcess.invoke(ConfigurationProcess::Input.new(scoped_source, "test/fixtures/config_path_exclusion.yml", "explicit excluded", "", "fleek"))
explicit_excluded_reference = ConfigurationProcess.invoke(ConfigurationProcess::Input.new(scoped_source, "test/fixtures/config_path_exclusion.yml", "explicit excluded", "", "reek"))
raise "explicit Reek exclusion reference changed" unless explicit_excluded_reference[0] == 0
raise "explicit exclusion implied successful analysis" unless explicit_excluded[0] == 1 && explicit_excluded[1].include?("Coverage: 1 selected; 0 analyzed; 0 failed; 1 excluded") && explicit_excluded[1].include?("Status: incomplete") && explicit_excluded[2].include?("no analysis ran")

suppressed_source = File.expand_path("test/fixtures/class_variable_suppressed.rb")
suppressed = ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(suppressed_source, "", "suppression", ""))
raise "suppression did not remove finding" unless suppressed[0] == 0
false_suppression_source = File.expand_path("test/fixtures/class_variable_suppression_false.rb")
ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(false_suppression_source, "", "disabled suppression option", ""))
enabled_suppression_source = File.expand_path("test/fixtures/class_variable_suppression_enabled.rb")
ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(enabled_suppression_source, "", "enabled suppression directive", ""))
inline_suppression_source = File.expand_path("test/fixtures/class_variable_suppression_inline.rb")
inline_suppression = ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(inline_suppression_source, "", "inline class suppression", ""))
raise "inline class comment changed Reek behavior" unless inline_suppression[0] == 2
bad_suppression = ConfigurationProcess.invoke(ConfigurationProcess::Input.new(File.expand_path("test/fixtures/class_variable_suppression_bad.rb"), "", "bad suppression", "", "fleek"))
raise "unsupported suppression setting was accepted" unless bad_suppression[0] == 1 && AnalysisRunner.warning_lines(bad_suppression[1]).empty? && bad_suppression[2].include?("unsupported Reek ClassVariable suppression")

ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(scoped_source, directory_config, "named stdin configuration scope", scoped_source))
excluded_stdin = ConfigurationProcess.invoke(ConfigurationProcess::Input.new(scoped_source, "test/fixtures/config_path_exclusion.yml", "excluded stdin", scoped_source, "fleek"))
raise "excluded stdin status differed" unless excluded_stdin[0] == 1
raise "excluded stdin source scope differed: #{excluded_stdin[1]}" unless excluded_stdin[1].include?("Source: \"#{scoped_source}\" scope=excluded")
raise "excluded stdin check was reported as run" unless excluded_stdin[1].include?("Checks run: none")
raise "excluded stdin coverage differed" unless excluded_stdin[1].include?("Coverage: 1 selected; 0 analyzed; 0 failed; 1 excluded")
raise "excluded stdin status label differed" unless excluded_stdin[1].include?("Status: incomplete")
raise "excluded stdin omitted no-analysis diagnostic" unless excluded_stdin[2].include?("no analysis ran")

puts "Configuration contract: pass"
