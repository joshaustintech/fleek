# frozen_string_literal: true

require "fileutils"
require_relative "analysis_runner"

# Protects Flay source expansion through the public CLIs.
# :reek:TooManyConstants
class FlayPathsContract
  PROJECT_ROOT = Dir.pwd
  ROOT = "#{ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")}/flay-paths-contract-#{Process.pid}"
  EXTERNAL = "#{ROOT}/../flay-paths-external-#{Process.pid}.rb"
  SOURCE = File.read("#{PROJECT_ROOT}/test/fixtures/duplication_file_a.rb")
  FLEEK_PATH = "#{PROJECT_ROOT}/build/fleek"

  # :reek:TooManyStatements
  def self.run
    original_directory = Dir.pwd
    original_bundle_gemfile = ENV["BUNDLE_GEMFILE"]
    ENV["BUNDLE_GEMFILE"] = "#{PROJECT_ROOT}/Gemfile"
    prepare_tree
    Dir.chdir(ROOT)
    verify_contracts
    puts "Flay paths contract: pass"
  ensure
    Dir.chdir(original_directory) if original_directory
    if original_bundle_gemfile
      ENV["BUNDLE_GEMFILE"] = original_bundle_gemfile
    else
      ENV.delete("BUNDLE_GEMFILE")
    end
    File.delete(EXTERNAL) if File.file?(EXTERNAL)
    FileUtils.rm_rf(ROOT) unless ENV.key?("FLEEK_TEMP_ROOT")
  end

  # :reek:TooManyStatements
  def self.verify_contracts
    verify_overlapping_paths
    verify_absolute_relative_paths
    verify_directory_selection
    verify_missing_input_policy
    verify_empty_input_policy
    verify_literal_glob_policy
    verify_directory_symlink_policy
  end

  # :reek:TooManyStatements
  def self.prepare_tree
    FileUtils.mkdir_p("#{ROOT}/tree/nested")
    FileUtils.mkdir_p("#{ROOT}/tree/.hidden")
    ["tree/a.rb", "tree/nested/b.rb", "tree/.hidden/hidden.rb"].each { |path| File.write("#{ROOT}/#{path}", SOURCE) }
    File.write(EXTERNAL, SOURCE)
    File.symlink("#{ROOT}/tree/nested", "#{ROOT}/tree/alias")
  end

  # :reek:TooManyStatements
  def self.verify_overlapping_paths
    paths = ["tree", "tree/a.rb", "./tree/a.rb"]
    reference = invoke("flay", paths)
    fleek = invoke("fleek", paths)
    reference_output = reference[1]
    fleek_output = fleek[1]
    fleek_details = fleek.inspect
    raise "Flay overlap score changed: #{reference.inspect}" unless reference[0].zero? && reference_output.include?("Total score (lower is better) = 64")
    raise "Fleek did not deduplicate overlapping paths: #{fleek_details}" unless fleek_output.include?("Coverage: 2 selected; 2 analyzed; 0 failed; 0 excluded") && fleek_output.include?("Total duplication score: 64")
    raise "Fleek overlap outcome differed: #{fleek_details}" unless fleek[0] == 2 && fleek[2].empty?
  end

  # :reek:TooManyStatements
  # :reek:DuplicateMethodCall
  def self.verify_absolute_relative_paths
    absolute = File.expand_path("tree/a.rb")
    paths = ["tree/a.rb", absolute, "./tree/a.rb"]
    reference = invoke("flay", paths)
    fleek = invoke("fleek", paths)
    output = fleek[1]
    processed = processed_paths(reference[1] + reference[2])
    unless reference[0].zero? && reference[1].include?("Total score (lower is better) = 64") && processed == [absolute, "tree/a.rb"]
      raise "Flay absolute/relative path identity changed: #{reference.inspect}"
    end
    unless fleek[0] == 2 && output.include?("Coverage: 2 selected; 2 analyzed; 0 failed; 0 excluded") && output.include?("Source: \"#{absolute}\" scope=included") && output.include?('Source: "tree/a.rb" scope=included') && output.include?("Total duplication score: 64")
      raise "Fleek absolute/relative path identity changed: #{fleek.inspect}"
    end
    relative = "../#{File.basename(EXTERNAL)}"
    relative_reference = invoke("flay", ["tree/a.rb", relative])
    relative_fleek = invoke("fleek", ["tree/a.rb", relative])
    raise "Flay parent-relative identity changed" unless relative_reference[0].zero? && relative_reference[2].include?("Processing #{relative}")
    raise "Fleek parent-relative identity changed" unless relative_fleek[1].include?("Source: \"#{relative}\" scope=included")
  end

  # :reek:TooManyStatements
  # :reek:DuplicateMethodCall
  def self.verify_directory_selection
    reference = invoke("flay", ["tree"])
    fleek = invoke("fleek", ["tree"])
    output = fleek[1]
    expected = ["tree/a.rb", "tree/nested/b.rb"]
    processed = processed_paths(reference[1] + reference[2])
    raise "Flay directory selection changed: #{processed.inspect}" unless processed == expected
    raise "Fleek directory selection changed: #{fleek.inspect}" unless includes_sources?(output, expected) && output.include?("Coverage: 2 selected; 2 analyzed; 0 failed; 0 excluded")
    current_reference = invoke("flay", ["."])
    current_fleek = invoke("fleek", ["."])
    raise "Current-directory Flay paths changed" unless processed_paths(current_reference[1] + current_reference[2]) == expected
    raise "Current-directory Fleek paths changed" unless includes_sources?(current_fleek[1], expected)
  end

  def self.processed_paths(output)
    output.lines.filter_map { |line| line.delete_prefix("Processing ").strip if line.start_with?("Processing ") }
  end

  def self.includes_sources?(output, paths)
    paths.all? { |path| output.include?("Source: \"#{path}\" scope=included") }
  end

  # :reek:TooManyStatements
  def self.verify_missing_input_policy
    paths = ["tree", "missing.rb"]
    reference = invoke("flay", paths)
    fleek = invoke("fleek", paths)
    output = fleek[1]
    details = fleek.inspect
    raise "Flay missing-path handling changed" unless reference[0].zero? && (reference[1] + reference[2]).include?("Processing tree/a.rb")
    raise "Fleek missing-path partial coverage changed: #{details}" unless fleek[0] == 1 && fleek[2].empty? && output.include?("Status: incomplete") && output.include?("Coverage: 3 selected; 2 analyzed; 1 failed; 0 excluded") && output.include?('Source: "tree/a.rb" scope=included') && output.include?('Source: "tree/nested/b.rb" scope=included') && output.include?('Source: "missing.rb" scope=failed') && output.include?("Total duplication score: 64")
  end

  # :reek:TooManyStatements
  def self.verify_empty_input_policy
    reference = invoke("flay", [""])
    fleek = invoke("fleek", [""])
    expected = ["tree/a.rb", "tree/nested/b.rb"]
    raise "Flay empty-path fallback changed" unless reference[0].zero? && processed_paths(reference[1] + reference[2]) == expected
    output = fleek[1]
    unless fleek[0] == 1 && output.include?('Source: "" scope=failed') && output.include?("Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded") && output.include?("Status: incomplete")
      raise "Fleek empty-path fail-closed policy changed: #{fleek.inspect}"
    end
  end

  # :reek:TooManyStatements
  def self.verify_literal_glob_policy
    reference = invoke("flay", ["tree/**/*.rb"])
    fleek = invoke("fleek", ["tree/**/*.rb"])
    report = reference[1] + reference[2]
    processed = processed_paths(report)
    raise "Flay literal-glob fallback changed: #{processed.inspect}" unless reference[0].zero? && processed == ["tree/a.rb", "tree/nested/b.rb"]
    raise "Fleek literal-glob failure policy changed" unless fleek[0] == 1 && fleek[2].include?("Cannot read source file") && fleek[1].include?("Status: incomplete")
  end

  def self.verify_directory_symlink_policy
    reference = invoke("flay", ["tree/alias"])
    fleek = invoke("fleek", ["tree/alias"])
    report = reference[1] + reference[2]
    raise "Flay explicit symlink expansion changed" unless reference[0].zero? && report.include?("Processing tree/alias/b.rb")
    raise "Fleek directory-symlink safety policy changed" unless fleek[0] == 1 && fleek[2].include?("Directory symlinks are not followed")
  end

  # :reek:TooManyStatements
  def self.invoke(tool, paths)
    output = "#{ROOT}/#{tool}.out"
    error = "#{ROOT}/#{tool}.err"
    process_id = tool == "fleek" ? invoke_fleek(paths, output, error) : invoke_flay(paths, output, error)
    AnalysisRunner.observe(process_id, output, error)
  end

  # :reek:TooManyStatements
  def self.invoke_fleek(paths, output, error)
    first, second, third = paths
    case paths.length
    when 1 then Process.spawn(FLEEK_PATH, "--checks", "flay:StructuralDuplication", first, chdir: ROOT, out: output, err: error)
    when 2 then Process.spawn(FLEEK_PATH, "--checks", "flay:StructuralDuplication", first, second, chdir: ROOT, out: output, err: error)
    else Process.spawn(FLEEK_PATH, "--checks", "flay:StructuralDuplication", first, second, third, chdir: ROOT, out: output, err: error)
    end
  end

  # :reek:TooManyStatements
  def self.invoke_flay(paths, output, error)
    bundler = ENV["BUNDLE"] || "bundle"
    first, second, third = paths
    case paths.length
    when 1 then Process.spawn(bundler, "exec", "flay", "--verbose", first, chdir: ROOT, out: output, err: error)
    when 2 then Process.spawn(bundler, "exec", "flay", "--verbose", first, second, chdir: ROOT, out: output, err: error)
    else Process.spawn(bundler, "exec", "flay", "--verbose", first, second, third, chdir: ROOT, out: output, err: error)
    end
  end
end

FlayPathsContract.run
