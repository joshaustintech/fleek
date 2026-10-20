# frozen_string_literal: true

require_relative "analysis_runner"

# Protects Flay's default-distance fuzzy method groups through the public CLI.
# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:LongParameterList
# :reek:RepeatedConditional
# :reek:TooManyStatements
# :reek:TooManyConstants
class DuplicationFuzzyContract
  PATH = "test/fixtures/duplication_fuzzy_methods.rb"
  CLASS_PATH = "test/fixtures/duplication_fuzzy_class_methods.rb"
  EXACT_PATH = "test/fixtures/duplication_identical.rb"
  UNRELATED_PATH = "test/fixtures/duplication_unrelated_methods.rb"
  DEFAULT_PATH = "test/fixtures/duplication_fuzzy_methods.rb"
  SIZE_LIMIT_PATH = "test/fixtures/duplication_fuzzy_size_limit.rb"
  MASS_REFERENCE_PATH = "test/fixtures/duplication_fuzzy_mass_reference.rb"
  def self.run
    fuzzy_reference = invoke("flay", true)
    class_reference = invoke("flay", true, CLASS_PATH)
    exact_reference = invoke("flay", false, EXACT_PATH)
    unrelated_reference = invoke("flay", true, UNRELATED_PATH)
    default_reference = invoke("flay", false, DEFAULT_PATH)
    size_limit_reference = invoke("flay", true, SIZE_LIMIT_PATH)
    mass_reference = invoke("flay", true, MASS_REFERENCE_PATH)
    fuzzy_actual = invoke("fleek", true)
    class_actual = invoke("fleek", true, CLASS_PATH)
    exact_actual = invoke("fleek", false, EXACT_PATH)
    unrelated_actual = invoke("fleek", true, UNRELATED_PATH)
    default_actual = invoke("fleek", false, DEFAULT_PATH)
    size_limit_actual = invoke("fleek", true, SIZE_LIMIT_PATH)
    mass_actual = invoke("fleek", true, MASS_REFERENCE_PATH)
    verify_reference(fuzzy_reference, true)
    verify_reference(class_reference, true, CLASS_PATH, 32, 2, 9)
    verify_reference(exact_reference, false, EXACT_PATH, 64, 1, 18)
    verify_reference(unrelated_reference, false, UNRELATED_PATH, 0)
    verify_reference(default_reference, false, DEFAULT_PATH, 0)
    verify_reference(size_limit_reference, false, SIZE_LIMIT_PATH, 0)
    verify_reference(mass_reference, true, MASS_REFERENCE_PATH, 40, 1, 11)
    verify_actual(fuzzy_actual, true)
    verify_actual(class_actual, true, CLASS_PATH, 32, 2, 9)
    verify_actual(exact_actual, false, EXACT_PATH, 64)
    verify_actual(unrelated_actual, false, UNRELATED_PATH, 0)
    verify_actual(default_actual, false, DEFAULT_PATH, 0)
    verify_actual(size_limit_actual, false, SIZE_LIMIT_PATH, 0)
    verify_actual(mass_actual, true, MASS_REFERENCE_PATH, 40, 1, 11)
    verify_inapplicable_fuzzy
    puts "Flay fuzzy contract: pass"
  end

  def self.invoke(tool, fuzzy, path = PATH)
    root = ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")
    suffix = fuzzy ? "fuzzy" : "exact"
    output = "#{root}/duplication-#{suffix}-#{tool}.out"
    error = "#{root}/duplication-#{suffix}-#{tool}.err"
    process_id = if tool == "fleek" && fuzzy
      Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", path, "--fuzzy", out: output, err: error)
    elsif tool == "fleek"
      Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", path, out: output, err: error)
    elsif fuzzy
      Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "flay", path, "--fuzzy", out: output, err: error)
    else
      Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "flay", path, out: output, err: error)
    end
    AnalysisRunner.observe(process_id, output, error)
  end

  def self.verify_reference(result, fuzzy, path = PATH, total = 32, fuzzy_line = 1, other_line = 8)
    expected = ["Total score (lower is better) = #{total}"]
    expected << "#{path}:#{fuzzy_line} (FUZZY)" if fuzzy
    expected << "#{path}:#{other_line}" unless total.zero?
    AnalysisRunner.assert_report_contains(result, [0, expected, "Flay fuzzy reference changed for #{path}: #{expected.join(' ; ')}"])
    raise "Flay fuzzy reference wrote to stderr" unless result[2].empty?
    raise "Flay fuzzy marker count changed" unless result[1].scan("(FUZZY)").length == (fuzzy ? 1 : 0)
  end

  def self.verify_actual(result, fuzzy, path = PATH, total = 32, fuzzy_line = 1, other_line = 8)
    fuzzy_group = "node=\"defn\" kind=\"similar\" locations=\"#{path}:#{fuzzy_line},#{path}:#{other_line}\" fuzzy_locations=\"#{path}:#{fuzzy_line}\" mass=#{total} score=#{total}"
    expected = fuzzy ? [fuzzy_group, "Total duplication score: #{total}"] :
      ["Total duplication score: #{total}"]
    expected << "node=\"defn\" kind=\"identical\" locations=\"#{path}:1,#{path}:18\" mass=32 score=64" if path == EXACT_PATH
    expected.concat(["Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"])
    expected[-1] = "Status: complete" if total.zero?
    expected[-2] = "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded" if total.zero?
    expected[-3] = "Total duplication score: 0" if total.zero?
    raise "Flay fuzzy CLI outcome changed" unless result[0] == (total.zero? ? 0 : 2) && result[2].empty?
    expected.each { |field| raise "Flay fuzzy CLI report changed: missing #{field}" unless result[1].include?(field) }
    raise "unexpected fuzzy report field" if !fuzzy && result[1].include?("fuzzy_locations=")
  end

  def self.verify_inapplicable_fuzzy
    root = ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")
    output = "#{root}/duplication-fuzzy-inapplicable.out"
    error = "#{root}/duplication-fuzzy-inapplicable.err"
    process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", PATH, "--fuzzy", out: output, err: error)
    result = AnalysisRunner.observe(process_id, output, error)
    raise "Reek-only fuzzy status changed" unless result[0] == 1
    raise "Reek-only fuzzy option produced analysis output" unless result[1].empty?
    raise "Reek-only fuzzy diagnostic changed" unless result[2].include?("--fuzzy applies only to flay:StructuralDuplication")
  end
end

DuplicationFuzzyContract.run
