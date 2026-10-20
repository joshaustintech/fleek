# frozen_string_literal: true

require "fileutils"
require_relative "analysis_runner"

# Protects Flay ignore-file selection through the public CLIs.
# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:LongParameterList
# :reek:TooManyConstants
# :reek:TooManyStatements
class FlayIgnoreContract
  PROJECT_ROOT = Dir.pwd
  ROOT = "#{ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")}/flayignore-contract-#{Process.pid}"
  FLEEK_PATH = "#{PROJECT_ROOT}/build/fleek"
  GEMFILE_PATH = "#{PROJECT_ROOT}/Gemfile"
  IGNORE_PATH = "#{ROOT}/.flayignore"
  SOURCE = File.read("#{PROJECT_ROOT}/test/fixtures/duplication_file_a.rb")
  PAIRS = {
    "literal" => ["literal/a.rb", "literal/b.rb"],
    "slashless literal" => ["a.rb", "b.rb"],
    "nested slashless literal" => ["literal/nested/a.rb", "literal/nested/b.rb"],
    "directory" => ["directory/a.rb", "directory/b.rb"],
    "nested directory" => ["directory/nested/a.rb", "directory/nested/b.rb"],
    "basename glob" => ["basename_a_skip.rb", "basename_b_skip.rb"],
    "nested basename glob" => ["basename/nested/a_skip.rb", "basename/nested/b_skip.rb"],
    "nested glob" => ["nested_glob/deep/a.rb", "nested_glob/deep/b.rb"],
    "comments" => ["comments/a.rb", "comments/b.rb"],
    "hash-prefixed literal" => ["# comment.rb", "# comment peer.rb"]
  }.freeze
  CONTROL_PAIR = ["controls/a.rb", "controls/b.rb"].freeze

  def self.run
    original_directory = Dir.pwd
    original_gemfile = ENV["BUNDLE_GEMFILE"]
    original_pwd = ENV["PWD"]
    prepare_tree
    ENV["BUNDLE_GEMFILE"] = GEMFILE_PATH
    Dir.chdir(ROOT)
    @root_path = Dir.pwd
    ENV["PWD"] = @root_path
    verify_excluded_pair(PAIRS["literal"], PAIRS["literal"].join("\n"), "literal file")
    File.write(IGNORE_PATH, PAIRS["slashless literal"].join("\n"))
    verify_case(PAIRS["slashless literal"] + PAIRS["nested slashless literal"], PAIRS["slashless literal"], "slashless literal matches root only")
    verify_excluded_pair(PAIRS["directory"], "directory/", "directory suffix")
    File.write(IGNORE_PATH, "directory/")
    verify_case(PAIRS["nested directory"] + PAIRS["directory"], PAIRS["directory"], "directory suffix is not recursive")
    verify_excluded_pair(PAIRS["basename glob"], "*skip.rb", "basename glob")
    verify_excluded_pair(PAIRS["nested basename glob"], "*skip.rb", "nested basename glob")
    verify_excluded_pair(PAIRS["nested glob"], "nested_glob/**/*.rb", "nested glob")
    verify_excluded_pair(PAIRS["hash-prefixed literal"], PAIRS["hash-prefixed literal"].join("\n"), "hash-prefixed literal")
    File.write(IGNORE_PATH, ["", "# comment", "unmatched-pattern"].join("\n"))
    verify_case(PAIRS["comments"], [], "blank, comment, and unmatched patterns")
    File.delete(IGNORE_PATH) if File.exist?(IGNORE_PATH)
    verify_case(PAIRS["literal"], [], "missing ignore file")
    verify_unreadable_ignore
    puts "Flay ignore contract: pass"
  ensure
    Dir.chdir(original_directory) if original_directory
    ENV["BUNDLE_GEMFILE"] = original_gemfile
    ENV["PWD"] = original_pwd
    FileUtils.rm_rf(ROOT) unless ENV.key?("FLEEK_TEMP_ROOT")
  end

  def self.prepare_tree
    FileUtils.mkdir_p(ROOT)
    PAIRS.values.flatten.concat(CONTROL_PAIR).each do |path|
      absolute = "#{ROOT}/#{path}"
      FileUtils.mkdir_p(File.dirname(absolute))
      File.write(absolute, SOURCE)
    end
  end

  def self.verify_excluded_pair(pair, pattern, label)
    File.write(IGNORE_PATH, pattern)
    verify_case(pair + CONTROL_PAIR, pair, label)
  end

  def self.verify_case(paths, excluded_paths, label)
    reference = invoke("flay", paths)
    fleek = invoke("fleek", paths)
    raise "#{label} Flay failed: #{reference.inspect}" unless reference[0].zero?
    verify_scope(fleek[1], paths, excluded_paths, label)
    verify_coverage(fleek[1], paths.length, excluded_paths, label)
    reference_score = total_score(reference[1], "Total score (lower is better) = ")
    fleek_score = total_score(fleek[1], "Total duplication score: ")
    raise "#{label} score differed: Flay=#{reference_score} Fleek=#{fleek_score}\n#{reference[1]}\n#{fleek[1]}" unless reference_score == fleek_score
    raise "#{label} Fleek outcome differed: #{fleek.inspect}" unless fleek[0] == 2 && fleek[2].empty?
  end

  def self.verify_unreadable_ignore
    Dir.mkdir(IGNORE_PATH)
    reference = invoke("flay", PAIRS["literal"])
    fleek = invoke("fleek", PAIRS["literal"])
    verify_failure(reference, "Flay unreadable ignore file")
    verify_failure(fleek, "Fleek unreadable ignore file")
    raise "Unreadable .flayignore outcome differed" unless reference[0] == fleek[0]
  ensure
    FileUtils.rm_rf(IGNORE_PATH)
  end

  def self.verify_scope(report, paths, excluded_paths, label)
    expected = paths.map do |path|
      scope = excluded_paths.include?(path) ? "excluded" : "included"
      "Source: \"#{@root_path}/#{path}\" scope=#{scope}"
    end
    missing = expected.reject { |line| report.include?(line) }
    raise "#{label} source set differed: #{missing.join(", ")}" unless missing.empty?
  end

  def self.verify_coverage(report, selected, excluded_paths, label)
    analyzed = selected - excluded_paths.length
    expected = "Coverage: #{selected} selected; #{analyzed} analyzed; 0 failed; #{excluded_paths.length} excluded"
    raise "#{label} coverage differed" unless report.include?(expected)
  end

  def self.total_score(report, prefix)
    score = report.split(prefix)[1]
    raise "Missing #{prefix} in report: #{report}" unless score
    score.lines.first.to_i
  end

  def self.invoke(tool, paths)
    output = "#{@root_path}/#{tool}.out"
    error = "#{@root_path}/#{tool}.err"
    first, second, third, fourth = paths.map { |path| "#{@root_path}/#{path}" }
    process_id = if tool == "fleek"
      if paths.length == 2
        Process.spawn(FLEEK_PATH, "--checks", "flay:StructuralDuplication", first, second, chdir: ROOT, out: output, err: error)
      else
        Process.spawn(FLEEK_PATH, "--checks", "flay:StructuralDuplication", first, second, third, fourth, chdir: ROOT, out: output, err: error)
      end
    elsif paths.length == 2
      Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "flay", first, second, chdir: ROOT, out: output, err: error)
    else
      Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "flay", first, second, third, fourth, chdir: ROOT, out: output, err: error)
    end
    AnalysisRunner.observe(process_id, output, error)
  end

  def self.verify_failure(result, label)
    raise "#{label} unexpectedly succeeded" if result[0].zero?
    raise "#{label} did not report an error" if result[2].empty?
  end
end

FlayIgnoreContract.run
