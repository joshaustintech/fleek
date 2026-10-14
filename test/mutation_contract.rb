# Proves public checks reject two deliberately broken parser/CLI behaviors.
class MutationCase
  # Carries one behavior mutation and its expected contract failure.
  Configuration = Struct.new(:source, :target, :replacement, :label, :expected_failure)

  def initialize(configuration)
    @configuration = configuration
  end

  def run
    source = @configuration.source
    mutated = source.gsub(@configuration.target, @configuration.replacement)
    raise "#{@configuration.label} mutation target missing" if mutated == source

    File.write("bin/fleek.rb", mutated)
    verify_mutation
  ensure
    File.write("bin/fleek.rb", source)
  end

  def verify_mutation
    process_id = Process.spawn("make", "-B", "test", out: "/tmp/fleek-mutation-out", err: "/tmp/fleek-mutation-err")
    _, status = Process.waitpid2(process_id)
    verify_failure(status)
  end

  def verify_failure(status)
    label = @configuration.label
    raise "#{label} mutant survived" if status.success?
    message = File.read("/tmp/fleek-mutation-err")
    raise "unexpected #{label} failure" unless message.include?(@configuration.expected_failure)
    puts "Mutation contract: caught #{label}"
  end
end

source = File.read("bin/fleek.rb")
MutationCase.new(MutationCase::Configuration.new(source,
  "    warn \"Usage: fleek [--help | --version]\"\n    1\n  end",
  "    warn \"Usage: fleek [--help | --version]\"\n    0\n  end",
  "wrong usage status",
  "empty invocation status")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (nul != NULL) return -2;",
  "if (nul != NULL) return -1;",
  "embedded NUL acceptance",
  "embedded NUL was not rejected")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_OPTIONS_VERSION_CRUBY_4_0",
  "PM_OPTIONS_VERSION_CRUBY_3_3",
  "Ruby 4 grammar downgrade",
  "Ruby 4 parse status")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "column = offset - (prefix.rindex(\"\\n\") || -1)",
  "column = 1",
  "location attribution",
  "original byte location changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "scope->occurrence_count++;",
  "scope->occurrence_count += 0;",
  "missing ClassVariable finding",
  "finding status differs from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "group->lines[group->line_count++] = line;",
  "group->lines[group->line_count++] = line + 1;",
  "wrong ClassVariable location",
  "finding context/message/location missing")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if findings.empty?",
  "if false",
  "false-positive ClassVariable finding",
  "clean status differs from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "    2\n  end",
  "    0\n  end",
  "wrong ClassVariable findings status",
  "finding status differs from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_groups[group_index].name_length != constant->length || memcmp(fleek_groups[group_index].name, constant->start, constant->length) != 0",
  "false",
  "ClassVariable occurrence grouping",
  "ClassVariable findings differ")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_class_count != 1 || fleek_module_count != 0 || fleek_unsupported",
  "fleek_unsupported",
  "ClassVariable nested scope isolation",
  "nested scopes were silently reported")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "directory && File.basename(path).start_with?(\".\")",
  "false",
  "hidden directory discovery",
  "directory scan findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return true if File.symlink?(path) && directory",
  "return false if File.symlink?(path) && directory",
  "directory symlink traversal",
  "directory scan findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "files << path",
  "files << path unless files.include?(path)",
  "repeated input suppression",
  "repeated paths findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if files.empty? && errors.empty?",
  "if false",
  "empty scan success",
  "empty discovery was successful")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "combined == 3 ? 1 : combined",
  "combined",
  "partial input error precedence",
  "partial analysis status missing")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'warn "ERROR: #{path}: ClassVariable supports one simple class without inheritance or nested classes or modules."',
  'warn "ERROR: ClassVariable supports one simple class without inheritance or nested classes or modules."',
  "unsupported source path diagnostic",
  "unsupported source not identified")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'return run_class_variable_with_stdin(source_inputs, configuration) if source_inputs[0] == "--stdin"',
  'return 0 if inputs[0] == "--stdin"',
  "stdin origin requirement",
  "stdin origin was not required")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'analyze_class_variable_source(origin, $stdin.read, configuration)',
  'analyze_class_variable_source("wrong.rb", $stdin.read, configuration)',
  "stdin source origin",
  "named stdin differs from file")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'results.unshift(analyze_stdin_source(origin, configuration))',
  'results.unshift(0)',
  "stdin findings status",
  "named stdin differs from file")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "def self.discover_additional_sources(paths, configuration)\n    collect_sources(paths, configuration)\n  end",
  "def self.discover_additional_sources(paths, configuration)\n    files, errors = collect_sources(paths, configuration)\n    add_empty_scan_error(files, errors)\n    [files, errors]\n  end",
  "empty stdin source fallback",
  "named stdin differs from file")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'inputs[2, input_count - 2]',
  '[]',
  "mixed stdin path omission",
  "mixed stdin and path lost analysis")).run

MutationCase.new(MutationCase::Configuration.new(source,
  'path = explicit_path.empty? ? discovered_path : explicit_path',
  'path = discovered_path',
  "explicit configuration precedence",
  "explicit config precedence status differs from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'fail_config(number, "malformed YAML mapping")',
  'nil',
  "malformed configuration mapping",
  "malformed YAML mapping was not rejected before analysis")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'value.include?(": ")',
  'false',
  "malformed YAML list mapping",
  "malformed YAML list mapping was not rejected before analysis")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'if (fleek_suppressed) {',
  'if (false) {',
  "suppression comment handling",
  "suppression status differs from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  '@enabled == false',
  'false',
  "disabled selected check handling",
  "disabled check implied success")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'configuration.excluded_context?(path, context)',
  'false',
  "ClassVariable context exclusions",
  "context exclusion status differs from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'configuration.excluded_path?(path) ? 0 : analyze_class_variable_file(path, configuration)',
  'analyze_class_variable_file(path, configuration)',
  "Reek path exclusions",
  "explicit exclusion implied successful analysis")).run

process_id = Process.spawn("make", "-B", "test", out: "/tmp/fleek-mutation-restore-out", err: "/tmp/fleek-mutation-restore-err")
_, status = Process.waitpid2(process_id)
raise "mutation restore failed" unless status.success?
