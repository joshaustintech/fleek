# frozen_string_literal: true

require_relative "analysis_runner"

# Protects explicit Flay fuzzy-distance parsing through the public CLI.
# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:TooManyStatements
class DuplicationFuzzyDistanceContract
  PATH = "test/fixtures/duplication_fuzzy_distance_two.rb"
  DEFAULT_PATH = "test/fixtures/duplication_fuzzy_methods.rb"

  def self.run
    reference_one = invoke("flay", ["--fuzzy=1"])
    reference_two = invoke("flay", ["--fuzzy=2"])
    actual_one = invoke("fleek", ["--fuzzy=1"])
    actual_two = invoke("fleek", ["--fuzzy=2"])
    actual_separate = invoke("fleek", ["--fuzzy", "2"])
    reference_repeated_two = invoke("flay", ["--fuzzy=1", "--fuzzy=2"])
    actual_repeated_two = invoke("fleek", ["--fuzzy=1", "--fuzzy=2"])
    reference_repeated_one = invoke("flay", ["--fuzzy=2", "--fuzzy=1"])
    actual_repeated_one = invoke("fleek", ["--fuzzy=2", "--fuzzy=1"])
    verify_clean(reference_one, "Flay distance one")
    verify_group(reference_two, true, "Flay distance two")
    verify_clean(actual_one, "Fleek distance one")
    verify_group(actual_two, false, "Fleek distance two")
    verify_group(actual_separate, false, "Fleek separate distance value")
    verify_group(reference_repeated_two, true, "Flay last fuzzy value two")
    verify_group(actual_repeated_two, false, "Fleek last fuzzy value two")
    verify_clean(reference_repeated_one, "Flay last fuzzy value one")
    verify_clean(actual_repeated_one, "Fleek last fuzzy value one")
    verify_clean(invoke("flay", ["--fuzzy=0"]), "Flay zero distance")
    verify_clean(invoke("fleek", ["--fuzzy=0"]), "Fleek zero distance")
    verify_clean(invoke("flay", ["--fuzzy=-1"]), "Flay negative distance")
    verify_clean(invoke("fleek", ["--fuzzy=-1"]), "Fleek negative distance")
    verify_default_distance
    verify_invalid_distance
    verify_bare_noninteger_value
    verify_reek_only_distance
    verify_class_negative_distance
    puts "Flay fuzzy distance contract: pass"
  end

  def self.invoke(tool, options, path = PATH)
    root = ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")
    stem = "fuzzy-distance-#{tool}-#{options.join("-").gsub(/[^a-zA-Z0-9-]/, "_")}"
    output = "#{root}/#{stem}.out"
    error = "#{root}/#{stem}.err"
    option_key = options.join(" ")
    process_id = if tool == "fleek"
      spawn_fleek(option_key, path, output, error)
    else
      spawn_flay(option_key, path, output, error)
    end
    AnalysisRunner.observe(process_id, output, error)
  end

  # :reek:LongParameterList
  def self.spawn_fleek(option_key, path, output, error)
    case option_key
    when "--fuzzy=1" then Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", path, "--fuzzy=1", out: output, err: error)
    when "--fuzzy=2" then Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", path, "--fuzzy=2", out: output, err: error)
    when "--fuzzy 2" then Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--fuzzy", "2", path, out: output, err: error)
    when "--fuzzy=1 --fuzzy=2" then Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--fuzzy=1", "--fuzzy=2", path, out: output, err: error)
    when "--fuzzy=2 --fuzzy=1" then Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--fuzzy=2", "--fuzzy=1", path, out: output, err: error)
    when "--fuzzy=0" then Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", path, "--fuzzy=0", out: output, err: error)
    when "--fuzzy=-1" then Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", path, "--fuzzy=-1", out: output, err: error)
    when "--fuzzy=bad" then Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", path, "--fuzzy=bad", out: output, err: error)
    else raise "unmapped Fleek option sequence: #{option_key}"
    end
  end

  # :reek:LongParameterList
  def self.spawn_flay(option_key, path, output, error)
    executable = ENV["BUNDLE"] || "bundle"
    case option_key
    when "--fuzzy=1" then Process.spawn(executable, "exec", "flay", "--fuzzy=1", path, out: output, err: error)
    when "--fuzzy=2" then Process.spawn(executable, "exec", "flay", "--fuzzy=2", path, out: output, err: error)
    when "--fuzzy=1 --fuzzy=2" then Process.spawn(executable, "exec", "flay", "--fuzzy=1", "--fuzzy=2", path, out: output, err: error)
    when "--fuzzy=2 --fuzzy=1" then Process.spawn(executable, "exec", "flay", "--fuzzy=2", "--fuzzy=1", path, out: output, err: error)
    when "--fuzzy=0" then Process.spawn(executable, "exec", "flay", "--fuzzy=0", path, out: output, err: error)
    when "--fuzzy=-1" then Process.spawn(executable, "exec", "flay", "--fuzzy=-1", path, out: output, err: error)
    else raise "unmapped Flay option sequence: #{option_key}"
    end
  end

  def self.verify_group(result, reference, label)
    expected = reference ? ["Total score (lower is better) = 40", "#{PATH}:1 (FUZZY)", "#{PATH}:11"] :
      ["locations=\"#{PATH}:1,#{PATH}:11\" fuzzy_locations=\"#{PATH}:1\" mass=40 score=40", "Total duplication score: 40"]
    raise "#{label} outcome changed" unless result[0] == (reference ? 0 : 2) && result[2].empty?
    expected.each { |field| raise "#{label} report changed: missing #{field}" unless result[1].include?(field) }
  end

  def self.verify_clean(result, label)
    score = label.start_with?("Flay") ? "Total score (lower is better) = 0" : "Total duplication score: 0"
    raise "#{label} outcome changed" unless result[0] == 0 && result[2].empty?
    raise "#{label} result changed" unless result[1].include?(score)
    raise "#{label} reported fuzzy locations" if result[1].include?("fuzzy_locations=") || result[1].include?("(FUZZY)")
  end

  def self.verify_default_distance
    output = output_path("fuzzy-distance-default.out")
    error = output_path("fuzzy-distance-default.err")
    process_id = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", DEFAULT_PATH, "--fuzzy",
      out: output, err: error)
    observed = AnalysisRunner.observe(process_id, output, error)
    raise "bare --fuzzy no longer defaults to distance one" unless observed[0] == 2 && observed[1].include?("mass=32 score=32")
    reference_output = output_path("fuzzy-distance-default-flay.out")
    reference_error = output_path("fuzzy-distance-default-flay.err")
    executable = ENV["BUNDLE"] || "bundle"
    reference_id = Process.spawn(executable, "exec", "flay", DEFAULT_PATH, "--fuzzy", out: reference_output, err: reference_error)
    reference = AnalysisRunner.observe(reference_id, reference_output, reference_error)
    raise "Flay bare --fuzzy reference changed" unless reference[0] == 0 && reference[2].empty? && reference[1].include?("mass = 32")
  end

  def self.verify_invalid_distance
    result = invoke("fleek", ["--fuzzy=bad"])
    raise "invalid fuzzy distance was analyzed" unless result[0] == 1 && result[1].empty?
    raise "invalid fuzzy distance diagnostic changed" unless result[2].include?("--fuzzy requires an integer")
  end

  def self.verify_bare_noninteger_value
    root = ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")
    output = "#{root}/fuzzy-distance-bare-value.out"
    error = "#{root}/fuzzy-distance-bare-value.err"
    process_id = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--fuzzy", PATH, out: output, err: error)
    result = AnalysisRunner.observe(process_id, output, error)
    raise "bare --fuzzy consumed a non-integer source as distance" unless result[0] == 1 && result[1].empty? && result[2].include?("--fuzzy requires an integer distance")
    executable = ENV["BUNDLE"] || "bundle"
    reference_id = Process.spawn(executable, "exec", "flay", "--fuzzy", PATH, out: output, err: error)
    reference = AnalysisRunner.observe(reference_id, output, error)
    raise "Flay bare fuzzy value validation changed" unless reference[0] == 1 && reference[1].empty? && reference[2].include?("invalid argument")
  end

  def self.verify_reek_only_distance
    root = ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")
    output = "#{root}/fuzzy-distance-reek.out"
    error = "#{root}/fuzzy-distance-reek.err"
    process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", PATH, "--fuzzy=2", out: output, err: error)
    result = AnalysisRunner.observe(process_id, output, error)
    raise "Reek-only fuzzy distance was not rejected" unless result[0] == 1 && result[1].empty? && result[2].include?("applies only to flay:StructuralDuplication")
  end

  def self.verify_class_negative_distance
    path = "test/fixtures/duplication_fuzzy_class_methods.rb"
    verify_clean(invoke("flay", ["--fuzzy=-1"], path), "Flay class negative distance")
    verify_clean(invoke("fleek", ["--fuzzy=-1"], path), "Fleek class negative distance")
  end

  def self.output_path(name)
    "#{ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")}/#{name}"
  end
end

DuplicationFuzzyDistanceContract.run
