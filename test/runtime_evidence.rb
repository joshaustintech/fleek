# Measures fresh CLI processes only after complete equivalent outputs are proven.
class RuntimeEvidence
  SOURCE = "test/fixtures/duplication_class_methods_or.rb"
  RAILS_REVISION = "92ce7c470bc31952d7dc51cac15e577a948e479e"
  OUT = "/tmp/fleek-runtime-#{Process.pid}-out"
  ERR = "/tmp/fleek-runtime-#{Process.pid}-err"
  VARIANTS = ["flay-reference", "flay-fleek", "reek-rails-reference", "reek-rails-fleek", "combined-reference", "combined-fleek"]
  # Keeps expected CLI status and report fields together at the process seam.
  ResultExpectation = Struct.new(:status, :fields, :message)
  # Retains raw observations with the exact measured input and binary identities.
  Measurement = Struct.new(:samples, :input_identity, :executable_identity, :corpus_identity, :harness_identity)

  # :reek:DuplicateMethodCall
  def self.spawn(arguments)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    process_id = spawn_arguments(arguments)
    _, status = Process.waitpid2(process_id)
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    [status.exitstatus, File.read(OUT), File.read(ERR), elapsed]
  end

  # :reek:DuplicateMethodCall
  # :reek:TooManyStatements
  def self.spawn_arguments(arguments)
    case arguments.length
    when 2 then Process.spawn(arguments[0], arguments[1], out: OUT, err: ERR)
    when 3 then Process.spawn(arguments[0], arguments[1], arguments[2], out: OUT, err: ERR)
    when 4 then Process.spawn(arguments[0], arguments[1], arguments[2], arguments[3], out: OUT, err: ERR)
    when 5 then Process.spawn(arguments[0], arguments[1], arguments[2], arguments[3], arguments[4], out: OUT, err: ERR)
    when 6 then Process.spawn(arguments[0], arguments[1], arguments[2], arguments[3], arguments[4], arguments[5], out: OUT, err: ERR)
    when 7 then Process.spawn(arguments[0], arguments[1], arguments[2], arguments[3], arguments[4], arguments[5], arguments[6], out: OUT, err: ERR)
    else raise "unsupported measured command arity: #{arguments.length} #{arguments.join(' ')}"
    end
  end

  def self.flay_reference
    spawn(["bundle", "exec", "flay", "--mass", "16", SOURCE])
  end

  def self.fleek_flay
    fleek("flay:StructuralDuplication")
  end

  def self.reek_reference
    spawn(["bundle", "exec", "reek", "--smell", "ClassVariable", "--no-progress", rails_app])
  end

  def self.reek_fixture_reference
    spawn(["bundle", "exec", "reek", "--smell", "ClassVariable", "--no-progress", SOURCE])
  end

  def self.fleek(checks, input = SOURCE)
    arguments = ["build/fleek", "--checks", checks]
    arguments.concat(["--mass", "16"]) if checks.include?("flay:")
    arguments << input
    spawn(arguments)
  end

  # :reek:ControlParameter
  def self.assert(value, message)
    raise message unless value
  end

  def self.verify_flay_reference(result)
    fields = ["Total score (lower is better) = 34", "Similar code found in :defn (mass = 34)", "#{SOURCE}:2", "#{SOURCE}:12"]
    verify_result_fields(result, ResultExpectation.new(0, fields, "Flay reference result differs"))
  end

  def self.verify_result_fields(result, expectation)
    assert(result[0] == expectation.status && result[2].empty? && expectation.fields.all? { |field| result[1].include?(field) }, expectation.message)
  end

  def self.verify_reek_reference(result)
    assert(result[0] == 0 && result[1].include?("0 total warnings") && result[2].empty?, "Reek Rails reference result differs")
  end

  def self.verify_reek_fixture_reference(result)
    assert(result[0] == 0 && result[1].empty? && result[2].empty?, "Reek fixture reference result differs")
  end

  def self.verify_fleek_clean(result, check, coverage)
    output = result[1]
    assert(result[0] == 0 && result[2].empty?, "Fleek #{check} process result differs")
    complete = output.include?("Overall status: complete") || output.include?("Status: complete")
    assert(complete && !output.include?("Finding:"), "Fleek #{check} findings or status differ")
    assert(output.include?(coverage), "Fleek #{check} coverage differs")
  end

  # :reek:TooManyStatements
  def self.verify_results
    verify_flay_reference(flay_reference)
    verify_reek_fixture_reference(reek_fixture_reference)
    verify_flay_fleek(fleek_flay)
    combined = fleek("flay:StructuralDuplication,reek:ClassVariable")
    verify_combined_fleek(combined)
  end

  def self.verify_rails_results
    verify_reek_reference(reek_reference)
    verify_fleek_clean(fleek("reek:ClassVariable", rails_app), "Reek ClassVariable on Rails", "25 selected; 25 analyzed; 0 failed; 0 excluded")
  end

  def self.verify_flay_fleek(result)
    fields = ["kind=\"similar\"", "locations=\"#{SOURCE}:2,#{SOURCE}:12\"", "mass=34 score=34", "Total duplication score: 34", "1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
    verify_result_fields(result, ResultExpectation.new(2, fields, "Fleek Flay result differs"))
  end

  def self.verify_combined_fleek(result)
    output = result[1]
    fields = ["locations=\"#{SOURCE}:2,#{SOURCE}:12\"", "mass=34 score=34", "Total duplication score: 34", "Checks run: flay:StructuralDuplication,reek:ClassVariable", "Duplication coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Smell coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Overall status: findings"]
    assert(result[0] == 2 && result[2].empty? && !output.include?("Finding:") && fields.all? { |field| output.include?(field) }, "Fleek combined result differs")
  end

  # :reek:ControlParameter
  # :reek:TooManyStatements
  def self.execute(variant)
    case variant
    when "flay-reference" then flay_reference
    when "flay-fleek" then fleek_flay
    when "reek-rails-reference" then reek_reference
    when "reek-rails-fleek" then fleek("reek:ClassVariable", rails_app)
    when "combined-fleek" then fleek("flay:StructuralDuplication,reek:ClassVariable")
    else combined_reference
    end
  end

  # :reek:DuplicateMethodCall
  # :reek:TooManyStatements
  def self.combined_reference
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    flay = flay_reference
    reek = reek_fixture_reference
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    [flay[0] == 0 && reek[0] == 0 ? 0 : 1, flay[1], flay[2], elapsed, reek]
  end

  # :reek:ControlParameter
  # :reek:DuplicateMethodCall
  # :reek:TooManyStatements
  def self.validate(variant, result)
    case variant
    when "flay-reference" then verify_flay_reference(result)
    when "flay-fleek" then verify_flay_fleek(result)
    when "reek-rails-reference" then verify_reek_reference(result)
    when "reek-rails-fleek" then verify_fleek_clean(result, "Reek ClassVariable on Rails", "25 selected; 25 analyzed; 0 failed; 0 excluded")
    when "combined-fleek"
      verify_combined_fleek(result)
    else
      verify_flay_reference([result[0], result[1], result[2], result[3]])
      verify_reek_fixture_reference(result[4])
    end
  end

  # :reek:DuplicateMethodCall
  def self.ordered_variants(index)
    pairs = [["flay-reference", "flay-fleek"], ["reek-rails-reference", "reek-rails-fleek"], ["combined-reference", "combined-fleek"]]
    pairs = pairs.reverse if index % 2 == 1
    pairs.flat_map { |pair| index % 2 == 1 ? pair.reverse : pair }
  end

  # :reek:NestedIterators
  # :reek:TooManyStatements
  def self.measure(repetitions)
    samples = []
    input_identity = source_hash
    executable_identity = binary_hash
    corpus_identity = rails_identity
    harness_identity = helper_hash
    verify_rails_results
    repetitions.times do |index|
      ordered_variants(index).each do |variant|
        result = execute(variant)
        validate(variant, result)
        samples << [index + 1, samples.length + 1, variant, result[3]]
      end
    end
    assert(source_hash == input_identity, "runtime evidence input changed during measurement")
    assert(binary_hash == executable_identity, "Fleek executable changed during measurement")
    assert(rails_identity == corpus_identity, "Rails corpus changed during measurement")
    assert(helper_hash == harness_identity, "runtime evidence helper changed during measurement")
    Measurement.new(samples, input_identity, executable_identity, corpus_identity, harness_identity)
  end

  def self.percentile(values, fraction)
    ordered = values.sort
    ordered[[(ordered.length * fraction).ceil - 1, 0].max]
  end

  def self.statistics(samples, variant)
    values = samples.select { |sample| sample[2] == variant }.map { |sample| sample[3] }
    [values.length, percentile(values, 0.5), percentile(values, 0.95), values.min, values.max]
  end

  def self.ms(seconds)
    (seconds * 1000).round(3)
  end

  def self.write_report(measurement, repetitions)
    File.write("docs/research/cold-runtime-2026-10-15.md", summary(measurement, repetitions))
  end

  # :reek:TooManyStatements
  def self.summary(measurement, repetitions)
    samples = measurement.samples
    lines = ["# Fleek cold CLI runtime evidence", "", "## Identity", "",
      "- Host: #{command_output(["uname", "-s"])} #{command_output(["uname", "-m"])}; macOS #{command_output(["sw_vers", "-productVersion"])} (#{command_output(["sw_vers", "-buildVersion"]).strip}).",
      "- Source revision: #{command_output(["git", "rev-parse", "HEAD"]).strip}.",
      "- Fleek executable SHA-256 (before and after): #{measurement.executable_identity}.",
      "- Spinel measurement helper SHA-256 (before and after): #{measurement.harness_identity}.",
      "- Compiler: Spinel 2026.09.12; reference analyzers: Flay 2.14.4 and Reek 6.6.0; reference Ruby: #{command_output(["ruby", "-v"])}.",
      "- Flay and combined input: `#{SOURCE}`; SHA-256 (before and after): #{measurement.input_identity}; immutable one-file fixture with one duplicated class-method group.",
      "- Reek input: `$FLEEK_RAILS_CORPUS/app`; pinned commit and clean status (before and after): #{measurement.corpus_identity}; exact 25-file Ruby manifest from the Rails parity receipt.",
      "- Configuration: Flay mass 16; Reek `--smell ClassVariable --no-progress`; matching explicitly selected Fleek checks; no config files or exclusions.",
      "", "## Reproduce", "",
      "Set `SPINEL` to the pinned 2026.09.12 executable, `BUNDLE_PATH` to the locked dependency bundle, and `FLEEK_RAILS_CORPUS` to the clean pinned checkout, then run `make runtime-evidence` (20 repetitions by default).",
      "", "## Method", "",
      "Each observation starts a fresh process and includes process startup, input reading, selected analysis, and process exit. Cold means fresh process only. OS filesystem caches stayed natural and were not evicted. Each reference command includes `bundle exec`. Combined reference work runs Flay then Reek sequentially on the duplicate fixture; Fleek runs both in one process on that same input. The six variants ran #{repetitions} times each, with pair order alternated on every repetition. Every output, stderr stream, and exit status passed the equivalence gate before its timing was retained.",
      "", "## Equivalence", "",
      "Equivalence is semantic; reference and Fleek stdout formats are intentionally different and were not compared byte-for-byte. Flay prints its prose report while Fleek uses its structured `Group` and coverage report. On identical Flay input, Flay 2.14.4 and Fleek both report one similar `:defn` group, mass/score 34, lines 2 and 12, complete 1/1 coverage, and no stderr. Flay exits 0 for findings; Fleek exits 2 by its declared CLI contract. Combined reference Flay plus Reek commands both exit 0; combined Fleek reports the identical Flay group, complete 1/1 coverage for both checks, and exits 2 for findings. On the identical pinned 25-file Rails `app/` input, Reek 6.6.0 reports 0 warnings; Fleek Reek reports 25/25 analyzed, complete, no findings, and exit 0. The Flay exit difference is intentional and documented in ADRs 0002 and 0018.",
      "", "## Summary", "", "Variant | n | median ms | p95 ms | min ms | max ms", "---|---:|---:|---:|---:|---:"]
    VARIANTS.each do |variant|
      stats = statistics(samples, variant)
      lines << "#{variant} | #{stats[0]} | #{ms(stats[1])} | #{ms(stats[2])} | #{ms(stats[3])} | #{ms(stats[4])}"
    end
    lines.concat(target_lines(samples))
    lines.concat(["", "## Raw observations", "", "order | repetition | variant | ms", "---:|---:|---|---:"])
    samples.each { |sample| lines << "#{sample[1]} | #{sample[0]} | #{sample[2]} | #{ms(sample[3])}" }
    lines.join("\n") + "\n"
  end

  # :reek:TooManyStatements
  def self.target_lines(samples)
    pairs = [["Flay fixture", "flay-fleek", "flay-reference"], ["Reek ClassVariable Rails corpus", "reek-rails-fleek", "reek-rails-reference"], ["Combined fixture", "combined-fleek", "combined-reference"]]
    lines = ["", "Target: Fleek p95 must be no slower than the corresponding pinned reference p95 for the same complete work. This ties target to observed upstream CLI cost and keeps combined work comparable.", ""]
    pairs.each do |pair|
      actual = statistics(samples, pair[1])[2]
      target = statistics(samples, pair[2])[2]
      lines << "- #{pair[0]}: target <= #{ms(target)} ms p95; observed #{ms(actual)} ms; #{actual <= target ? "met" : "not met"}."
    end
    lines
  end

  def self.command_output(arguments)
    result = spawn(arguments)
    assert(result[0] == 0 && result[2].empty?, "identity command failed: #{arguments[0]}")
    result[1].strip
  end

  def self.binary_hash
    command_output(["shasum", "-a", "256", "build/fleek"]).split[0]
  end

  def self.helper_hash
    command_output(["shasum", "-a", "256", "test/runtime_evidence.rb"]).split[0]
  end

  def self.source_hash
    command_output(["shasum", "-a", "256", SOURCE]).split[0]
  end

  def self.rails_app
    File.join(ENV["FLEEK_RAILS_CORPUS"], "app")
  end

  # :reek:TooManyStatements
  def self.rails_identity
    root = ENV["FLEEK_RAILS_CORPUS"]
    raise "FLEEK_RAILS_CORPUS must identify the pinned Rails checkout" unless root && !root.empty?
    revision = command_output(["git", "-C", root, "rev-parse", "HEAD"])
    state = command_output(["git", "-C", root, "status", "--porcelain"])
    assert(revision == RAILS_REVISION && state.empty?, "Rails corpus revision or worktree differs")
    "#{revision} (clean)"
  end
end

if ARGV[0] == "--verify-only"
  RuntimeEvidence.verify_results
  RuntimeEvidence.verify_rails_results if ENV["FLEEK_RAILS_CORPUS"]
  puts "Runtime equivalence contract: pass"
elsif ARGV[0] == "--measure"
  repetitions = ARGV[1].to_i
  raise "repetitions must be between 10 and 100" unless repetitions >= 10 && repetitions <= 100
  RuntimeEvidence.verify_results
  RuntimeEvidence.verify_rails_results
  measurement = RuntimeEvidence.measure(repetitions)
  RuntimeEvidence.write_report(measurement, repetitions)
  puts RuntimeEvidence.summary(measurement, repetitions)
else
  raise "usage: runtime_evidence.rb --verify-only | --measure REPETITIONS"
end
