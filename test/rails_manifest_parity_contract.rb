require_relative "analysis_runner"

# Compares both selected checks across the pinned Rails Ruby manifest.
class RailsManifestParityContract
  REVISION = "92ce7c470bc31952d7dc51cac15e577a948e479e"
  FILE_COUNT = 25
  FILES_PATH = "/tmp/fleek-rails-manifest-inputs"
  # :reek:TooManyStatements
  # :reek:NilCheck
  def self.run
    root = ENV["FLEEK_RAILS_CORPUS"]
    raise "FLEEK_RAILS_CORPUS is required" if root.nil? || root.empty?
    puts "Rails manifest corpus: #{root}"
    verify_revision(root)
    puts "Rails manifest revision: pass"
    paths = manifest(root)
    puts "Rails manifest files: #{paths.length}"
    flay = run_flay
    puts "Rails manifest Flay status: #{flay[0]}"
    reek = run_reek
    puts "Rails manifest Reek status: #{reek[0]}"
    fleek_reek = run_fleek_reek
    puts "Rails manifest Fleek Reek status: #{fleek_reek[0]}"
    fleek = run_fleek
    puts "Rails manifest Fleek status: #{fleek[0]}"
    verify_flay(flay, fleek, paths)
    verify_reek(reek, fleek_reek, paths)
    puts "Pinned Rails 25-file parity contract: pass (Flay explicitly incomplete)"
  end

  # :reek:TooManyStatements
  def self.verify_revision(root)
    revision_process = Process.spawn("git", "-C", root, "rev-parse", "HEAD", out: "/tmp/fleek-rails-manifest-revision", err: "/tmp/fleek-rails-manifest-revision-err")
    revision = AnalysisRunner.observe(revision_process, "/tmp/fleek-rails-manifest-revision", "/tmp/fleek-rails-manifest-revision-err")
    raise "pinned Rails corpus revision differed" unless revision[0] == 0 && revision[1].strip == REVISION
    clean_process = Process.spawn("git", "-C", root, "diff", "--quiet", REVISION, "--", "app", out: "/tmp/fleek-rails-manifest-clean", err: "/tmp/fleek-rails-manifest-clean-err")
    clean = AnalysisRunner.observe(clean_process, "/tmp/fleek-rails-manifest-clean", "/tmp/fleek-rails-manifest-clean-err")
    raise "pinned Rails app has tracked changes" unless clean[0] == 0
  end

  # :reek:TooManyStatements
  # :reek:DuplicateMethodCall
  def self.manifest(root)
    files_process = Process.spawn("git", "-C", root, "ls-files", "--", "app/**/*.rb", out: "/tmp/fleek-rails-manifest-files", err: "/tmp/fleek-rails-manifest-files-err")
    listed = AnalysisRunner.observe(files_process, "/tmp/fleek-rails-manifest-files", "/tmp/fleek-rails-manifest-files-err")
    raise "could not list pinned Rails Ruby files" unless listed[0] == 0
    paths = listed[1].lines.map { |line| line.strip }.select { |path| path.end_with?(".rb") }
    raise "pinned Rails Ruby manifest count differed" unless paths.length == FILE_COUNT
    paths.each { |path| raise "pinned Rails source missing: #{path}" unless File.file?(File.join(root, path)) }
    absolute_paths = paths.map { |path| File.join(root, path) }
    File.write(FILES_PATH, absolute_paths.join("\n"))
    absolute_paths
  end

  def self.run_flay
    run_with_manifest(ENV["BUNDLE"] || "bundle", "exec", "flay", "--mass", "16", "/tmp/fleek-rails-manifest-flay")
  end

  def self.run_reek
    run_with_manifest(ENV["BUNDLE"] || "bundle", "exec", "reek", "--smell", "ClassVariable", "/tmp/fleek-rails-manifest-reek")
  end

  def self.run_fleek_reek
    process_id = Process.spawn("xargs", File.expand_path("build/fleek"), "--checks", "reek:ClassVariable", in: FILES_PATH, out: "/tmp/fleek-rails-manifest-reek-fleek", err: "/tmp/fleek-rails-manifest-reek-fleek-err")
    AnalysisRunner.observe(process_id, "/tmp/fleek-rails-manifest-reek-fleek", "/tmp/fleek-rails-manifest-reek-fleek-err")
  end

  def self.run_fleek
    run_with_manifest(File.expand_path("build/fleek"), "--checks", "flay:StructuralDuplication,reek:ClassVariable", "--mass", "16", "/tmp/fleek-rails-manifest-fleek")
  end

  # :reek:LongParameterList
  def self.run_with_manifest(program, exec_argument, analyzer_argument, option_argument, value_argument, output_path)
    error_path = "#{output_path}-err"
    process_id = Process.spawn("xargs", program, exec_argument, analyzer_argument, option_argument, value_argument, in: FILES_PATH, out: output_path, err: error_path)
    AnalysisRunner.observe(process_id, output_path, error_path)
  end

  # :reek:TooManyStatements
  # :reek:NilCheck
  # :reek:DuplicateMethodCall
  def self.verify_flay(reference, actual, paths)
    group = "Similar code found in :defn (mass = 48)"
    controller = paths.find { |path| path.end_with?("/app/controllers/users_controller.rb") }
    raise "pinned Rails UsersController missing from manifest" if controller.nil?
    first_location = "#{controller}:51"
    second_location = "#{controller}:58"
    raise "Flay reference invocation failed" unless reference[0] == 0 && reference[2].empty?
    raise "Flay did not find the pinned score-48 group" unless reference[1].include?(group) && reference[1].include?(first_location) && reference[1].include?(second_location) && reference[1].include?("Total score (lower is better) = 48")
    raise "Flay manifest findings changed" unless reference[1].scan("code found in :").length == 1
    locations = reference[1].lines.select { |line| line.include?(".rb:") }.map { |line| line.strip }.sort
    raise "Flay manifest locations changed" unless locations == [first_location, second_location].sort
    expected_group = ["node=\"defn\"", "kind=\"similar\"", "locations=\"#{first_location},#{second_location}\"", "mass=48", "score=48"]
    raise "Fleek changed the pinned Flay group" unless expected_group.all? { |field| actual[1].include?(field) } && actual[1].include?("Total duplication score: 48")
    raise "Fleek did not run both selected checks" unless actual[1].include?("Checks selected: flay:StructuralDuplication,reek:ClassVariable") && actual[1].include?("Checks run: flay:StructuralDuplication,reek:ClassVariable")
    raise "Fleek Flay result must stay explicitly incomplete" unless actual[0] == 1 && actual[1].include?("Duplication coverage: 25 selected; 0 analyzed; 25 failed; 0 excluded") && actual[1].include?("Overall status: incomplete") && actual[2].include?("Partial results may omit Flay candidates")
    raise "Fleek Flay manifest omitted sources" unless paths.all? { |path| actual[1].include?("Source: \"#{path}\" scope=partial") }
  end

  # :reek:DuplicateMethodCall
  # :reek:TooManyStatements
  def self.verify_reek(reference, actual, paths)
    raise "Reek reference invocation failed" unless reference[0] == 0 && reference[2].empty?
    raise "Reek Rails reference was not clean" unless reference[1].include?("0 total warnings")
    raise "Fleek Reek invocation failed" unless actual[0] == 0 && actual[2].empty?
    raise "Fleek changed Reek's Rails result" unless actual[1].include?("Coverage: 25 selected; 25 analyzed; 0 failed; 0 excluded") && !actual[1].include?("Finding: check=\"reek:ClassVariable\"")
    raise "Fleek Reek manifest omitted sources" unless paths.all? { |path| actual[1].include?("Source: \"#{path}\" scope=included") }
  end
end

RailsManifestParityContract.run
