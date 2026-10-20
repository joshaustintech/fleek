# frozen_string_literal: true

require_relative "analysis_runner"

# Protects native legacy-parser semantics through the public CLI.
# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:LongParameterList
# :reek:TooManyStatements
class LegacyParserContract
  SHARED_PATH = "test/fixtures/duplication_methods_array_expression.rb"
  LEGACY_REJECTION_PATHS = [
    "test/fixtures/ruby4_duplicate.rb",
    "test/fixtures/ruby4_or_duplicate.rb",
    "test/fixtures/ruby4_and_keyword_duplicate.rb",
    "test/fixtures/ruby4_or_keyword_duplicate.rb"
  ].freeze

  def self.run
    verify_shared_case
    LEGACY_REJECTION_PATHS.each { |path| verify_legacy_rejection_case(path) }
    verify_reek_only_rejection
    puts "Flay legacy parser contract: pass"
  end

  def self.verify_shared_case
    default_reference = invoke("flay", SHARED_PATH, false)
    legacy_reference = invoke("flay", SHARED_PATH, true)
    default_fleek = invoke("fleek", SHARED_PATH, false)
    legacy_fleek = invoke("fleek", SHARED_PATH, true)
    expected_reference = ["IDENTICAL code found in :defn (mass*2 = 76)", "#{SHARED_PATH}:1", "#{SHARED_PATH}:5"]
    expected_fleek = ["kind=\"identical\"", "locations=\"#{SHARED_PATH}:1,#{SHARED_PATH}:5\"", "mass=38 score=76",
      "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
    verify_result(default_reference, 0, expected_reference, [], "Flay default shared syntax")
    verify_result(legacy_reference, 0, expected_reference, [], "Flay legacy shared syntax")
    verify_result(default_fleek, 2, expected_fleek, [], "Fleek default shared syntax")
    verify_result(legacy_fleek, 2, expected_fleek, [], "Fleek legacy shared syntax")
  end

  def self.verify_legacy_rejection_case(path)
    default_reference = invoke("flay", path, false)
    legacy_reference = invoke("flay", path, true)
    default_fleek = invoke("fleek", path, false)
    legacy_fleek = invoke("fleek", path, true)
    expected_default = ["mass = 36", "#{path}:1", "#{path}:19"]
    expected_legacy = ["Total score (lower is better) = 0"]
    expected_fleek_default = ["mass=36 score=36", "locations=\"#{path}:1,#{path}:19\"",
      "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
    expected_fleek_legacy = ["Source: \"#{path}\" scope=included", "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"]
    verify_result(default_reference, 0, expected_default, [], "Flay default parser case #{path}")
    verify_result(legacy_reference, 0, expected_legacy, ["#{path}:16", "parse error"], "Flay legacy parser rejection #{path}")
    verify_result(default_fleek, 2, expected_fleek_default, [], "Fleek default parser case #{path}")
    verify_result(legacy_fleek, 1, expected_fleek_legacy,
      [path, "line-leading boolean operator"], "Fleek legacy parser failure #{path}")
    raise "Fleek legacy parser emitted findings: #{path}" if legacy_fleek[1].include?("mass=36")
  end

  def self.verify_reek_only_rejection
    result = invoke("fleek", SHARED_PATH, true, "reek:ClassVariable")
    verify_result(result, 1, [], ["--legacy applies only to flay:StructuralDuplication"], "Reek-only legacy option")
  end

  def self.invoke(tool, path, legacy, check = "flay:StructuralDuplication")
    root = ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")
    output = "#{root}/legacy-parser-#{tool}-#{legacy}.out"
    error = "#{root}/legacy-parser-#{tool}-#{legacy}.err"
    process_id = if tool == "fleek"
      spawn_fleek(path, legacy, output, error, check)
    else
      spawn_flay(path, legacy, output, error)
    end
    AnalysisRunner.observe(process_id, output, error)
  end

  # :reek:LongParameterList
  def self.spawn_fleek(path, legacy, output, error, check)
    if legacy
      Process.spawn("build/fleek", "--checks", check, path, "--legacy", out: output, err: error)
    else
      Process.spawn("build/fleek", "--checks", check, path, out: output, err: error)
    end
  end

  # :reek:LongParameterList
  def self.spawn_flay(path, legacy, output, error)
    executable = ENV["BUNDLE"] || "bundle"
    if legacy
      Process.spawn(executable, "exec", "flay", "--legacy", path, out: output, err: error)
    else
      Process.spawn(executable, "exec", "flay", path, out: output, err: error)
    end
  end

  def self.verify_result(result, status, stdout_fields, stderr_fields, label)
    expected = [[result[0] == status, "status #{result[0]}"], [stdout_fields.all? { |field| result[1].include?(field) }, "stdout"],
      [stderr_fields.all? { |field| result[2].include?(field) }, "stderr"]]
    failures = expected.reject(&:first).map(&:last)
    raise "#{label} changed: #{failures.join(", ")}" unless failures.empty?
  end
end

LegacyParserContract.run
