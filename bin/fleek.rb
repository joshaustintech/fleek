# Fleek exposes native CLI usage and reference identities.
class Fleek
  VERSION = "0.1.0"
  FLAY_REFERENCE = "2.14.4"
  REEK_REFERENCE = "6.6.0"
  SPINEL_RELEASE = "2026.09.12"

  # Provides the native Prism parser adapter.
  module NativePrism
    ffi_source <<~C
    #include "prism.h"
    #include <stdint.h>
    #include <stdio.h>

    static char fleek_parse_message_buffer[512];
    static char fleek_finding_buffer[4096];
    static int fleek_class_count;
    static int fleek_module_count;
    static int fleek_finding_count;
    static int fleek_unsupported;
    static const pm_class_node_t *fleek_only_class;
    static const uint8_t *fleek_source_start;

    typedef struct {
      const uint8_t *name;
      size_t name_length;
      int lines[128];
      size_t line_count;
    } fleek_group_t;

    static fleek_group_t fleek_groups[64];
    static size_t fleek_group_count;

    typedef struct {
      pm_parser_t *parser;
      const char *class_name;
      size_t class_name_length;
      size_t occurrence_count;
    } fleek_class_t;

    static bool fleek_collect_classes(const pm_node_t *node, void *data) {
      (void) data;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE)) { fleek_class_count++; fleek_only_class = (const pm_class_node_t *) node; }
      if (PM_NODE_TYPE_P(node, PM_MODULE_NODE)) fleek_module_count++;
      return true;
    }

    static bool fleek_class_variables(const pm_node_t *node, void *data) {
      fleek_class_t *scope = (fleek_class_t *) data;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE) || PM_NODE_TYPE_P(node, PM_MODULE_NODE)) return false;
      if (node->type < PM_CLASS_VARIABLE_AND_WRITE_NODE || node->type > PM_CLASS_VARIABLE_WRITE_NODE) return true;
      pm_constant_id_t id = ((pm_class_variable_read_node_t *) node)->name;
      pm_constant_t *constant = pm_constant_pool_id_to_constant(&scope->parser->constant_pool, id);
      scope->occurrence_count++;
      size_t group_index = 0;
      while (group_index < fleek_group_count && (fleek_groups[group_index].name_length != constant->length || memcmp(fleek_groups[group_index].name, constant->start, constant->length) != 0)) group_index++;
      if (group_index == fleek_group_count) {
        if (fleek_group_count == 64) { fleek_unsupported = 1; return true; }
        fleek_groups[group_index].name = constant->start;
        fleek_groups[group_index].name_length = constant->length;
        fleek_groups[group_index].line_count = 0;
        fleek_group_count++;
      }
      fleek_group_t *group = &fleek_groups[group_index];
      if (group->line_count == 128) { fleek_unsupported = 1; return true; }
      int line = 1;
      for (const uint8_t *cursor = fleek_source_start; cursor < node->location.start; cursor++) if (*cursor == '\\n') line++;
      group->lines[group->line_count++] = line;
      return true;
    }

    static void fleek_render_groups(const fleek_class_t *scope) {
      size_t used = 0;
      for (size_t index = 0; index < fleek_group_count; index++) {
        for (size_t next = index + 1; next < fleek_group_count; next++) {
          size_t common = fleek_groups[index].name_length < fleek_groups[next].name_length ? fleek_groups[index].name_length : fleek_groups[next].name_length;
          int comparison = memcmp(fleek_groups[index].name, fleek_groups[next].name, common);
          if (comparison == 0) comparison = fleek_groups[index].name_length < fleek_groups[next].name_length ? -1 : 1;
          if (comparison > 0) { fleek_group_t temporary = fleek_groups[index]; fleek_groups[index] = fleek_groups[next]; fleek_groups[next] = temporary; }
        }
      }
      for (size_t group_index = 0; group_index < fleek_group_count; group_index++) {
        fleek_group_t *group = &fleek_groups[group_index];
        for (size_t line_index = 0; line_index < group->line_count; line_index++) {
          int written = snprintf(fleek_finding_buffer + used, sizeof(fleek_finding_buffer) - used, "%s%d", line_index == 0 ? "" : ", ", group->lines[line_index]);
          if (written < 0 || (size_t) written >= sizeof(fleek_finding_buffer) - used) { fleek_unsupported = 1; return; }
          used += (size_t) written;
        }
        int written = snprintf(fleek_finding_buffer + used, sizeof(fleek_finding_buffer) - used, "\\t%.*s\\t%.*s\\n", (int) scope->class_name_length, scope->class_name, (int) group->name_length, group->name);
        if (written < 0 || (size_t) written >= sizeof(fleek_finding_buffer) - used) { fleek_unsupported = 1; return; }
        used += (size_t) written;
      }
      fleek_finding_count = (int) fleek_group_count;
    }

    int fleek_class_variable(const char *source, size_t length) {
      fleek_finding_buffer[0] = 0;
      fleek_class_count = fleek_module_count = fleek_finding_count = fleek_unsupported = 0;
      fleek_group_count = 0;
      fleek_only_class = NULL;
      if (memchr(source, 0, length) != NULL) return -2;
      fleek_source_start = (const uint8_t *) source;
      pm_options_t options = {0};
      options.line = 1;
      options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser;
      pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) {
        pm_node_destroy(&parser, root);
        pm_parser_free(&parser);
        pm_options_free(&options);
        return -1;
      }
      pm_visit_node(root, fleek_collect_classes, NULL);
      if (fleek_class_count == 0 && fleek_module_count == 0) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
      }
      if (fleek_class_count != 1 || fleek_module_count != 0 || fleek_unsupported) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      const pm_class_node_t *class_node = fleek_only_class;
      if (class_node == NULL || class_node->superclass != NULL || !PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((pm_constant_read_node_t *) class_node->constant_path)->name);
      fleek_class_t scope = { &parser, (const char *) class_name->start, class_name->length, 0 };
      if (class_node->body != NULL) pm_visit_node(class_node->body, fleek_class_variables, &scope);
      if (fleek_unsupported) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      if (scope.occurrence_count > 0) fleek_render_groups(&scope);
      if (fleek_unsupported) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return fleek_finding_count;
    }

    const char *fleek_class_variable_finding(void) { return fleek_finding_buffer; }

    int fleek_parse_ruby4(const char *source, size_t length) {
      fleek_parse_message_buffer[0] = 0;
      const uint8_t *nul = (const uint8_t *) memchr(source, 0, length);
      if (nul != NULL) return -2;
      pm_options_t options = {0};
      options.line = 1;
      options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser;
      pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_parse(&parser);
      int result = -1;
      if (parser.error_list.head != NULL) {
        pm_diagnostic_t *diagnostic = (pm_diagnostic_t *) parser.error_list.head;
        result = (int) (diagnostic->location.start - (const uint8_t *) source);
        snprintf(fleek_parse_message_buffer, sizeof(fleek_parse_message_buffer), "%s", diagnostic->message);
      } else if (parser.comment_list.size > 0) {
        result = -3;
      }
      pm_parser_free(&parser);
      pm_options_free(&options);
      return result;
    }

    const char *fleek_parse_message(void) {
      return fleek_parse_message_buffer;
    }
    C

    ffi_func :fleek_parse_ruby4, [:str, :size_t], :int
    ffi_func :fleek_parse_message, [], :str
    ffi_func :fleek_class_variable, [:str, :size_t], :int
    ffi_func :fleek_class_variable_finding, [], :str
  end

  def self.print_help
    puts "Usage: fleek [--help | --version]"
    print_analysis_usage
    puts "Fleek #{VERSION} is a native Ruby analysis CLI."
    puts "References: Flay #{FLAY_REFERENCE}; Reek #{REEK_REFERENCE}."
    puts "Compiler: Spinel #{SPINEL_RELEASE}."
  end

  def self.print_analysis_usage
    puts "       fleek --parse-ruby4 SOURCE (parser prototype; runs no checks)"
    puts "       fleek --checks reek:ClassVariable SOURCE"
    puts "       fleek --checks reek:ClassVariable --stdin SOURCE [PATH...]"
  end

  def self.help_requested?(arguments)
    first_argument = arguments[0]
    arguments.length == 1 && (first_argument == "--help" || first_argument == "-h")
  end

  def self.version_requested?(arguments)
    first_argument = arguments[0]
    arguments.length == 1 && first_argument == "--version"
  end

  def self.print_version
    puts "Fleek #{VERSION} (Flay #{FLAY_REFERENCE}; Reek #{REEK_REFERENCE}; Spinel #{SPINEL_RELEASE})"
    0
  end

  def self.input_error(arguments)
    if arguments.empty?
      "ERROR: Select supported checks and source inputs."
    else
      "ERROR: Requested check or input is unsupported in this release."
    end
  end

  def self.print_help_if_requested(arguments)
    if help_requested?(arguments)
      print_help
      true
    else
      false
    end
  end

  def self.print_version_if_requested(arguments)
    if version_requested?(arguments)
      print_version
      true
    else
      false
    end
  end

  def self.print_usage_error(message)
    warn message
    warn "Usage: fleek [--help | --version]"
    1
  end

  def self.parse_ruby4_requested?(arguments)
    arguments.length == 2 && arguments[0] == "--parse-ruby4"
  end

  def self.class_variable_requested?(arguments)
    arguments.length >= 3 && arguments[0] == "--checks" && arguments[1] == "reek:ClassVariable"
  end

  def self.run_class_variable(inputs)
    return run_class_variable_with_stdin(inputs) if inputs[0] == "--stdin"

    files, errors = discover_sources(inputs)
    report_input_errors(errors)
    summarize_class_variable_inputs(files, errors)
  end

  def self.run_class_variable_with_stdin(inputs)
    input_count = inputs.length
    origin = inputs[1]
    return report_missing_stdin_origin if input_count < 2 || origin.empty?

    run_named_stdin(origin, inputs[2, input_count - 2])
  end

  def self.run_named_stdin(origin, paths)
    files, errors = discover_additional_sources(paths)
    report_input_errors(errors)
    summarize_class_variable_inputs_with_stdin(files, errors, analyze_stdin_source(origin))
  end

  def self.analyze_stdin_source(origin)
    analyze_class_variable_source(origin, $stdin.read)
  rescue SystemCallError
    warn "ERROR: Cannot read standard input: #{origin}"
    1
  end

  def self.report_missing_stdin_origin
    warn "ERROR: --stdin requires a source filename."
    1
  end

  def self.discover_sources(paths)
    files, errors = collect_sources(paths)
    add_empty_scan_error(files, errors)
    [files, errors]
  end

  def self.discover_additional_sources(paths)
    collect_sources(paths)
  end

  def self.collect_sources(paths)
    files = []
    errors = []
    collect_requested_sources(paths, files, errors)
    [files, errors]
  end

  def self.collect_requested_sources(paths, files, errors)
    paths.each { |path| discover_requested_path(path, files, errors) }
  end

  def self.add_empty_scan_error(files, errors)
    errors << "ERROR: No Ruby source files discovered from the requested inputs." if files.empty? && errors.empty?
  end

  def self.report_input_errors(errors)
    errors.each { |message| warn message }
  end

  def self.discover_requested_path(path, files, errors)
    symlink = File.symlink?(path)
    directory = File.directory?(path)
    if symlink && directory
      errors << "ERROR: Directory symlinks are not followed: #{path}"
    elsif directory
      discover_directory(path, files, errors)
    else
      add_explicit_source(path, files, errors)
    end
  end

  def self.discover_directory(path, files, errors)
    directory_entries(path, errors).each { |entry| discover_directory_entry("#{path}/#{entry}", files, errors) }
  end

  def self.directory_entries(path, errors)
    Dir.children(path).sort
  rescue SystemCallError
    errors << "ERROR: Cannot scan directory: #{path}"
    []
  end

  def self.discover_directory_entry(path, files, errors)
    return if skipped_directory_entry?(path)
    if File.directory?(path)
      discover_directory(path, files, errors)
    elsif ruby_source_path?(path)
      add_explicit_source(path, files, errors)
    end
  end

  def self.skipped_directory_entry?(path)
    directory = File.directory?(path)
    return true if File.symlink?(path) && directory
    directory && File.basename(path).start_with?(".")
  end

  def self.add_explicit_source(path, files, errors)
    unless readable_file?(path)
      errors << "ERROR: Cannot read source file: #{path}"
      return
    end
    unless ruby_source_path?(path)
      errors << "ERROR: Expected Ruby source (.rb): #{path}"
      return
    end
    files << path
  end

  def self.readable_file?(path)
    File.file?(path) && File.readable?(path)
  end

  def self.ruby_source_path?(path)
    path.end_with?(".rb")
  end

  def self.summarize_class_variable_inputs(files, errors)
    summarize_class_variable_results(class_variable_input_results(files, errors), files.length)
  end

  def self.summarize_class_variable_inputs_with_stdin(files, errors, stdin_result)
    results = class_variable_input_results(files, errors)
    results.unshift(stdin_result)
    summarize_class_variable_results(results, files.length + 1)
  end

  def self.summarize_class_variable_results(results, analyzed)
    status = class_variable_input_status(results)
    report_input_summary(analyzed, results.count(1), status == 1 ? "incomplete" : "complete")
    status
  end

  def self.class_variable_input_results(files, errors)
    files.map { |path| analyze_class_variable_file(path) } + Array.new(errors.length, 1)
  end

  def self.class_variable_input_status(results)
    combined = results.inject(0) { |current, result| current | result }
    combined == 3 ? 1 : combined
  end

  def self.report_input_summary(analyzed, failures, completion)
    puts "Coverage: #{analyzed} analyzed; #{failures} failed"
    puts "Status: #{completion}"
  end

  def self.analyze_class_variable_file(path)
    source = File.binread(path)
    analyze_class_variable_source(path, source)
  rescue SystemCallError
      warn "ERROR: Cannot read source file: #{path}"
      1
  end

  def self.analyze_class_variable_source(path, source)
    result = NativePrism.fleek_class_variable(source, source.bytesize)
    return report_unsupported_class(path) if result == -4
    return report_invalid_class_source(path, source) if result < 0
    print_class_variable_result_for_source(path)
  end

  def self.report_unsupported_class(path)
    warn "ERROR: #{path}: ClassVariable supports one simple class without inheritance or nested classes or modules."
    1
  end

  def self.report_invalid_class_source(path, source)
    offset = NativePrism.fleek_parse_ruby4(source, source.bytesize)
    report_parse_failure(path, source, offset)
  end

  def self.print_class_variable_result_for_source(path)
    print_class_variable_result(path)
  end

  def self.print_class_variable_result(path)
    if NativePrism.fleek_class_variable_finding.empty?
      return print_clean_class_variable(path)
    end
    print_class_variable_finding(path)
  end

  def self.print_clean_class_variable(path)
    puts "#{path} -- 0 warnings"
    print_class_variable_completion("complete")
    0
  end

  def self.print_class_variable_finding(path)
    findings = NativePrism.fleek_class_variable_finding.split("\n")
    print_class_variable_header(path, findings.length)
    print_class_variable_findings(findings)
    2
  end

  def self.print_class_variable_findings(findings)
    findings.each { |finding| print_class_variable_finding_line(finding) }
    print_class_variable_completion("findings")
  end

  def self.print_class_variable_header(path, count)
    plural = count == 1 ? "" : "s"
    puts "#{path} -- #{count} warning#{plural}:"
  end

  def self.print_class_variable_finding_line(finding)
    lines, context, variable = finding.split("\t")
    puts "  [#{lines}]:ClassVariable: #{context} declares the class variable '#{variable}' [https://github.com/troessner/reek/blob/v6.6.0/docs/Class-Variable.md]"
  end

  def self.print_class_variable_completion(state)
    puts "Checks: reek:ClassVariable"
    puts "Status: #{state}"
  end

  def self.parse_ruby4_file(path)
    unless readable_file?(path)
      warn "ERROR: Cannot read source file: #{path}"
      return 1
    end

    source = File.binread(path)
    parse_ruby4_source(path, source)
  end

  def self.parse_ruby4_source(path, source)
    offset = NativePrism.fleek_parse_ruby4(source, source.bytesize)
    return report_parse_failure(path, source, offset) unless parse_succeeded?(offset)

    comment_status = offset == -3 ? "; comments retained" : ""
    print_parse_success("PARSE OK (Ruby 4.0 syntax only; no checks ran#{comment_status})")
  end

  def self.print_parse_success(message)
    puts message
    0
  end

  def self.parse_succeeded?(offset)
    offset < 0 && offset != -2
  end

  def self.report_parse_failure(path, source, offset)
    if offset == -2
      warn "#{path}: embedded NUL byte is unsupported"
    else
      report_syntax_error(path, source, offset)
    end
    1
  end

  def self.report_syntax_error(path, source, offset)
    prefix = source.byteslice(0, offset)
    line = prefix.count("\n") + 1
    column = offset - (prefix.rindex("\n") || -1)
    diagnostic = NativePrism.fleek_parse_message
    warn "#{path}:#{line}:#{column}: #{diagnostic} (byte #{offset})"
  end

  def self.run(arguments)
    return parse_ruby4_file(arguments[1]) if parse_ruby4_requested?(arguments)
    return run_class_variable(arguments[2, arguments.length - 2]) if class_variable_requested?(arguments)
    return 0 if print_help_if_requested(arguments)
    return 0 if print_version_if_requested(arguments)

    print_usage_error(input_error(arguments))
  end
end

exit Fleek.run(ARGV)
