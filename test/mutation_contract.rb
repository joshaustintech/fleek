# Proves public checks reject deliberately broken parser, CLI, and analyzer behaviors.
class MutationCase
  # Carries one behavior mutation and its expected contract failure.
  Configuration = Struct.new(:source, :target, :replacement, :label, :expected_failure)
  CONTRACTS = {
    "wrong usage status" => "test/cli_contract.rb",
    "embedded NUL acceptance" => "test/native_parser_contract.rb",
    "Ruby 4 grammar downgrade" => "test/native_parser_contract.rb",
    "location attribution" => "test/native_parser_contract.rb",
    "ClassVariable occurrence grouping" => "test/class_variable_scope_contract.rb",
    "ClassVariable nested scope isolation" => "test/class_variable_scope_contract.rb",
    "inherited ClassVariable class rejection" => "test/class_variable_contract.rb",
    "ClassVariable namespace context traversal" => "test/class_variable_contract.rb",
    "ClassVariable wrapped namespace child acceptance" => "test/class_variable_contract.rb",
    "qualified ClassVariable namespace context" => "test/class_variable_contract.rb",
    "ClassVariable nested namespace boundary" => "test/class_variable_contract.rb",
    "ClassVariable namespace occurrence handling" => "test/class_variable_contract.rb",
    "missing ClassVariable finding" => "test/text_report_contract.rb",
    "wrong ClassVariable location" => "test/text_report_contract.rb",
    "false-positive ClassVariable finding" => "test/text_report_contract.rb",
    "wrong ClassVariable findings status" => "test/text_report_contract.rb",
    "hidden directory discovery" => "test/analysis_inputs_contract.rb",
    "directory symlink traversal" => "test/analysis_inputs_contract.rb",
    "empty scan success" => "test/analysis_inputs_contract.rb",
    "empty scan fabricated source count" => "test/analysis_inputs_contract.rb",
    "directory scan failure fabricated source" => "test/analysis_inputs_contract.rb",
    "partial input error precedence" => "test/analysis_inputs_contract.rb",
    "unsupported source path diagnostic" => "test/analysis_inputs_contract.rb",
    "stdin origin requirement" => "test/analysis_stdin_contract.rb",
    "stdin source origin" => "test/analysis_stdin_contract.rb",
    "stdin findings status" => "test/analysis_stdin_contract.rb",
    "empty stdin source fallback" => "test/analysis_stdin_contract.rb",
    "mixed stdin path omission" => "test/analysis_stdin_contract.rb",
    "explicit configuration precedence" => "test/configuration_contract.rb",
    "malformed configuration mapping" => "test/configuration_contract.rb",
    "suppression comment handling" => "test/configuration_contract.rb",
    "disabled selected check handling" => "test/configuration_contract.rb",
    "ClassVariable context exclusions" => "test/configuration_contract.rb",
    "Reek path exclusions" => "test/configuration_contract.rb",
    "named stdin path exclusions" => "test/configuration_contract.rb",
    "Flay structural equality" => "test/duplication_contract.rb",
    "Flay mass boundary" => "test/duplication_contract.rb",
    "Flay identical multiplier" => "test/duplication_contract.rb",
    "Flay total score" => "test/duplication_contract.rb",
    "Flay cross-file method collection" => "test/duplication_contract.rb",
    "Flay class method candidate collection" => "test/duplication_contract.rb",
    "Flay required parameter candidates" => "test/duplication_contract.rb",
    "Flay required parameter arity" => "test/duplication_contract.rb",
    "Flay required parameter identity" => "test/duplication_contract.rb",
    "Flay class method conditional candidates" => "test/duplication_contract.rb",
    "Flay class method unless candidates" => "test/duplication_contract.rb",
    "Flay class method conditional mass" => "test/duplication_contract.rb",
    "Flay class method candidate capacity" => "test/duplication_contract.rb",
    "Flay class group does not hide method findings" => "test/duplication_contract.rb",
    "Flay multiple class declarations" => "test/duplication_contract.rb",
    "Flay cross-class class group rejection" => "test/duplication_contract.rb",
    "Flay namespace class method collection" => "test/duplication_contract.rb",
    "Flay additional class method rejection" => "test/duplication_contract.rb",
    "Flay class method tree topology" => "test/duplication_contract.rb",
    "Flay class method partial subtree" => "test/duplication_contract.rb",
    "Flay class method score" => "test/duplication_contract.rb",
    "Flay class method original locations" => "test/duplication_contract.rb",
    "Flay class method pair ordering" => "test/duplication_contract.rb",
    "Flay class method partial status" => "test/duplication_contract.rb",
    "Flay partial source label" => "test/duplication_contract.rb",
    "Flay partial coverage count" => "test/duplication_contract.rb",
    "Flay ambiguous class group rejection" => "test/duplication_contract.rb",
    "Flay partial class candidates" => "test/duplication_contract.rb",
    "Flay empty namespace classes" => "test/duplication_contract.rb",
    "Flay empty module body guard" => "test/duplication_contract.rb",
    "Flay cross-file location mapping" => "test/duplication_contract.rb",
    "Flay cross-file ordering" => "test/duplication_contract.rb",
    "combined failure precedence" => "test/combined_contract.rb",
    "Flay ignore scope" => "test/combined_contract.rb",
    "Spinel module finding traversal" => "test/language_extensions_contract.rb",
    "Spinel module finding location" => "test/language_extensions_contract.rb",
    "Spinel FFI duplication module traversal" => "test/language_extensions_contract.rb",
    "Ruby 4 logical operator duplication" => "test/language_extensions_contract.rb",
    "Ruby 4 operator final-position boundary" => "test/language_extensions_contract.rb",
    "Spinel FFI module ordering" => "test/language_extensions_contract.rb",
    "text report newline escaping" => "test/text_report_contract.rb",
    "text report source ordering" => "test/text_report_contract.rb",
    "text report section ordering" => "test/text_report_contract.rb",
    "text report check execution" => "test/text_report_contract.rb",
    "text report failed source identity" => "test/text_report_contract.rb",
    "text report completion state" => "test/text_report_contract.rb"
  }

  def initialize(configuration)
    @configuration = configuration
    @selected_labels = ENV["FLEEK_MUTATIONS"]
    @source = configuration.source
  end

  def run
    return unless selected_mutation?

    apply_mutation
    verify_mutation
  ensure
    File.write("bin/fleek.rb", @source)
  end

  def apply_mutation
    mutated = @source.gsub(@configuration.target, @configuration.replacement)
    raise "#{@configuration.label} mutation target missing" if mutated == @source
    File.write("bin/fleek.rb", mutated)
  end

  def selected_mutation?
    return true unless @selected_labels && !@selected_labels.empty?

    labels = @selected_labels.split(",")
    unknown_labels = labels - CONTRACTS.keys
    raise "unknown mutation labels: #{unknown_labels.join(', ')}" unless unknown_labels.empty?
    labels.include?(@configuration.label)
  end

  def verify_mutation
    verify_build
    verify_contract
  end

  def verify_build
    File.delete("build/fleek") if File.file?("build/fleek")
    process_id = Process.spawn("make", "build/fleek", out: "/tmp/fleek-mutation-build-out", err: "/tmp/fleek-mutation-build-err")
    _, status = MutationProcess.wait(process_id)
    raise "#{@configuration.label} mutant failed to compile" unless status.success?
  end

  def verify_contract
    process_id = Process.spawn(ENV["SPINEL"] || "spinel", "-E", CONTRACTS.fetch(@configuration.label), out: "/tmp/fleek-mutation-out", err: "/tmp/fleek-mutation-err")
    _, status = MutationProcess.wait(process_id)
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

# Waits for isolated mutation build and contract subprocesses.
class MutationProcess
  def self.wait(process_id)
    Process.waitpid2(process_id)
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
  "stable finding fields missing")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "group->lines[group->line_count++] = line;",
  "group->lines[group->line_count++] = line + 1;",
  "wrong ClassVariable location",
  "stable finding fields missing")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if findings.empty?",
  "if false",
  "false-positive ClassVariable finding",
  "clean report report status or coverage differs")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "    2\n  end",
  "    0\n  end",
  "wrong ClassVariable findings status",
  "finding result missing")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_groups[group_index].name_length != constant->length || memcmp(fleek_groups[group_index].name, constant->start, constant->length) != 0",
  "false",
  "ClassVariable occurrence grouping",
  "ClassVariable findings differ")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if ((!simple_class && !simple_module && !namespaced_scope) || fleek_unsupported)",
  "if (fleek_unsupported)",
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
  "if files.empty? && errors.empty?",
  "if false",
  "empty scan success",
  "empty discovery was successful")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "Array.new(scan_errors.length, :scan_failure)",
  "Array.new(scan_errors.length, 1)",
  "empty scan fabricated source count",
  "empty discovery fabricated a failed source count")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'SourceFailure.new(path, "ERROR: Directory symlinks are not followed", :request)',
  'SourceFailure.new(path, "ERROR: Directory symlinks are not followed", :source)',
  "directory scan failure fabricated source",
  "directory scan failure fabricated a source row")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "combined == 3 ? 1 : combined",
  "combined",
  "partial input error precedence",
  "partial input report status or coverage differs")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'warn "ERROR: #{quote_text(path)}: ClassVariable supports one simple class or module (optionally within one simple module namespace); other scope shapes are unsupported."',
  'warn "ERROR: ClassVariable supports one simple class or module (optionally within one simple module namespace); other scope shapes are unsupported."',
  "unsupported source path diagnostic",
  "unsupported source not identified")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "scope_keyword = class_node->class_keyword_loc.start;",
  "scope_keyword = class_node->class_keyword_loc.start;\n        if (class_node->superclass != NULL) scope_node = NULL;",
  "inherited ClassVariable class rejection",
  "inherited class status differs from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "bool namespaced_scope = fleek_scope_contains(fleek_namespace_scope, fleek_only_scope) &&",
  "bool namespaced_scope = false &&",
  "ClassVariable namespace context traversal",
  "namespaced class status differs from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_module_has_direct_child(fleek_namespace_scope, fleek_only_scope) &&",
  "true &&",
  "ClassVariable wrapped namespace child acceptance",
  "wrapped namespace child was accepted")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "\"%.*s::%.*s\"",
  "\"%.*s/%.*s\"",
  "qualified ClassVariable namespace context",
  "namespaced class findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_module_has_direct_child(fleek_namespace_scope, fleek_only_scope) &&\n        ((fleek_class_count == 1 && fleek_module_count == 1) || (fleek_class_count == 0 && fleek_module_count == 2))",
  "true &&\n        ((fleek_class_count == 1 && fleek_module_count >= 1) || (fleek_class_count == 0 && fleek_module_count >= 2))",
  "ClassVariable nested namespace boundary",
  "deep namespace was not reported incomplete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (namespace_has_occurrences) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }",
  "if (false) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }",
  "ClassVariable namespace occurrence handling",
  "unreported namespace occurrence implied complete analysis")).run
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
  'configuration.excluded_path?(origin) ? 0 : analyze_stdin_source(origin, configuration)',
  '0',
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
  "mixed stdin and path report status or coverage differs")).run

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
MutationCase.new(MutationCase::Configuration.new(source,
  'configuration.excluded_path?(origin) ? 0 : analyze_stdin_source(origin, configuration)',
  'analyze_stdin_source(origin, configuration)',
  "named stdin path exclusions",
  "excluded stdin status differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "elsif character == \"\\n\"",
  "elsif character == \"not-newline\"",
  "text report newline escaping",
  "source field escaping is ambiguous")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'files.each { |path| print_report_source(path, configuration) }',
  'files.reverse_each { |path| print_report_source(path, configuration) }',
  "text report source ordering",
  "source ordering changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "print_selected_check(files, configuration, origin)\n      print_report_scope",
  "print_report_scope\n      print_selected_check(files, configuration, origin)",
  "text report section ordering",
  "report section order changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'check_runs = report_sources(files, origin).any? { |path| !configuration.excluded_path?(path) }',
  'check_runs = false',
  "text report check execution",
  "run check missing")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'print_failed_sources(failed_sources)',
  'puts "  none"',
  "text report failed source identity",
  "failed source missing from report sources")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'status == 2 ? "findings" : "complete"',
  '"complete"',
  "text report completion state",
  "finding result missing")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "bool same_shape = class_count == 0 ? first_method.shape_count == second_method.shape_count : fleek_duplication_class_shapes_equal(&first_method, &second_method);",
  "bool same_shape = false;",
  "Flay structural equality",
  "similar method group report differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "mass >= (size_t) mass_threshold",
  "mass > (size_t) mass_threshold",
  "Flay mass boundary",
  "similar method group report differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "(identical ? 2 : 1)",
  "(identical ? 1 : 1)",
  "Flay identical multiplier",
  "identical group multiplier changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'puts "Total duplication score: #{score}"',
  'puts "Total duplication score: 0"',
  "Flay total score",
  "similar method group report differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!PM_NODE_TYPE_P(statement, PM_NIL_NODE)) {",
  "if (true) {",
  "Flay cross-file method collection",
  "cross-file report differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (matching_pairs > 1) return false;",
  "if (false) return false;",
  "Flay ambiguous class group rejection",
  "ambiguous class method groups were reported as complete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (PM_NODE_TYPE_P(statement, PM_CLASS_NODE)) {",
  "if (false) {",
  "Flay class method candidate collection",
  "unsupported syntax implied complete analysis")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "method->receiver != NULL || !fleek_duplication_class_parameters((const pm_node_t *) method->parameters)",
  "method->receiver != NULL || method->parameters != NULL || !fleek_duplication_class_parameters((const pm_node_t *) method->parameters)",
  "Flay required parameter candidates",
  "required-parameter class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "parameters->requireds.size > 8",
  "parameters->requireds.size > 1",
  "Flay required parameter arity",
  "parameter-arity class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_constants_equal(&parser, first->name, second->name) && fleek_duplication_class_parameters_equal(&parser, first, second) && fleek_duplication_class_values_equal",
  "fleek_constants_equal(&parser, first->name, second->name) && true && fleek_duplication_class_values_equal",
  "Flay required parameter identity",
  "parameter-name class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_ASSOC_NODE) || PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_READ_NODE) ||\n        PM_NODE_TYPE_P(node, PM_IF_NODE) || PM_NODE_TYPE_P(node, PM_UNLESS_NODE) || PM_NODE_TYPE_P(node, PM_ELSE_NODE);",
  "PM_NODE_TYPE_P(node, PM_ASSOC_NODE) || PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_READ_NODE) ||\n        PM_NODE_TYPE_P(node, PM_UNLESS_NODE) || PM_NODE_TYPE_P(node, PM_ELSE_NODE);",
  "Flay class method conditional candidates",
  "conditional class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_IF_NODE) || PM_NODE_TYPE_P(node, PM_UNLESS_NODE) || PM_NODE_TYPE_P(node, PM_ELSE_NODE);",
  "PM_NODE_TYPE_P(node, PM_IF_NODE) || PM_NODE_TYPE_P(node, PM_ELSE_NODE);",
  "Flay class method unless candidates",
  "unless class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_KEYWORD_HASH_NODE) || PM_NODE_TYPE_P(node, PM_ELSE_NODE)",
  "PM_NODE_TYPE_P(node, PM_KEYWORD_HASH_NODE)",
  "Flay class method conditional mass",
  "conditional class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (set->count == 24 || !fleek_duplication_class_method(child, source, &set->candidates[set->count]))",
  "if (set->count == 16 || !fleek_duplication_class_method(child, source, &set->candidates[set->count]))",
  "Flay class method candidate capacity",
  "class-method candidate capacity parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "possible_class_group = true;\n              fleek_duplication_partial = 1;\n              continue;",
  "possible_class_group = true;\n              fleek_duplication_partial = 1;\n              return false;",
  "Flay class group does not hide method findings",
  "independent class-method candidates were hidden by a possible class group")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (set->count == 24 || !fleek_duplication_class_method(child, source, &set->candidates[set->count])) { fleek_duplication_partial = 1; continue; }",
  "if (set->count == 1 || !fleek_duplication_class_method(child, source, &set->candidates[set->count])) { fleek_duplication_partial = 1; continue; }",
  "Flay additional class method rejection",
  "Rails-shaped class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (method_count != 0 || ffi_module_count != 0 || !fleek_duplication_collect_class_methods(statement, (const uint8_t *) source, &class_candidates)) {",
  "if (class_count != 0 || method_count != 0 || ffi_module_count != 0 || !fleek_duplication_collect_class_methods(statement, (const uint8_t *) source, &class_candidates)) {",
  "Flay multiple class declarations",
  "class methods across classes were not compared")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (possible_class_group) return false;",
  "if (false) return false;",
  "Flay cross-class class group rejection",
  "unsupported cross-class Flay group was reported as a defn group or complete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "set->class_body_counts[left] == set->class_candidate_counts[left] &&\n                set->class_body_counts[right] == set->class_candidate_counts[right] &&",
  "true && true &&",
  "Flay partial class candidates",
  "supported class methods were hidden by unsupported callbacks")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "else if (!fleek_duplication_collect_namespace_classes(statement, (const uint8_t *) source, &class_candidates)) {",
  "else if (true) {",
  "Flay namespace class method collection",
  "simple namespace class methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "(class_node->body != NULL && !PM_NODE_TYPE_P(class_node->body, PM_STATEMENTS_NODE))",
  "(class_node->body == NULL || !PM_NODE_TYPE_P(class_node->body, PM_STATEMENTS_NODE))",
  "Flay empty namespace classes",
  "empty namespaced classes were not analyzed cleanly")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "module_node->body == NULL || !PM_NODE_TYPE_P(module_node->body, PM_STATEMENTS_NODE)",
  "!PM_NODE_TYPE_P(module_node->body, PM_STATEMENTS_NODE)",
  "Flay empty module body guard",
  "empty modules were not analyzed cleanly")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (left->shape_count != right->shape_count || left->data.ast.tree_count != right->data.ast.tree_count) return false;\n      for (size_t index = 0; index < left->data.ast.tree_count; index++) if (left->data.ast.tree[index] != right->data.ast.tree[index]) return false;\n      return true;",
  "return left->shape_count == right->shape_count;",
  "Flay class method tree topology",
  "different class method tree topology was grouped")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (fleek_duplication_class_subtree_mass(&set->candidates[left], left_node) >= (size_t) mass_threshold &&\n                    fleek_duplication_class_subtree_mass(&set->candidates[left], left_node) == fleek_duplication_class_subtree_mass(&set->candidates[right], right_node) &&\n                    fleek_duplication_class_subtrees_equal(&set->candidates[left], left_node, &set->candidates[right], right_node)) return false;",
  "if (false) return false;",
  "Flay class method partial subtree",
  "partial class-method duplicate was silently skipped")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (class_count != 0) {\n        for (size_t index = 0; index < first_method.shape_count; index++) if (fleek_duplication_class_node_massless(first_method.data.ast.nodes[index])) mass--;\n      }",
  "if (class_count != 0) {\n        for (size_t index = 0; index < first_method.shape_count; index++) if (fleek_duplication_class_node_massless(first_method.data.ast.nodes[index])) mass++;\n      }",
  "Flay class method score",
  "Rails-shaped class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "result->line = 1;\n      for (const uint8_t *cursor = source; cursor < method->def_keyword_loc.start; cursor++) if (*cursor == '\\\\n') result->line++;\n      return true;\n    }\n    static bool fleek_duplication_class_shapes_equal",
  "result->line = 1;\n      return true;\n    }\n    static bool fleek_duplication_class_shapes_equal",
  "Flay class method original locations",
  "Rails-shaped class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "*selected_first = set->candidates[left];\n          *selected_second = set->candidates[right];",
  "*selected_first = set->candidates[right];\n          *selected_second = set->candidates[left];",
  "Flay class method pair ordering",
  "Rails-shaped class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'if (!PM_NODE_TYPE_P(child, PM_DEF_NODE)) { fleek_duplication_partial = 1; continue; }',
  'if (!PM_NODE_TYPE_P(child, PM_DEF_NODE)) { fleek_duplication_partial = 0; continue; }',
  "Flay class method partial status",
  "supported class methods were hidden by unsupported callbacks")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'print_duplication_source(path, report.source_scope)',
  'print_duplication_source(path, "included")',
  "Flay partial source label",
  "partial Rails class results were hidden or reported complete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'report.paths.length - report.partial_paths.length',
  'report.paths.length',
  "Flay partial coverage count",
  "unsupported syntax implied complete analysis")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'source_map.reverse.find { |_path, start_line| line >= start_line }',
  'source_map.find { |_path, start_line| line >= start_line }',
  "Flay cross-file location mapping",
  "cross-file report differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  '[included.sort, excluded.sort]',
  '[included.reverse, excluded.sort]',
  "Flay cross-file ordering",
  "failed requested file hid remaining cross-file group")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'return 1 if duplication_status == 1 || smell_status == 1',
  'return 2 if duplication_status == 1 || smell_status == 1',
  "combined failure precedence",
  "combined unsupported input implied success")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'File.fnmatch?(absolute_pattern, absolute_path, pattern.include?("/") ? 0 : File::FNM_PATHNAME)',
  'false',
  "Flay ignore scope",
  "Flay ignore did not report excluded source")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "bool simple_module = fleek_class_count == 0 && fleek_module_count == 1;",
  "bool simple_module = fleek_class_count == 0 && fleek_module_count > 1;",
  "Spinel module finding traversal",
  "NativeDependency ClassVariable finding or location was lost")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'group->lines[group->line_count++] = line;',
  'group->lines[group->line_count++] = line + 1;',
  "Spinel module finding location",
  "NativeDependency ClassVariable finding or location was lost")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "name->length == 8 && memcmp(name->start, \"ffi_func\", 8) == 0",
  "name->length == 7 && memcmp(name->start, \"ffi_func\", 8) == 0",
  "Spinel FFI duplication module traversal",
  "Flay finding or coverage differs")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (PM_NODE_TYPE_P(logical_and->left, PM_INTEGER_NODE) && PM_NODE_TYPE_P(logical_and->right, PM_TRUE_NODE)) return FLEEK_DUPLICATION_RUBY4_AND_STATEMENT;",
  "if (PM_NODE_TYPE_P(logical_and->left, PM_INTEGER_NODE) && PM_NODE_TYPE_P(logical_and->right, PM_TRUE_NODE)) return FLEEK_DUPLICATION_UNSUPPORTED_STATEMENT;",
  "Ruby 4 logical operator duplication",
  "Flay finding or coverage differs")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "tag == FLEEK_DUPLICATION_RUBY4_AND_STATEMENT && statement + 1 != body->body.size",
  "false",
  "Ruby 4 operator final-position boundary",
  "non-final Ruby 4 logical-and was not rejected as incomplete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (method_count != 0 || ffi_module_count != 0) {",
  "if (ffi_module_count != 0) {",
  "Spinel FFI module ordering",
  "Spinel FFI module after methods was not rejected as incomplete")).run

process_id = Process.spawn("make", "build/fleek", out: "/tmp/fleek-mutation-restore-out", err: "/tmp/fleek-mutation-restore-err")
_, status = Process.waitpid2(process_id)
raise "mutation restore failed" unless status.success?
