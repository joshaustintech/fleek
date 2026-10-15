# Verifies combined selection against pinned analyzers and status precedence.
require_relative "analysis_runner"
# Runs combined CLI and pinned reference contracts.
class CombinedProcess
  IGNORE_PATH = ".flayignore"
  CONFIG_PATH = "/tmp/fleek-combined-config-#{Process.pid}.yml"
  # Carries one combined CLI invocation.
  Input = Struct.new(:checks, :first, :second, :third)
  # Carries one pinned reference invocation.
  Reference = Struct.new(:config, :first, :second, :third)

  def self.run(input)
    checks, first, second, third = input.to_a
    process_id = Process.spawn("build/fleek", "--checks", checks, first, second, third, out: "/tmp/fleek-combined-out", err: "/tmp/fleek-combined-err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-combined-out", "/tmp/fleek-combined-err")
  end

  # :reek:TooManyStatements
  def self.run_with_opposing_exclusions(input)
    _checks, first, second, third = input.to_a
    File.write(IGNORE_PATH, "#{third}\n")
    File.write(CONFIG_PATH, "exclude_paths:\n  - test/fixtures/duplication_file_*.rb\n")
    process_id = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication,reek:ClassVariable", "--mass", "16", "--reek-config", CONFIG_PATH, first, second, third, out: "/tmp/fleek-combined-out", err: "/tmp/fleek-combined-err")
    output = AnalysisRunner.observe(process_id, "/tmp/fleek-combined-out", "/tmp/fleek-combined-err")
    [output, run_flay_reference(input), run_reek_reference(Reference.new(CONFIG_PATH, first, second, third))]
  ensure
    File.delete(IGNORE_PATH) if File.exist?(IGNORE_PATH)
    File.delete(CONFIG_PATH) if File.exist?(CONFIG_PATH)
  end

  def self.run_clean
    first = "test/fixtures/duplication_different_shapes.rb"
    second = "test/fixtures/empty.rb"
    third = "test/fixtures/empty.rb"
    process_id = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication,reek:ClassVariable", "--mass", "16", first, second, third, out: "/tmp/fleek-combined-out", err: "/tmp/fleek-combined-err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-combined-out", "/tmp/fleek-combined-err")
  end

  def self.run_flay_reference(input)
    _checks, first, second, _third = input.to_a
    output_path = "/tmp/fleek-combined-flay-out"
    error_path = "/tmp/fleek-combined-flay-err"
    process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "flay", "--mass", "16", first, second, out: output_path, err: error_path)
    AnalysisRunner.observe(process_id, output_path, error_path)
  end

  def self.run_reek_reference(input)
    config, first, second, third = input.to_a
    process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "reek", "--smell", "ClassVariable", "--config", config, first, second, third, out: "/tmp/fleek-combined-reek-out", err: "/tmp/fleek-combined-reek-err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-combined-reek-out", "/tmp/fleek-combined-reek-err")
  end

  def self.verify_flay_parity(report, reference, input)
    _checks, first, second, = input.to_a
    locations = "#{first}:1,#{second}:1"
    verify_flay_reference(reference, first, second)
    verify_flay_report(report, locations)
  end

  def self.verify_flay_reference(reference, first, second)
    status, reference_text = reference.to_a
    verify(status == 0 && reference_text.include?("Total score (lower is better) = 64"), "pinned Flay reference score or status changed")
    verify(reference_text.include?("IDENTICAL code found in :defn (mass*2 = 64)"), "pinned Flay group kind or mass changed")
    verify(reference_text.include?("#{first}:1") && reference_text.include?("#{second}:1"), "pinned Flay locations changed")
  end

  def self.verify_flay_report(report, locations)
    group = "Group: check=\"flay:StructuralDuplication\" node=\"defn\" kind=\"identical\" locations=\"#{locations}\" mass=64 score=64"
    verify(report.include?(group) && report.include?("Total duplication score: 64"), "combined Flay finding, locations, mass, or score differed")
  end

  def self.verify_reek_parity(report, reference)
    verify(reference[0] == 2, "pinned Reek findings status changed")
    reference_text = reference[1]
    verify(reference_text.include?("[3]:ClassVariable:") && reference_text.include?("Counter declares") && reference_text.include?("'@@count'"), "pinned Reek finding or location changed")
    verify(report.include?("lines=\"3\"") && report.include?("context=\"Counter\"") && report.include?("name=\"@@count\""), "combined Reek finding or location differed")
  end

  def self.verify_report_order(report)
    duplication = report.index("Duplication section:")
    score = report.index("Total duplication score:")
    smells = report.index("Smell section:")
    finding = report.index("Finding: check=\"reek:ClassVariable")
    verify(duplication < score && score < smells && smells < finding, "combined sections changed analyzer ordering")
  end

  # :reek:ControlParameter
  def self.verify(condition, message)
    raise message unless condition
  end
end

CombinedProcess.verify(!File.exist?(CombinedProcess::IGNORE_PATH), "unexpected .flayignore already exists")

inputs = CombinedProcess::Input.new("flay:StructuralDuplication,reek:ClassVariable", "test/fixtures/duplication_file_a.rb", "test/fixtures/duplication_file_b.rb", "test/fixtures/class_variable.rb")
combined = CombinedProcess.run(inputs)
CombinedProcess.verify(combined[1].include?("check=\"reek:ClassVariable\""), "combined findings were lost")
CombinedProcess.verify(combined[1].include?("Duplication section:") && combined[1].include?("Smell section:"), "combined sections missing")
CombinedProcess.verify(combined[1].include?("Checks selected: flay:StructuralDuplication,reek:ClassVariable"), "combined checks were not selected")
CombinedProcess.verify(combined[0] == 1 && combined[1].end_with?("Overall status: incomplete\n"), "combined unsupported input implied success")
CombinedProcess.verify(!combined[1].include?("Combined score:"), "combined score was invented")

opposing = CombinedProcess.run_with_opposing_exclusions(inputs)
report, flay_reference, reek_reference = opposing
CombinedProcess.verify(report[1].include?("check=\"reek:ClassVariable\"") && report[1].include?("class_variable.rb\" scope=included"), "Flay ignore leaked into Reek scope")
CombinedProcess.verify(report[1].include?("class_variable.rb\" scope=excluded") && report[1].include?("Duplication coverage: 3 selected; 2 analyzed; 0 failed; 1 excluded"), "Flay ignore did not report excluded source")
CombinedProcess.verify(report[1].include?("Total duplication score: 64") && report[1].include?("duplication_file_a.rb\" scope=included"), "Reek exclusion leaked into Flay scope")
CombinedProcess.verify(report[1].include?("duplication_file_a.rb\" scope=excluded") && report[1].include?("Smell coverage: 3 selected; 1 analyzed; 0 failed; 2 excluded"), "Reek exclusion did not report excluded sources")
CombinedProcess.verify(report[0] == 2 && report[1].end_with?("Overall status: findings\n"), "opposing exclusions changed complete findings status")
CombinedProcess.verify_report_order(report[1])
CombinedProcess.verify(report[1].include?("Overall status: findings"), "combined findings status was not reported")
CombinedProcess.verify_flay_parity(report[1], flay_reference, inputs)
CombinedProcess.verify_reek_parity(report[1], reek_reference)
CombinedProcess.verify(!reek_reference[1].include?("duplication_file_a.rb") && !reek_reference[1].include?("duplication_file_b.rb"), "Reek exclusions leaked into reference input")

clean = CombinedProcess.run_clean
CombinedProcess.verify(clean[0] == 0, "combined clean exit status differed")
CombinedProcess.verify(clean[1].end_with?("Overall status: complete\n"), "combined clean report status differed")

unsupported = CombinedProcess.run(CombinedProcess::Input.new("flay:StructuralDuplication,unknown:Check", "test/fixtures/duplication_file_a.rb", "test/fixtures/duplication_file_b.rb", "test/fixtures/class_variable.rb"))
CombinedProcess.verify(unsupported[0] == 1, "unsupported combined check exit status differed")
CombinedProcess.verify(unsupported[1].empty?, "unsupported combined check ran analysis")
CombinedProcess.verify(unsupported[2].include?("unsupported"), "unsupported combined check diagnostic missing")

puts "Combined analysis contract: pass"
