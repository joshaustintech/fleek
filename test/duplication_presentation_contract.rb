require_relative "analysis_runner"

# Verifies Flay presentation effects and Fleek's stable report boundary.
# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:TooManyStatements
class DuplicationPresentationContract
  PATH = "test/fixtures/duplication_class_methods_rails_pair.rb"
  OPTIONS = ["--summary", "--diff", "-#", "--verbose"]

  def self.run
    OPTIONS.each { |option| verify_option(option) }
    puts "Flay presentation contract: pass"
  end

  def self.verify_option(option)
    reference = invoke("flay", option)
    actual = invoke("fleek", option)
    raise "Flay #{option} exit status changed" unless reference[0] == 0
    raise "Flay #{option} changed analysis score" unless reference[1].include?("Total score (lower is better) = 48")
    verify_reference_presentation(option, reference)
    return verify_fleek_numbering_option(actual) if option == "-#"
    raise "Fleek #{option} exit status changed" unless actual[0] == 1
    raise "Fleek #{option} wrote report output" unless actual[1].empty?
    raise "Fleek #{option} was accepted into report v1" unless actual[2].include?("Unsupported Flay option: \"#{option}\"")
  end

  def self.verify_fleek_numbering_option(actual)
    raise "Fleek numbering option changed normalized status" unless actual[0] == 2
    raise "Fleek numbering option changed report rows" unless actual[1].include?("Total duplication score: 48") && !actual[1].include?("1) Group:")
    raise "Fleek numbering option wrote stderr" unless actual[2].empty?
    combined = invoke_combined_numbering
    raise "combined Fleek numbering option changed source coverage" unless combined[1].include?("Smell coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
  end

  def self.invoke_combined_numbering
    root = ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")
    process_id = Process.pid
    output = "#{root}/flay-presentation-combined-#{process_id}.out"
    error = "#{root}/flay-presentation-combined-#{process_id}.err"
    executable = File.expand_path("../build/fleek", __dir__)
    worker = Process.spawn(executable, "--checks", "flay:StructuralDuplication,reek:ClassVariable", "-#", PATH, out: output, err: error)
    AnalysisRunner.observe(worker, output, error)
  end

  def self.verify_reference_presentation(option, reference)
    if option == "--summary"
      raise "Flay summary output changed" unless reference[1].include?("48.00:") && reference[2].empty?
    elsif option == "--diff"
      raise "Flay diff output changed" unless reference[1].include?("ruby2ruby is required for diff") && reference[2].empty?
    elsif option == "-#"
      raise "Flay numbering output changed" unless reference[1].include?("Similar code found") && !reference[1].include?("1) Similar") && reference[2].empty?
    else
      raise "Flay verbose output changed" unless reference[1].include?("1) Similar") && reference[2].include?("Processing #{PATH}")
    end
  end

  def self.invoke(tool, option)
    root = ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")
    process_id = Process.pid
    output = "#{root}/flay-presentation-#{tool}-#{process_id}.out"
    error = "#{root}/flay-presentation-#{tool}-#{process_id}.err"
    executable = File.expand_path("../build/fleek", __dir__)
    process_id = if tool == "flay"
      Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "flay", option, PATH, out: output, err: error)
    else
      Process.spawn(executable, "--checks", "flay:StructuralDuplication", option, PATH, out: output, err: error)
    end
    AnalysisRunner.observe(process_id, output, error)
  end
end

DuplicationPresentationContract.run
