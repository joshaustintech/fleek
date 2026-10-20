# frozen_string_literal: true

require_relative "analysis_runner"

# Checks Flay last-value controls and optional fuzzy argument routing.
# :reek:DuplicateMethodCall
# :reek:TooManyConstants
# :reek:TooManyStatements
class DuplicationControlInteractionsContract
  MASS_PATH = "test/fixtures/duplication_class_methods_class_group_with_conditional_pair.rb"
  FUZZY_PATH = "test/fixtures/duplication_class_direct_and_sibling_methods.rb"
  COMBINED_FUZZY_PATH = "test/fixtures/duplication_fuzzy_class_methods.rb"
  LEGACY_PATH = "test/fixtures/duplication_class_cross_scope_group.rb"
  LEGACY_COMBINED_PATH = "test/fixtures/duplication_class_methods_identical.rb"
  BUNDLE = ENV["BUNDLE"] || "bundle"

  def self.run
    verify_repeated_mass
    verify_fuzzy_liberal_source_routing
    verify_legacy_only_interaction
    verify_combined_legacy_only_interaction
    puts "Flay control interactions contract: pass"
  end

  def self.verify_repeated_mass
    reference = invoke("flay", ["--mass", "100", "--mass", "16"], MASS_PATH)
    actual = invoke("fleek", ["--mass", "100", "--mass", "16"], MASS_PATH)
    AnalysisRunner.assert_report_contains(reference, [0, ["Total score (lower is better) = 112"], "Flay repeated --mass reference changed"])
    AnalysisRunner.assert_report_contains(actual, [2, ["Total duplication score: 112", "mass=62", "mass=50"], "repeated --mass did not use last value"])
    assert_clean_stderr(reference, "Flay repeated --mass")
    assert_clean_stderr(actual, "Fleek repeated --mass")

    reverse = invoke("fleek", ["--mass", "16", "--mass", "100"], MASS_PATH)
    AnalysisRunner.assert_report_contains(reverse, [0, ["Total duplication score: 0", "Status: complete"], "repeated --mass retained earlier threshold"])
    assert_clean_stderr(reverse, "Fleek reversed --mass")
  end

  def self.verify_fuzzy_liberal_source_routing
    reference = invoke("flay", ["--fuzzy", "--liberal", "--mass", "3"], FUZZY_PATH)
    actual = invoke("fleek", ["--fuzzy", "--liberal", "--mass", "3"], FUZZY_PATH)
    AnalysisRunner.assert_report_contains(reference, [0, ["Total score (lower is better) = 266", "mass*3 = 216"], "Flay fuzzy liberal reference changed"])
    AnalysisRunner.assert_report_contains(actual, [2, ["Total duplication score: 266", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"], "fuzzy liberal routing lost source path"])
    assert_clean_stderr(reference, "Flay fuzzy liberal")
    assert_clean_stderr(actual, "Fleek fuzzy liberal")

    root = ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")
    output = "#{root}/flay-controls-combined.out"
    error = "#{root}/flay-controls-combined.err"
    process_id = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication,reek:ClassVariable", "--fuzzy", "--liberal", "--mass", "3", COMBINED_FUZZY_PATH, out: output, err: error)
    combined = AnalysisRunner.observe(process_id, output, error)
    AnalysisRunner.assert_report_contains(combined, [2, ["Total duplication score: 32", "Duplication coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Smell coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Overall status: findings"], "combined fuzzy liberal routing lost source path"])
    assert_clean_stderr(combined, "combined fuzzy liberal")
  end

  def self.verify_legacy_only_interaction
    reference = invoke("flay", ["--legacy", "--only", "class"], LEGACY_PATH)
    actual = invoke("fleek", ["--legacy", "--only", "class"], LEGACY_PATH)
    AnalysisRunner.assert_report_contains(reference, [0, ["Total score (lower is better) = 50", "Similar code found in :class"], "Flay legacy only reference changed"])
    AnalysisRunner.assert_report_contains(actual, [2, ["node=\"class\" kind=\"similar\"", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"], "legacy plus only routing changed"])
    assert_clean_stderr(reference, "Flay legacy only")
    assert_clean_stderr(actual, "Fleek legacy only")
  end

  def self.verify_combined_legacy_only_interaction
    root = ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")
    output = "#{root}/flay-controls-legacy-combined.out"
    error = "#{root}/flay-controls-legacy-combined.err"
    reference_id = Process.spawn(BUNDLE, "exec", "flay", "--legacy", "--only", "defn", LEGACY_COMBINED_PATH, out: output, err: error)
    reference = AnalysisRunner.observe(reference_id, output, error)
    AnalysisRunner.assert_report_contains(reference, [0, ["Total score (lower is better) = 64", "IDENTICAL code found in :defn"], "Flay combined legacy only reference changed"])

    process_id = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication,reek:ClassVariable", "--legacy", "--only", "defn", LEGACY_COMBINED_PATH, out: output, err: error)
    combined = AnalysisRunner.observe(process_id, output, error)
    AnalysisRunner.assert_report_contains(combined, [2, ["Total duplication score: 64", "Duplication coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Smell coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Overall status: findings"], "combined legacy only routing changed"])
    assert_clean_stderr(reference, "Flay combined legacy only")
    assert_clean_stderr(combined, "combined legacy only")
  end

  def self.assert_clean_stderr(result, label)
    raise "#{label} wrote to stderr: #{result[2]}" unless result[2].empty?
  end

  def self.invoke(tool, options, path)
    root = ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")
    output = "#{root}/flay-controls-#{tool}.out"
    error = "#{root}/flay-controls-#{tool}.err"
    process_id = if tool == "flay" && path == MASS_PATH
      Process.spawn(BUNDLE, "exec", "flay", "--mass", "100", "--mass", "16", path, out: output, err: error)
    elsif tool == "flay" && path == LEGACY_PATH
      Process.spawn(BUNDLE, "exec", "flay", "--legacy", "--only", "class", path, out: output, err: error)
    elsif tool == "fleek" && path == MASS_PATH && options[1] == "100"
      Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", "100", "--mass", "16", path, out: output, err: error)
    elsif tool == "fleek" && path == MASS_PATH
      Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", "16", "--mass", "100", path, out: output, err: error)
    elsif tool == "fleek" && path == LEGACY_PATH
      Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--legacy", "--only", "class", path, out: output, err: error)
    elsif tool == "flay"
      Process.spawn(BUNDLE, "exec", "flay", "--fuzzy", "--liberal", "--mass", "3", path, out: output, err: error)
    else
      Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--fuzzy", "--liberal", "--mass", "3", path, out: output, err: error)
    end
    AnalysisRunner.observe(process_id, output, error)
  end
end

DuplicationControlInteractionsContract.run
