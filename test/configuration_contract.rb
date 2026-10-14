require_relative "analysis_runner"
# Verifies imported Reek settings through compiled CLI processes.
class ConfigurationProcess
  # Describes one reference-comparison invocation.
  Input = Struct.new(:path, :config, :label, :stdin)

  def self.fleek(path, config = "", stdin = "")
    executable = File.expand_path("build/fleek")
    if stdin.empty?
      if config.empty?
        process_id = Process.spawn(executable, "--checks", "reek:ClassVariable", path, in: "/dev/null", out: "/tmp/fleek-config-out", err: "/tmp/fleek-config-err")
      else
        process_id = Process.spawn(executable, "--checks", "reek:ClassVariable", "--reek-config", config, path, in: "/dev/null", out: "/tmp/fleek-config-out", err: "/tmp/fleek-config-err")
      end
    else
      process_id = Process.spawn(executable, "--checks", "reek:ClassVariable", "--stdin", path, in: stdin, out: "/tmp/fleek-config-out", err: "/tmp/fleek-config-err")
    end
    AnalysisRunner.observe(process_id, "/tmp/fleek-config-out", "/tmp/fleek-config-err")
  end

  def self.reek(path, config = "", stdin = "")
    if stdin.empty?
      if config.empty?
        process_id = Process.spawn("bundle", "exec", "reek", "--smell", "ClassVariable", path, in: "/dev/null", out: "/tmp/reek-config-out", err: "/tmp/reek-config-err")
      else
        process_id = Process.spawn("bundle", "exec", "reek", "--smell", "ClassVariable", "--config", config, path, in: "/dev/null", out: "/tmp/reek-config-out", err: "/tmp/reek-config-err")
      end
    else
      process_id = Process.spawn("bundle", "exec", "reek", "--smell", "ClassVariable", "--stdin-filename", path, in: stdin, out: "/tmp/reek-config-out", err: "/tmp/reek-config-err")
    end
    AnalysisRunner.observe(process_id, "/tmp/reek-config-out", "/tmp/reek-config-err")
  end

  def self.assert_reference(input)
    path, config, label, stdin = input.to_a
    actual = fleek(path, config, stdin)
    reference = reek(path, config, stdin)
    AnalysisRunner.assert_same_report(actual, reference, label)
  end

  def self.assert_rejected(result, diagnostic, label)
    raise "#{label} was not rejected before analysis" unless result[0] == 1 && result[1].empty? && result[2].include?(diagnostic)
  end

  def self.compare_discovery_and_explicit(path, explicit_config)
    File.write(".reek.yml", File.read("test/fixtures/config_disabled.yml"))
    [fleek(path), reek(path), fleek(path, explicit_config), reek(path, explicit_config)]
  ensure
    File.delete(".reek.yml") if File.file?(".reek.yml")
  end
end

source = File.expand_path("test/fixtures/class_variable.rb")
discovered, discovered_reference, explicit, explicit_reference = ConfigurationProcess.compare_discovery_and_explicit(source, "test/fixtures/config_enabled.yml")
raise "discovered disabled check implied success" unless discovered[0] == 1 && discovered[2].include?("disabled")
raise "reference discovery behavior changed" unless discovered_reference[0] == 0
AnalysisRunner.assert_same_report(explicit, explicit_reference, "explicit config precedence")

disabled = ConfigurationProcess.fleek(source, "test/fixtures/config_disabled.yml")
disabled_reference = ConfigurationProcess.reek(source, "test/fixtures/config_disabled.yml")
ConfigurationProcess.assert_rejected(disabled, "ClassVariable", "disabled selected check")
raise "Reek disabled check behavior changed" unless disabled_reference[0] == 0 && AnalysisRunner.warning_lines(disabled_reference[1]).empty?

unsupported = ConfigurationProcess.fleek(source, "test/fixtures/config_unsupported.yml")
ConfigurationProcess.assert_rejected(unsupported, "LongParameterList", "unsupported enabled detector")
malformed = ConfigurationProcess.fleek(source, "test/fixtures/config_malformed.yml")
ConfigurationProcess.assert_rejected(malformed, "unsupported Reek YAML key", "malformed YAML")
bad_mapping = ConfigurationProcess.fleek(source, "test/fixtures/config_bad_mapping.yml")
ConfigurationProcess.assert_rejected(bad_mapping, "malformed YAML mapping", "malformed YAML mapping")
bad_list_mapping = ConfigurationProcess.fleek(source, "test/fixtures/config_bad_list_mapping.yml")
ConfigurationProcess.assert_rejected(bad_list_mapping, "unsupported YAML scalar", "malformed YAML list mapping")
missing = ConfigurationProcess.fleek(source, "test/fixtures/missing-config.yml")
ConfigurationProcess.assert_rejected(missing, "file cannot be read", "missing config")

ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(source, "test/fixtures/config_enabled.yml", "enabled configuration", ""))

excluded = ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(source, "test/fixtures/config_exclude.yml", "context exclusion", ""))
raise "context exclusion did not remove finding" unless excluded[0] == 0

scoped_source = "test/fixtures/config_scope/visible.rb"
directory_config = "test/fixtures/config_directory_override.yml"
scoped = ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(scoped_source, directory_config, "directory config override", ""))
raise "directory override did not re-enable selected check" unless scoped[0] == 2
scoped_disabled = ConfigurationProcess.fleek(scoped_source, "test/fixtures/config_directory_disabled.yml")
ConfigurationProcess.assert_rejected(scoped_disabled, "disabled", "directory-disabled selected check")
ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(scoped_source, "test/fixtures/config_directory_glob.yml", "directory glob override", ""))
ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(scoped_source, "test/fixtures/config_directory_exclusions.yml", "directory exclusion override", ""))

ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new("test/fixtures/config_scope", "test/fixtures/config_path_exclusion.yml", "directory path exclusion", ""))
explicit_excluded = ConfigurationProcess.fleek(scoped_source, "test/fixtures/config_path_exclusion.yml")
explicit_excluded_reference = ConfigurationProcess.reek(scoped_source, "test/fixtures/config_path_exclusion.yml")
raise "explicit Reek exclusion reference changed" unless explicit_excluded_reference[0] == 0
raise "explicit exclusion implied successful analysis" unless explicit_excluded[0] == 1 && explicit_excluded[1].include?("Coverage: 0 analyzed; 0 failed; 1 excluded") && explicit_excluded[1].include?("Status: incomplete") && explicit_excluded[2].include?("no analysis ran")

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
bad_suppression = ConfigurationProcess.fleek(File.expand_path("test/fixtures/class_variable_suppression_bad.rb"))
raise "unsupported suppression setting was accepted" unless bad_suppression[0] == 1 && AnalysisRunner.warning_lines(bad_suppression[1]).empty? && bad_suppression[2].include?("unsupported Reek ClassVariable suppression")

ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(scoped_source, directory_config, "named stdin configuration scope", scoped_source))
excluded_stdin = ConfigurationProcess.assert_reference(ConfigurationProcess::Input.new(scoped_source, "test/fixtures/config_path_exclusion.yml", "named stdin path exclusion policy", scoped_source))
raise "stdin filename was incorrectly path-excluded" unless excluded_stdin[0] == 2

puts "Configuration contract: pass"
