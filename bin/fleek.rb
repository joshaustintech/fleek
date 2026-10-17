# Fleek exposes native CLI usage and reference identities.
# :reek:TooManyConstants
class Fleek
  # :reek:DuplicateMethodCall
  # :reek:LongParameterList
  # :reek:NilCheck
  # :reek:RepeatedConditional
  # :reek:TooManyStatements
  VERSION = "0.2.0"
  # Retains source identity alongside its diagnostic for the text report.
  SourceFailure = Struct.new(:path, :message, :kind)
  # Carries inputs and locations through structural duplication reporting.
  DuplicationReport = Struct.new(:paths, :errors, :source_map, :mass_threshold, :excluded_paths, :source, :result, :partial, :partial_paths, :source_scope)
  # Carries one Flay group through stable report formatting.
  DuplicationGroup = Struct.new(:node, :kind, :mass, :score, :locations)
  # Carries validated analyzer inputs through combined execution.
  CombinedAnalysis = Struct.new(:flay_inputs, :reek_inputs, :configuration, :error, :disabled_paths)
  # Carries source coverage through stable report output.
  Coverage = Struct.new(:selected, :analyzed, :failed, :excluded, :state)
  # Carries parsed ClassVariable inputs through coverage aggregation.
  ClassVariableSummary = Struct.new(:files, :errors, :configuration, :combined_report, :excluded_paths)
  # Carries ClassVariable outcomes through status aggregation.
  ClassVariableResults = Struct.new(:results, :analyzed, :excluded, :combined_report, :excluded_results)
  # Carries source rows through report formatting.
  SourceListing = Struct.new(:files, :configuration, :failed_sources, :excluded_paths)
  # Carries independent analyzer exit results.
  CheckResults = Struct.new(:duplication, :smell)
  # Carries a stable selection and its coverage policy into the combined runner.
  class AnalysisProfile < Struct.new(:selected, :run, :disabled, :unsupported, :report_all)
    def report_lines
      lines = ["Checks selected: #{selected.join(',')}", "Checks run: #{run.join(',')}"]
      lines.concat(coverage_lines) if report_all
      lines
    end

    def coverage_lines
      ["Checks disabled: #{disabled.empty? ? 'none' : disabled.join(',')}", "Checks unsupported: #{unsupported.empty? ? 'none' : unsupported.join(',')}"]
    end

    def final_status(status)
      report_all && !unsupported.empty? ? 1 : status
    end
  end
  # Builds the pinned analyzer selections and coverage policy.
  module CheckProfiles
    DEFAULT_CHECKS = %w[
      flay:StructuralDuplication reek:Attribute reek:BooleanParameter reek:ClassVariable
      reek:ControlParameter reek:DataClump reek:DuplicateMethodCall reek:FeatureEnvy
      reek:InstanceVariableAssumption reek:IrresponsibleModule reek:LongParameterList
      reek:LongYieldList reek:ManualDispatch reek:MissingSafeMethod reek:ModuleInitialize
      reek:NestedIterators reek:NilCheck reek:RepeatedConditional reek:SubclassedFromCoreClass
      reek:TooManyConstants reek:TooManyInstanceVariables reek:TooManyMethods reek:TooManyStatements
      reek:UncommunicativeMethodName reek:UncommunicativeModuleName
      reek:UncommunicativeParameterName reek:UncommunicativeVariableName
      reek:UnusedParameters reek:UtilityFunction
    ].freeze
    RUNNABLE_DEFAULT_CHECKS = DEFAULT_CHECKS
    EXPLICIT_CHECKS = %w[flay:StructuralDuplication reek:ClassVariable].freeze
    EXPLICIT = AnalysisProfile.new(EXPLICIT_CHECKS, EXPLICIT_CHECKS, [], [], false)

    def self.default(configuration, source_paths)
      selected = enabled_defaults(configuration, source_paths)
      selected.concat(configuration.enabled_opt_in_detectors(source_paths).map { |name| "reek:#{name}" })
      profile(selected.uniq)
    end

    def self.enabled_defaults(configuration, source_paths)
      DEFAULT_CHECKS.select { |check| configuration.detector_enabled_anywhere?(check.delete_prefix("reek:"), source_paths) }
    end

    def self.profile(selected)
      disabled = DEFAULT_CHECKS - selected
      run = RUNNABLE_DEFAULT_CHECKS & selected
      AnalysisProfile.new(selected, run, disabled, selected - run, true)
    end
  end
  FLAY_REFERENCE = "2.14.4"
  REEK_REFERENCE = "6.6.0"
  SPINEL_RELEASE = "2026.09.12"

  # Provides the native Prism parser adapter.
  module NativePrism
    DUPLICATION_UNSUPPORTED_SOURCE = -4
    FLAY_DEFAULT_MASS = 16
    ffi_source <<~C
    #include "prism.h"
    #include <stdint.h>
    #include <stdio.h>
    #include <ctype.h>
    #include <stdlib.h>
    #include <regex.h>

    static char fleek_parse_message_buffer[512];
    static char fleek_finding_buffer[4096];
    static char fleek_duplication_buffer[8192];
    static size_t fleek_duplication_buffer_used;
    static int fleek_duplication_total_score;
    static char fleek_attribute_buffer[4096];
    static size_t fleek_attribute_buffer_used;
    static int fleek_attribute_unsupported;
    static int fleek_attribute_public;
    static char fleek_instance_variable_assumption_buffer[4096];
    static char fleek_subclassed_from_core_class_buffer[1024];
    static char fleek_module_initialize_buffer[1024];
    static char fleek_irresponsible_module_buffer[1024];
    static char fleek_long_parameter_list_buffer[8192];
    static size_t fleek_long_parameter_list_used;
    static char fleek_boolean_parameter_buffer[8192];
    static size_t fleek_boolean_parameter_used;
    static char fleek_long_yield_list_buffer[8192];
    static size_t fleek_long_yield_list_used;
    static char fleek_control_parameter_buffer[8192];
    static size_t fleek_control_parameter_used;
    static char fleek_unused_parameters_buffer[8192];
    static size_t fleek_unused_parameters_used;
    static char fleek_utility_function_buffer[8192];
    static size_t fleek_utility_function_used;
    static char fleek_duplicate_method_call_buffer[8192];
    static size_t fleek_duplicate_method_call_used;
    static char fleek_manual_dispatch_buffer[4096];
    static size_t fleek_manual_dispatch_used;
    static char fleek_nil_check_buffer[8192];
    static size_t fleek_nil_check_used;
    static char fleek_missing_safe_method_buffer[4096];
    static size_t fleek_missing_safe_method_used;
    static char fleek_repeated_conditional_buffer[8192];
    static size_t fleek_repeated_conditional_used;
    static char fleek_nested_iterators_buffer[8192];
    static size_t fleek_nested_iterators_used;
    static char fleek_feature_envy_buffer[8192];
    static size_t fleek_feature_envy_used;
    static char fleek_data_clump_buffer[8192];
    static char fleek_too_many_constants_buffer[4096];
    static char fleek_too_many_instance_variables_buffer[4096];
    static char fleek_too_many_methods_buffer[4096];
    static char fleek_too_many_statements_buffer[8192];
    static char fleek_uncommunicative_method_name_buffer[8192];
    static size_t fleek_uncommunicative_method_name_used;
    static char fleek_uncommunicative_module_name_buffer[8192];
    static size_t fleek_uncommunicative_module_name_used;
    static char fleek_uncommunicative_parameter_name_buffer[8192];
    static size_t fleek_uncommunicative_parameter_name_used;
    static char fleek_uncommunicative_variable_name_buffer[8192];
    static size_t fleek_uncommunicative_variable_name_used;
    static size_t fleek_data_clump_used;
    static size_t fleek_too_many_statements_used;
    static bool fleek_matches_any_pattern(const uint8_t *source, size_t length, const char *patterns) {
      const char *start = patterns;
      while (*start != 0) {
        const char *end = strchr(start, '\\n');
        size_t pattern_length = end == NULL ? strlen(start) : (size_t) (end - start);
        if (pattern_length > 0) {
          char pattern[256];
          if (pattern_length >= sizeof(pattern)) return false;
          memcpy(pattern, start, pattern_length);
          pattern[pattern_length] = 0;
          regex_t expression;
          if (regcomp(&expression, pattern, REG_EXTENDED) == 0) {
            char *text = malloc(length + 1);
            if (text == NULL) { regfree(&expression); return false; }
            memcpy(text, source, length);
            text[length] = 0;
            bool matched = regexec(&expression, text, 0, NULL, 0) == 0;
            free(text);
            regfree(&expression);
            if (matched) return true;
          }
        }
        if (end == NULL) break;
        start = end + 1;
      }
      return false;
    }
    static int fleek_duplication_partial;
    static int fleek_class_count;
    static int fleek_module_count;
    static int fleek_finding_count;
    static int fleek_unsupported;
    static int fleek_suppressed;
    static int fleek_bad_suppression;
    static const pm_node_t *fleek_only_scope;
    static const pm_node_t *fleek_namespace_scope;
    static const uint8_t *fleek_source_start;
    static char fleek_scope_name[512];

    static bool fleek_only_comments_between(const uint8_t *start, const uint8_t *end) {
      const uint8_t *cursor = start;
      while (cursor < end) {
        if (isspace(*cursor)) { cursor++; continue; }
        if (*cursor == '#') {
          while (cursor < end && *cursor != '\\n') cursor++;
          continue;
        }
        return false;
      }
      return true;
    }

    static int fleek_comment_suppression(const pm_comment_t *comment) {
      const char *needle = ":reek:ClassVariable";
      size_t needle_length = strlen(needle);
      const uint8_t *directive = NULL;
      for (const uint8_t *cursor = comment->location.start; cursor + needle_length <= comment->location.end; cursor++) {
        if (memcmp(cursor, needle, needle_length) == 0) { directive = cursor + needle_length; break; }
      }
      if (directive == NULL) return 0;
      while (directive < comment->location.end && isspace(*directive)) directive++;
      if (directive == comment->location.end || *directive != '{') return 1;
      directive++;
      while (directive < comment->location.end && isspace(*directive)) directive++;
      if (comment->location.end - directive < 7 || memcmp(directive, "enabled", 7) != 0) return -1;
      directive += 7;
      while (directive < comment->location.end && isspace(*directive)) directive++;
      if (directive == comment->location.end || *directive++ != ':') return -1;
      while (directive < comment->location.end && isspace(*directive)) directive++;
      int enabled = 0;
      if (comment->location.end - directive >= 5 && memcmp(directive, "false", 5) == 0) directive += 5;
      else if (comment->location.end - directive >= 4 && memcmp(directive, "true", 4) == 0) { directive += 4; enabled = 1; }
      else return -1;
      while (directive < comment->location.end && isspace(*directive)) directive++;
      if (directive == comment->location.end || *directive != '}') return -1;
      return enabled ? 2 : 1;
    }

    typedef struct {
      const uint8_t *name;
      size_t name_length;
      int lines[128];
      size_t line_count;
    } fleek_group_t;

    static fleek_group_t fleek_groups[64];
    static size_t fleek_group_count;
    enum { FLEEK_DUPLICATION_PARSE_ERROR = -1, FLEEK_DUPLICATION_NUL_SOURCE = -2, FLEEK_DUPLICATION_UNSUPPORTED_SOURCE = -4 };

    typedef struct {
      union {
        int shapes[128];
        struct { const pm_node_t *nodes[128]; uint16_t tree_starts[128]; uint16_t tree_ends[128]; uint8_t node_ends[128]; int16_t tree[256]; size_t tree_count; } ast;
      } data;
      size_t shape_count;
      size_t parameter_mass;
      int line;
      int scope_kind;
      pm_constant_id_t scope_names[15];
      size_t scope_depth;
      size_t scope_mass;
    } fleek_duplication_method_t;

    typedef struct {
      const pm_def_node_t *methods[24];
      fleek_duplication_method_t candidates[24];
      size_t scope_indices[24];
      size_t scope_body_counts[24];
      size_t scope_candidate_counts[24];
      int scope_lines[24];
      size_t scope_count;
      size_t namespace_count;
      size_t count;
    } fleek_duplication_class_candidates_t;

    typedef struct {
      pm_parser_t *parser;
      const char *class_name;
      size_t class_name_length;
      size_t occurrence_count;
    } fleek_class_t;

    static bool fleek_collect_classes(const pm_node_t *node, void *data) {
      (void) data;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE)) { fleek_class_count++; fleek_only_scope = node; }
      if (PM_NODE_TYPE_P(node, PM_MODULE_NODE)) {
        fleek_module_count++;
        if (fleek_module_count == 1) fleek_namespace_scope = node;
        fleek_only_scope = node;
      }
      return true;
    }

    static bool fleek_scope_contains(const pm_node_t *outer, const pm_node_t *inner) {
      return outer != NULL && inner != NULL && outer != inner && outer->location.start <= inner->location.start && outer->location.end >= inner->location.end;
    }

    static bool fleek_module_has_direct_child(const pm_node_t *module, const pm_node_t *child) {
      const pm_node_t *body = ((const pm_module_node_t *) module)->body;
      if (!PM_NODE_TYPE_P(body, PM_STATEMENTS_NODE)) return false;
      const pm_node_list_t *statements = &((const pm_statements_node_t *) body)->body;
      for (size_t index = 0; index < statements->size; index++) {
        if (statements->nodes[index] == child) return true;
      }
      return false;
    }

    static bool fleek_namespace_has_class_variables(const pm_node_t *node, void *data) {
      bool *found = (bool *) data;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE) || PM_NODE_TYPE_P(node, PM_MODULE_NODE)) return false;
      if (node->type >= PM_CLASS_VARIABLE_AND_WRITE_NODE && node->type <= PM_CLASS_VARIABLE_WRITE_NODE) {
        *found = true;
        return false;
      }
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

    static bool fleek_name_is(pm_parser_t *parser, pm_constant_id_t id, const char *name) {
      pm_constant_t *constant = pm_constant_pool_id_to_constant(&parser->constant_pool, id);
      size_t length = strlen(name);
      return constant->length == length && memcmp(constant->start, name, length) == 0;
    }

    static int fleek_source_line(const uint8_t *source, const uint8_t *position) {
      int line = 1;
      for (const uint8_t *cursor = source; cursor < position; cursor++) if (*cursor == '\\n') line++;
      return line;
    }

    static bool fleek_attribute_calls(const pm_node_t *node, void *data) {
      fleek_class_t *scope = (fleek_class_t *) data;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE) || PM_NODE_TYPE_P(node, PM_MODULE_NODE) || PM_NODE_TYPE_P(node, PM_DEF_NODE) || PM_NODE_TYPE_P(node, PM_SINGLETON_CLASS_NODE)) return false;
      if (!PM_NODE_TYPE_P(node, PM_CALL_NODE)) return true;
      const pm_call_node_t *call = (const pm_call_node_t *) node;
      if (call->receiver != NULL || call->block != NULL) return true;
      if (fleek_name_is(scope->parser, call->name, "private") || fleek_name_is(scope->parser, call->name, "protected") || fleek_name_is(scope->parser, call->name, "public")) {
        if (call->arguments != NULL && call->arguments->arguments.size > 0) fleek_attribute_unsupported = 1;
        else fleek_attribute_public = fleek_name_is(scope->parser, call->name, "public");
        return true;
      }
      bool attr_call = fleek_name_is(scope->parser, call->name, "attr");
      bool attr_writer = false;
      if (attr_call && call->arguments != NULL) {
        const pm_node_list_t *arguments = &call->arguments->arguments;
        if (arguments->size == 1) return true;
        if (arguments->size != 2 || (!PM_NODE_TYPE_P(arguments->nodes[1], PM_TRUE_NODE) && !PM_NODE_TYPE_P(arguments->nodes[1], PM_FALSE_NODE))) { fleek_attribute_unsupported = 1; return true; }
        if (PM_NODE_TYPE_P(arguments->nodes[1], PM_FALSE_NODE)) return true;
        attr_writer = true;
      }
      bool writer = attr_writer || fleek_name_is(scope->parser, call->name, "attr_accessor") || fleek_name_is(scope->parser, call->name, "attr_writer");
      if (!writer || !fleek_attribute_public || call->arguments == NULL) return true;
      const pm_node_list_t *arguments = &call->arguments->arguments;
      size_t argument_count = arguments->size - (attr_writer ? 1 : 0);
      for (size_t index = 0; index < argument_count; index++) {
        const pm_node_t *argument = arguments->nodes[index];
        if (!PM_NODE_TYPE_P(argument, PM_SYMBOL_NODE)) { fleek_attribute_unsupported = 1; continue; }
        const pm_symbol_node_t *symbol = (const pm_symbol_node_t *) argument;
        const uint8_t *name = pm_string_source(&symbol->unescaped);
        size_t length = pm_string_length(&symbol->unescaped);
        int line = fleek_source_line(fleek_source_start, symbol->value_loc.start);
        int written = snprintf(fleek_attribute_buffer + fleek_attribute_buffer_used, sizeof(fleek_attribute_buffer) - fleek_attribute_buffer_used, "%d\\t%.*s#%.*s\\t%.*s\\n", line, (int) scope->class_name_length, scope->class_name, (int) length, name, (int) length, name);
        if (written < 0 || (size_t) written >= sizeof(fleek_attribute_buffer) - fleek_attribute_buffer_used) { fleek_attribute_unsupported = 1; return true; }
        fleek_attribute_buffer_used += (size_t) written;
      }
      return true;
    }

    typedef struct { pm_parser_t *parser; bool found; } fleek_attribute_search_t;

    static bool fleek_has_attribute_writer(const pm_node_t *node, void *data) {
      if (!PM_NODE_TYPE_P(node, PM_CALL_NODE)) return true;
      const pm_call_node_t *call = (const pm_call_node_t *) node;
      fleek_attribute_search_t *search = (fleek_attribute_search_t *) data;
      bool writable_attr = false;
      if (fleek_name_is(search->parser, call->name, "attr") && call->arguments != NULL && call->arguments->arguments.size > 1) {
        const pm_node_t *flag = call->arguments->arguments.nodes[1];
        writable_attr = PM_NODE_TYPE_P(flag, PM_TRUE_NODE) || !PM_NODE_TYPE_P(flag, PM_FALSE_NODE);
      }
      if (fleek_name_is(search->parser, call->name, "attr_accessor") || fleek_name_is(search->parser, call->name, "attr_writer") || writable_attr) {
        search->found = true;
        return false;
      }
      return true;
    }

    int fleek_attribute(const char *source, size_t length) {
      fleek_attribute_buffer[0] = 0;
      fleek_attribute_buffer_used = 0;
      fleek_attribute_unsupported = 0;
      fleek_attribute_public = 1;
      fleek_class_count = fleek_module_count = 0;
      fleek_only_scope = fleek_namespace_scope = NULL;
      if (memchr(source, 0, length) != NULL) return -2;
      fleek_source_start = (const uint8_t *) source;
      pm_options_t options = {0};
      options.line = 1;
      options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser;
      pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -1;
      }
      pm_visit_node(root, fleek_collect_classes, NULL);
      bool simple_scope = fleek_class_count + fleek_module_count == 1 && fleek_only_scope != NULL;
      if (!simple_scope) {
        fleek_attribute_search_t search = { &parser, false };
        pm_visit_node(root, fleek_has_attribute_writer, &search);
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
        return search.found ? -4 : 0;
      }
      const pm_node_t *constant_path;
      const pm_node_t *body;
      if (PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE)) {
        const pm_class_node_t *class_node = (const pm_class_node_t *) fleek_only_scope;
        constant_path = class_node->constant_path;
        body = class_node->body;
      } else {
        const pm_module_node_t *module_node = (const pm_module_node_t *) fleek_only_scope;
        constant_path = module_node->constant_path;
        body = module_node->body;
      }
      if (!PM_NODE_TYPE_P(constant_path, PM_CONSTANT_READ_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) constant_path)->name);
      fleek_class_t scope = { &parser, (const char *) class_name->start, class_name->length, 0 };
      if (body != NULL) pm_visit_node(body, fleek_attribute_calls, &scope);
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return fleek_attribute_unsupported ? -4 : fleek_attribute_buffer_used > 0 ? 1 : 0;
    }

    const char *fleek_attribute_finding(void) { return fleek_attribute_buffer; }

    typedef struct {
      pm_parser_t *parser;
      pm_constant_id_t assumptions[128];
      size_t assumption_count;
      pm_constant_id_t initialized[128];
      size_t initialized_count;
      int initializer;
      int unsupported;
    } fleek_instance_variables_t;

    static bool fleek_id_in_list(const pm_constant_id_t *items, size_t count, pm_constant_id_t id) {
      for (size_t index = 0; index < count; index++) if (items[index] == id) return true;
      return false;
    }

    static bool fleek_collect_instance_variables(const pm_node_t *node, void *data) {
      fleek_instance_variables_t *variables = (fleek_instance_variables_t *) data;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE) || PM_NODE_TYPE_P(node, PM_MODULE_NODE) || PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      if (PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_READ_NODE)) {
        pm_constant_id_t name = ((const pm_instance_variable_read_node_t *) node)->name;
        if (!fleek_id_in_list(variables->assumptions, variables->assumption_count, name)) {
          if (variables->assumption_count == 128) variables->unsupported = 1;
          else variables->assumptions[variables->assumption_count++] = name;
        }
      }
      if (variables->initializer && PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_WRITE_NODE)) {
        pm_constant_id_t name = ((const pm_instance_variable_write_node_t *) node)->name;
        if (!fleek_id_in_list(variables->initialized, variables->initialized_count, name)) {
          if (variables->initialized_count == 128) variables->unsupported = 1;
          else variables->initialized[variables->initialized_count++] = name;
        }
      }
      return true;
    }

    static bool fleek_instance_methods(const pm_node_t *node, void *data) {
      fleek_instance_variables_t *variables = (fleek_instance_variables_t *) data;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE) || PM_NODE_TYPE_P(node, PM_MODULE_NODE)) return false;
      if (!PM_NODE_TYPE_P(node, PM_DEF_NODE)) return true;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->receiver == NULL && method->body != NULL) {
        variables->initializer = fleek_name_is(variables->parser, method->name, "initialize");
        pm_visit_node(method->body, fleek_collect_instance_variables, variables);
      }
      return false;
    }

    int fleek_instance_variable_assumption(const char *source, size_t length) {
      fleek_instance_variable_assumption_buffer[0] = 0;
      fleek_class_count = fleek_module_count = 0;
      fleek_only_scope = fleek_namespace_scope = NULL;
      if (memchr(source, 0, length) != NULL) return -2;
      fleek_source_start = (const uint8_t *) source;
      pm_options_t options = {0};
      options.line = 1;
      options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser;
      pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -1;
      }
      pm_visit_node(root, fleek_collect_classes, NULL);
      if (fleek_class_count == 0) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
      }
      if (fleek_class_count != 1 || fleek_module_count != 0 || !PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      const pm_class_node_t *class_node = (const pm_class_node_t *) fleek_only_scope;
      if (!PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) class_node->constant_path)->name);
      fleek_instance_variables_t variables = { &parser, {0}, 0, {0}, 0, 0, 0 };
      if (class_node->body != NULL) pm_visit_node(class_node->body, fleek_instance_methods, &variables);
      size_t used = 0;
      int line = fleek_source_line((const uint8_t *) source, class_node->class_keyword_loc.start);
      for (size_t index = 0; index < variables.assumption_count; index++) {
        pm_constant_id_t name = variables.assumptions[index];
        if (fleek_id_in_list(variables.initialized, variables.initialized_count, name)) continue;
        pm_constant_t *variable = pm_constant_pool_id_to_constant(&parser.constant_pool, name);
        int written = snprintf(fleek_instance_variable_assumption_buffer + used, sizeof(fleek_instance_variable_assumption_buffer) - used, "%d\\t%.*s\\t%.*s\\n", line, (int) class_name->length, class_name->start, (int) variable->length, variable->start);
        if (written < 0 || (size_t) written >= sizeof(fleek_instance_variable_assumption_buffer) - used) { variables.unsupported = 1; break; }
        used += (size_t) written;
      }
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return variables.unsupported ? -4 : used > 0 ? 1 : 0;
    }

    const char *fleek_instance_variable_assumption_finding(void) { return fleek_instance_variable_assumption_buffer; }

    typedef struct { pm_parser_t *parser; bool found; } fleek_class_new_search_t;

    static bool fleek_class_new_expression(pm_parser_t *parser, const pm_node_t *node) {
      if (!PM_NODE_TYPE_P(node, PM_CALL_NODE)) return false;
      const pm_call_node_t *call = (const pm_call_node_t *) node;
      return call->receiver != NULL && PM_NODE_TYPE_P(call->receiver, PM_CONSTANT_READ_NODE) && fleek_name_is(parser, call->name, "new") && fleek_name_is(parser, ((const pm_constant_read_node_t *) call->receiver)->name, "Class");
    }

    static bool fleek_class_new_assignment(const pm_node_t *node, void *data) {
      fleek_class_new_search_t *search = (fleek_class_new_search_t *) data;
      const pm_node_t *value = NULL;
      if (PM_NODE_TYPE_P(node, PM_CONSTANT_WRITE_NODE)) value = ((const pm_constant_write_node_t *) node)->value;
      else if (PM_NODE_TYPE_P(node, PM_CONSTANT_PATH_WRITE_NODE)) value = ((const pm_constant_path_write_node_t *) node)->value;
      else if (PM_NODE_TYPE_P(node, PM_CONSTANT_AND_WRITE_NODE)) value = ((const pm_constant_and_write_node_t *) node)->value;
      else if (PM_NODE_TYPE_P(node, PM_CONSTANT_OR_WRITE_NODE)) value = ((const pm_constant_or_write_node_t *) node)->value;
      else if (PM_NODE_TYPE_P(node, PM_CONSTANT_OPERATOR_WRITE_NODE)) value = ((const pm_constant_operator_write_node_t *) node)->value;
      if (value != NULL && fleek_class_new_expression(search->parser, value)) { search->found = true; return false; }
      return true;
    }

    static bool fleek_has_class_new(pm_parser_t *parser, pm_node_t *root) {
      fleek_class_new_search_t search = { parser, false };
      pm_visit_node(root, fleek_class_new_assignment, &search);
      return search.found;
    }

    int fleek_subclassed_from_core_class(const char *source, size_t length) {
      fleek_subclassed_from_core_class_buffer[0] = 0;
      fleek_class_count = fleek_module_count = 0;
      fleek_only_scope = fleek_namespace_scope = NULL;
      if (memchr(source, 0, length) != NULL) return -2;
      fleek_source_start = (const uint8_t *) source;
      pm_options_t options = {0};
      options.line = 1;
      options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser;
      pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -1;
      }
      if (fleek_has_class_new(&parser, root)) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }
      pm_visit_node(root, fleek_collect_classes, NULL);
      if (fleek_class_count == 0) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
      }
      if (fleek_class_count != 1 || fleek_module_count != 0 || !PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      const pm_class_node_t *class_node = (const pm_class_node_t *) fleek_only_scope;
      if (class_node->superclass == NULL) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
      }
      if (!PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE) || !PM_NODE_TYPE_P(class_node->superclass, PM_CONSTANT_READ_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) class_node->constant_path)->name);
      pm_constant_t *superclass_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) class_node->superclass)->name);
      bool core = (superclass_name->length == 5 && memcmp(superclass_name->start, "Array", 5) == 0) ||
        (superclass_name->length == 4 && memcmp(superclass_name->start, "Hash", 4) == 0) ||
        (superclass_name->length == 6 && memcmp(superclass_name->start, "String", 6) == 0);
      int result = 0;
      if (core) {
        int line = fleek_source_line((const uint8_t *) source, class_node->class_keyword_loc.start);
        int written = snprintf(fleek_subclassed_from_core_class_buffer, sizeof(fleek_subclassed_from_core_class_buffer), "%d\\t%.*s\\t%.*s\\n", line, (int) class_name->length, class_name->start, (int) superclass_name->length, superclass_name->start);
        result = written < 0 || (size_t) written >= sizeof(fleek_subclassed_from_core_class_buffer) ? -4 : 1;
      }
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return result;
    }

    const char *fleek_subclassed_from_core_class_finding(void) { return fleek_subclassed_from_core_class_buffer; }

    typedef struct { pm_parser_t *parser; bool found; } fleek_module_initialize_t;

    static bool fleek_module_defines_initialize(const pm_node_t *node, void *data) {
      fleek_module_initialize_t *state = (fleek_module_initialize_t *) data;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE) || PM_NODE_TYPE_P(node, PM_MODULE_NODE)) return false;
      if (!PM_NODE_TYPE_P(node, PM_DEF_NODE)) return true;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->receiver == NULL && fleek_name_is(state->parser, method->name, "initialize")) {
        state->found = true;
        return false;
      }
      return false;
    }

    int fleek_module_initialize(const char *source, size_t length) {
      fleek_module_initialize_buffer[0] = 0;
      fleek_class_count = fleek_module_count = 0;
      fleek_only_scope = fleek_namespace_scope = NULL;
      if (memchr(source, 0, length) != NULL) return -2;
      fleek_source_start = (const uint8_t *) source;
      pm_options_t options = {0};
      options.line = 1;
      options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser;
      pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -1;
      }
      pm_visit_node(root, fleek_collect_classes, NULL);
      if (fleek_module_count == 0) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
      }
      if (fleek_module_count != 1 || fleek_class_count != 0 || !PM_NODE_TYPE_P(fleek_only_scope, PM_MODULE_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      const pm_module_node_t *module_node = (const pm_module_node_t *) fleek_only_scope;
      if (!PM_NODE_TYPE_P(module_node->constant_path, PM_CONSTANT_READ_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      pm_constant_t *module_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) module_node->constant_path)->name);
      fleek_module_initialize_t state = { &parser, false };
      if (module_node->body != NULL) pm_visit_node(module_node->body, fleek_module_defines_initialize, &state);
      int result = 0;
      if (state.found) {
        int line = fleek_source_line((const uint8_t *) source, module_node->module_keyword_loc.start);
        int written = snprintf(fleek_module_initialize_buffer, sizeof(fleek_module_initialize_buffer), "%d\\t%.*s\\tinitialize\\n", line, (int) module_name->length, module_name->start);
        result = written < 0 || (size_t) written >= sizeof(fleek_module_initialize_buffer) ? -4 : 1;
      }
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return result;
    }

    const char *fleek_module_initialize_finding(void) { return fleek_module_initialize_buffer; }

    static int fleek_whitespace_newlines(const uint8_t *start, const uint8_t *end) {
      int newlines = 0;
      for (const uint8_t *cursor = start; cursor < end; cursor++) {
        if (*cursor == '\\n') newlines++;
        else if (!isspace(*cursor)) return -1;
      }
      return newlines;
    }

    static int fleek_comment_words(const pm_comment_t *comment) {
      int words = 0;
      bool in_word = false;
      for (const uint8_t *cursor = comment->location.start; cursor < comment->location.end; cursor++) {
        if (comment->location.end - cursor >= 6 && memcmp(cursor, ":reek:", 6) == 0) {
          while (cursor < comment->location.end && !isspace(*cursor)) cursor++;
          const uint8_t *options = cursor;
          while (options < comment->location.end && isspace(*options)) options++;
          if (options < comment->location.end && *options == '{') {
            cursor = options;
            while (cursor < comment->location.end && *cursor != '}') cursor++;
          }
          in_word = false;
        } else if (*cursor == '#' || isspace(*cursor)) {
          in_word = false;
        } else if (!in_word) {
          words++;
          in_word = true;
        }
      }
      return words;
    }

    static int fleek_scope_descriptively_commented(pm_parser_t *parser, const uint8_t *keyword) {
      const pm_comment_t *comments[128];
      size_t count = 0;
      bool overflow = false;
      for (pm_list_node_t *item = parser->comment_list.head; item != NULL; item = item->next) {
        const pm_comment_t *comment = (const pm_comment_t *) item;
        if (comment->location.end > keyword) continue;
        if (count == 128) { overflow = true; continue; }
        comments[count++] = comment;
      }
      if (overflow) return -1;
      size_t nearest = count;
      while (nearest > 0) {
        nearest--;
        if (fleek_whitespace_newlines(comments[nearest]->location.end, keyword) == 1) break;
      }
      if (count == 0 || nearest >= count || fleek_whitespace_newlines(comments[nearest]->location.end, keyword) != 1) return 0;
      int words = 0;
      words += fleek_comment_words(comments[nearest]);
      while (nearest > 0 && fleek_whitespace_newlines(comments[nearest - 1]->location.end, comments[nearest]->location.start) == 1) {
        nearest--;
        words += fleek_comment_words(comments[nearest]);
      }
      return words >= 2 ? 1 : 0;
    }

    int fleek_irresponsible_module(const char *source, size_t length) {
      fleek_irresponsible_module_buffer[0] = 0;
      fleek_class_count = fleek_module_count = 0;
      fleek_only_scope = fleek_namespace_scope = NULL;
      if (memchr(source, 0, length) != NULL) return -2;
      fleek_source_start = (const uint8_t *) source;
      pm_options_t options = {0};
      options.line = 1;
      options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser;
      pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -1;
      }
      if (fleek_has_class_new(&parser, root)) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }
      pm_visit_node(root, fleek_collect_classes, NULL);
      if (fleek_class_count + fleek_module_count == 0) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
      }
      if (fleek_class_count + fleek_module_count != 1) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      const pm_node_t *constant_path;
      const uint8_t *keyword;
      if (PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE)) {
        const pm_class_node_t *class_node = (const pm_class_node_t *) fleek_only_scope;
        constant_path = class_node->constant_path;
        keyword = class_node->class_keyword_loc.start;
      } else {
        const pm_module_node_t *module_node = (const pm_module_node_t *) fleek_only_scope;
        constant_path = module_node->constant_path;
        keyword = module_node->module_keyword_loc.start;
      }
      if (!PM_NODE_TYPE_P(constant_path, PM_CONSTANT_READ_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      pm_constant_t *context = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) constant_path)->name);
      int result = 0;
      int comment_status = fleek_scope_descriptively_commented(&parser, keyword);
      if (comment_status < 0) result = -4;
      else if (comment_status == 0) {
        int line = fleek_source_line((const uint8_t *) source, keyword);
        int written = snprintf(fleek_irresponsible_module_buffer, sizeof(fleek_irresponsible_module_buffer), "%d\\t%.*s\\t\\n", line, (int) context->length, context->start);
        result = written < 0 || (size_t) written >= sizeof(fleek_irresponsible_module_buffer) ? -4 : 1;
      }
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return result;
    }

    const char *fleek_irresponsible_module_finding(void) { return fleek_irresponsible_module_buffer; }

    static size_t fleek_parameter_count(const pm_parameters_node_t *parameters) {
      if (parameters == NULL) return 0;
      return parameters->requireds.size + parameters->optionals.size + parameters->posts.size +
        parameters->keywords.size + (parameters->rest != NULL) + (parameters->keyword_rest != NULL) +
        (parameters->block != NULL);
    }

    typedef int (*fleek_method_analyzer_t)(pm_parser_t *, const uint8_t *, const char *, size_t, const pm_node_t *, void *);

    static int fleek_scan_method_scope(const char *source, size_t length, fleek_method_analyzer_t analyze, void *state) {
      fleek_class_count = fleek_module_count = 0;
      fleek_only_scope = NULL;
      if (memchr(source, 0, length) != NULL) return -2;
      fleek_source_start = (const uint8_t *) source;
      pm_options_t options = {0};
      options.line = 1;
      options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser;
      pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -1; }
      pm_visit_node(root, fleek_collect_classes, NULL);
      if (fleek_class_count + fleek_module_count > 1 || (fleek_class_count + fleek_module_count == 1 && fleek_only_scope == NULL)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      const pm_node_t *body;
      const char *class_name_text;
      size_t class_name_length;
      if (fleek_class_count + fleek_module_count == 0) {
        if (!PM_NODE_TYPE_P(root, PM_PROGRAM_NODE)) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }
        body = (const pm_node_t *) ((const pm_program_node_t *) root)->statements;
        class_name_text = "Object";
        class_name_length = 6;
      } else {
        const pm_node_t *constant_path;
        if (PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE)) {
          const pm_class_node_t *class_node = (const pm_class_node_t *) fleek_only_scope;
          constant_path = class_node->constant_path;
          body = class_node->body;
        } else {
          const pm_module_node_t *module_node = (const pm_module_node_t *) fleek_only_scope;
          constant_path = module_node->constant_path;
          body = module_node->body;
        }
        if (!PM_NODE_TYPE_P(constant_path, PM_CONSTANT_READ_NODE)) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }
        pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) constant_path)->name);
        class_name_text = (const char *) class_name->start;
        class_name_length = class_name->length;
      }
      int findings = 0;
      if (body != NULL && !PM_NODE_TYPE_P(body, PM_STATEMENTS_NODE)) findings = -1;
      if (findings >= 0 && body != NULL) {
        const pm_statements_node_t *statements = (const pm_statements_node_t *) body;
        if (statements->body.size > 128) findings = -1;
        for (size_t index = 0; findings >= 0 && index < statements->body.size; index++) {
          if (!PM_NODE_TYPE_P(statements->body.nodes[index], PM_DEF_NODE)) continue;
          int result = analyze(&parser, (const uint8_t *) source, class_name_text,
            class_name_length, statements->body.nodes[index], state);
          if (result < 0) findings = -1;
          else findings += result;
        }
      }
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return findings < 0 ? -4 : findings;
    }

    typedef struct { size_t count; } fleek_scope_count_state_t;
    typedef struct { pm_constant_id_t names[128]; size_t count; } fleek_parameter_names_t;
    typedef struct { size_t max_copies; size_t min_clump; pm_constant_id_t names[128][64]; size_t counts[128]; size_t lines[128]; size_t methods; bool unsupported; } fleek_data_clump_state_t;
    static bool fleek_data_clump_method(const pm_node_t *node, const uint8_t *source, fleek_data_clump_state_t *state) {
      if (!PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->receiver != NULL) return true;
      if (method->parameters == NULL) { if (state->methods == 128) { state->unsupported = true; return false; } state->methods++; return true; }
      if (!PM_NODE_TYPE_P((const pm_node_t *) method->parameters, PM_PARAMETERS_NODE)) { state->unsupported = true; return false; }
      const pm_parameters_node_t *parameters = method->parameters;
      if (parameters->requireds.size + parameters->optionals.size > 64 || parameters->rest != NULL || parameters->posts.size != 0 || parameters->keywords.size != 0 || parameters->keyword_rest != NULL || parameters->block != NULL) { state->unsupported = true; return true; }
      if (state->methods == 128) { state->unsupported = true; return true; }
      size_t method_index = state->methods++;
      state->lines[method_index] = 1;
      for (const uint8_t *cursor = source; cursor < method->def_keyword_loc.start; cursor++) if (*cursor == '\\n') state->lines[method_index]++;
      for (size_t index = 0; index < parameters->requireds.size; index++) {
        if (!PM_NODE_TYPE_P(parameters->requireds.nodes[index], PM_REQUIRED_PARAMETER_NODE)) { state->unsupported = true; return false; }
        state->names[method_index][state->counts[method_index]++] = ((const pm_required_parameter_node_t *) parameters->requireds.nodes[index])->name;
      }
      for (size_t index = 0; index < parameters->optionals.size; index++) {
        if (!PM_NODE_TYPE_P(parameters->optionals.nodes[index], PM_OPTIONAL_PARAMETER_NODE)) { state->unsupported = true; return false; }
        state->names[method_index][state->counts[method_index]++] = ((const pm_optional_parameter_node_t *) parameters->optionals.nodes[index])->name;
      }
      return true;
    }

    typedef struct { size_t maximum; } fleek_long_parameter_state_t;
    static bool fleek_has_block(const pm_node_t *node, void *data) {
      bool *found = (bool *) data;
      if (PM_NODE_TYPE_P(node, PM_BLOCK_NODE)) { *found = true; return false; }
      return !PM_NODE_TYPE_P(node, PM_DEF_NODE);
    }

    static int fleek_long_parameter_list_method(pm_parser_t *parser, const uint8_t *source,
        const char *class_name, size_t class_name_length, const pm_node_t *node, void *data) {
      if (!PM_NODE_TYPE_P(node, PM_DEF_NODE)) return 0;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      bool class_method = method->receiver != NULL;
      if ((class_method && !PM_NODE_TYPE_P(method->receiver, PM_SELF_NODE)) || (method->parameters != NULL && !PM_NODE_TYPE_P((const pm_node_t *) method->parameters, PM_PARAMETERS_NODE))) return -1;
      bool has_block = false;
      if (method->body != NULL) pm_visit_node(method->body, fleek_has_block, &has_block);
      if (has_block) return -1;
      size_t count = fleek_parameter_count((const pm_parameters_node_t *) method->parameters);
      const fleek_long_parameter_state_t *state = (const fleek_long_parameter_state_t *) data;
      size_t method_maximum = fleek_name_is(parser, method->name, "initialize") ? 5 : state->maximum;
      if (count <= method_maximum) return 0;
      pm_constant_t *method_name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      int line = fleek_source_line(source, method->def_keyword_loc.start);
      int written = snprintf(fleek_long_parameter_list_buffer + fleek_long_parameter_list_used,
        sizeof(fleek_long_parameter_list_buffer) - fleek_long_parameter_list_used,
        "%d\\t%.*s#%s%.*s\\t%zu\\n", line, (int) class_name_length, class_name, class_method ? "self." : "",
        (int) method_name->length, method_name->start, count);
      if (written < 0 || (size_t) written >= sizeof(fleek_long_parameter_list_buffer) - fleek_long_parameter_list_used) return -1;
      fleek_long_parameter_list_used += (size_t) written;
      return 1;
    }

    int fleek_long_parameter_list(const char *source, size_t length, size_t maximum) {
      fleek_long_parameter_list_buffer[0] = 0;
      fleek_long_parameter_list_used = 0;
      fleek_long_parameter_state_t state = { maximum };
      return fleek_scan_method_scope(source, length, fleek_long_parameter_list_method, &state);
    }

    const char *fleek_long_parameter_list_finding(void) { return fleek_long_parameter_list_buffer; }

    static int fleek_boolean_parameter_method(pm_parser_t *parser, const uint8_t *source,
        const char *class_name, size_t class_name_length, const pm_node_t *node, void *data) {
      (void) data;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      bool class_method = method->receiver != NULL;
      if (class_method && !PM_NODE_TYPE_P(method->receiver, PM_SELF_NODE)) return -1;
      if (method->parameters == NULL) return 0;
      const pm_parameters_node_t *parameters = method->parameters;
      pm_constant_t *method_name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      int method_line = fleek_source_line(source, method->def_keyword_loc.start);
      size_t count = parameters->optionals.size + parameters->keywords.size;
      int findings = 0;
      for (size_t index = 0; index < count; index++) {
        const pm_node_t *parameter = index < parameters->optionals.size ? parameters->optionals.nodes[index] : parameters->keywords.nodes[index - parameters->optionals.size];
        pm_constant_id_t parameter_name;
        const pm_node_t *value;
        if (PM_NODE_TYPE_P(parameter, PM_OPTIONAL_PARAMETER_NODE)) {
          const pm_optional_parameter_node_t *optional = (const pm_optional_parameter_node_t *) parameter;
          parameter_name = optional->name;
          value = optional->value;
        } else if (PM_NODE_TYPE_P(parameter, PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) {
          const pm_optional_keyword_parameter_node_t *optional = (const pm_optional_keyword_parameter_node_t *) parameter;
          parameter_name = optional->name;
          value = optional->value;
        } else return -1;
        if (!PM_NODE_TYPE_P(value, PM_TRUE_NODE) && !PM_NODE_TYPE_P(value, PM_FALSE_NODE)) continue;
        pm_constant_t *name = pm_constant_pool_id_to_constant(&parser->constant_pool, parameter_name);
        int written = snprintf(fleek_boolean_parameter_buffer + fleek_boolean_parameter_used,
          sizeof(fleek_boolean_parameter_buffer) - fleek_boolean_parameter_used,
          "%d\\t%.*s#%s%.*s\\t%.*s\\n", method_line, (int) class_name_length, class_name, class_method ? "self." : "",
          (int) method_name->length, method_name->start, (int) name->length, name->start);
        if (written < 0 || (size_t) written >= sizeof(fleek_boolean_parameter_buffer) - fleek_boolean_parameter_used) return -1;
        fleek_boolean_parameter_used += (size_t) written;
        findings++;
      }
      return findings;
    }

    int fleek_boolean_parameter(const char *source, size_t length) {
      fleek_boolean_parameter_buffer[0] = 0;
      fleek_boolean_parameter_used = 0;
      return fleek_scan_method_scope(source, length, fleek_boolean_parameter_method, NULL);
    }

    const char *fleek_boolean_parameter_finding(void) { return fleek_boolean_parameter_buffer; }

    typedef struct {
      pm_parser_t *parser;
      const uint8_t *source;
      const char *class_name;
      size_t class_name_length;
      const pm_def_node_t *method;
      size_t maximum;
      int findings;
      bool overflow;
    } fleek_long_yield_state_t;

    static bool fleek_long_yield_visit(const pm_node_t *node, void *data) {
      fleek_long_yield_state_t *state = (fleek_long_yield_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      if (!PM_NODE_TYPE_P(node, PM_YIELD_NODE)) return true;
      const pm_yield_node_t *yield_node = (const pm_yield_node_t *) node;
      size_t count = yield_node->arguments == NULL ? 0 : yield_node->arguments->arguments.size;
      if (count <= state->maximum) return false;
      pm_constant_t *method_name = pm_constant_pool_id_to_constant(&state->parser->constant_pool, state->method->name);
      int line = fleek_source_line(state->source, yield_node->keyword_loc.start);
      int written = snprintf(fleek_long_yield_list_buffer + fleek_long_yield_list_used,
        sizeof(fleek_long_yield_list_buffer) - fleek_long_yield_list_used,
        "%d\\t%.*s#%s%.*s\\t%zu\\n", line, (int) state->class_name_length, state->class_name, state->method->receiver == NULL ? "" : "self.",
        (int) method_name->length, method_name->start, count);
      if (written < 0 || (size_t) written >= sizeof(fleek_long_yield_list_buffer) - fleek_long_yield_list_used) { state->overflow = true; return false; }
      fleek_long_yield_list_used += (size_t) written;
      state->findings++;
      return false;
    }

    static int fleek_long_yield_list_method(pm_parser_t *parser, const uint8_t *source,
        const char *class_name, size_t class_name_length, const pm_node_t *node, void *data) {
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      fleek_long_yield_state_t state = { parser, source, class_name, class_name_length, method, *(size_t *) data, 0, false };
      if (method->receiver != NULL && !PM_NODE_TYPE_P(method->receiver, PM_SELF_NODE)) return -1;
      if (method->body != NULL) pm_visit_node(method->body, fleek_long_yield_visit, &state);
      if (state.overflow) return -1;
      return state.findings;
    }

    int fleek_long_yield_list(const char *source, size_t length, size_t maximum) {
      fleek_long_yield_list_buffer[0] = 0;
      fleek_long_yield_list_used = 0;
      return fleek_scan_method_scope(source, length, fleek_long_yield_list_method, &maximum);
    }

    const char *fleek_long_yield_list_finding(void) { return fleek_long_yield_list_buffer; }

    static bool fleek_constants_equal(pm_parser_t *parser, pm_constant_id_t left, pm_constant_id_t right);
    typedef struct { pm_parser_t *parser; pm_constant_id_t name; bool found; } fleek_name_search_t;
    static bool fleek_find_body_name(const pm_node_t *node, void *data) {
      fleek_name_search_t *search = (fleek_name_search_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE) || PM_NODE_TYPE_P(node, PM_BLOCK_NODE)) return false;
      pm_constant_id_t name = 0;
      if (PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_READ_NODE)) name = ((const pm_local_variable_read_node_t *) node)->name;
      if (PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_WRITE_NODE)) name = ((const pm_local_variable_write_node_t *) node)->name;
      if (name != 0 && fleek_constants_equal(search->parser, search->name, name)) { search->found = true; return false; }
      return true;
    }
    static bool fleek_body_uses_name(pm_parser_t *parser, const pm_node_t *body, pm_constant_id_t name) {
      if (body == NULL) return false;
      fleek_name_search_t search = { parser, name, false };
      pm_visit_node(body, fleek_find_body_name, &search);
      return search.found;
    }
    static bool fleek_find_implicit_super(const pm_node_t *node, void *data);
    static bool fleek_body_has_implicit_super(const pm_node_t *body) {
      if (body == NULL) return false;
      bool found = false;
      pm_visit_node(body, fleek_find_implicit_super, &found);
      return found;
    }
    static bool fleek_method_body_node_supported(const pm_node_t *node, void *data) {
      bool *supported = (bool *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      if (PM_NODE_TYPE_P(node, PM_BLOCK_NODE)) { *supported = false; return false; }
      if (PM_NODE_TYPE_P(node, PM_STATEMENTS_NODE) || PM_NODE_TYPE_P(node, PM_IF_NODE) || PM_NODE_TYPE_P(node, PM_UNLESS_NODE) ||
          PM_NODE_TYPE_P(node, PM_CASE_NODE) || PM_NODE_TYPE_P(node, PM_WHEN_NODE) || PM_NODE_TYPE_P(node, PM_ELSE_NODE) ||
          PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_READ_NODE) || PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_WRITE_NODE) ||
          PM_NODE_TYPE_P(node, PM_SUPER_NODE) || PM_NODE_TYPE_P(node, PM_CALL_NODE) || PM_NODE_TYPE_P(node, PM_ARGUMENTS_NODE) ||
          PM_NODE_TYPE_P(node, PM_ARRAY_NODE) || PM_NODE_TYPE_P(node, PM_STRING_NODE) || PM_NODE_TYPE_P(node, PM_SYMBOL_NODE) ||
          PM_NODE_TYPE_P(node, PM_INTEGER_NODE) || PM_NODE_TYPE_P(node, PM_TRUE_NODE) || PM_NODE_TYPE_P(node, PM_FALSE_NODE) ||
          PM_NODE_TYPE_P(node, PM_NIL_NODE) || PM_NODE_TYPE_P(node, PM_RETURN_NODE) || PM_NODE_TYPE_P(node, PM_AND_NODE) ||
          PM_NODE_TYPE_P(node, PM_OR_NODE) || PM_NODE_TYPE_P(node, PM_CONSTANT_READ_NODE) || PM_NODE_TYPE_P(node, PM_KEYWORD_HASH_NODE) ||
          PM_NODE_TYPE_P(node, PM_ASSOC_NODE) || PM_NODE_TYPE_P(node, PM_PARENTHESES_NODE) || PM_NODE_TYPE_P(node, PM_SELF_NODE) ||
          PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_READ_NODE) || PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_WRITE_NODE)) return true;
      *supported = false;
      return false;
    }
    static bool fleek_method_body_supported(const pm_node_t *body) {
      if (body == NULL) return true;
      bool supported = true;
      pm_visit_node(body, fleek_method_body_node_supported, &supported);
      return supported;
    }
    static bool fleek_find_implicit_super(const pm_node_t *node, void *data) {
      bool *found = (bool *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE) || PM_NODE_TYPE_P(node, PM_BLOCK_NODE)) return false;
      if (PM_NODE_TYPE_P(node, PM_SUPER_NODE) && ((const pm_super_node_t *) node)->arguments == NULL) { *found = true; return false; }
      return true;
    }
    typedef struct { pm_parser_t *parser; const pm_parameters_node_t *parameters; } fleek_method_parameters_t;
    static pm_constant_id_t fleek_parameter_name(const pm_node_t *parameter) {
      if (PM_NODE_TYPE_P(parameter, PM_REQUIRED_PARAMETER_NODE)) return ((const pm_required_parameter_node_t *) parameter)->name;
      if (PM_NODE_TYPE_P(parameter, PM_OPTIONAL_PARAMETER_NODE)) return ((const pm_optional_parameter_node_t *) parameter)->name;
      if (PM_NODE_TYPE_P(parameter, PM_REQUIRED_KEYWORD_PARAMETER_NODE)) return ((const pm_required_keyword_parameter_node_t *) parameter)->name;
      if (PM_NODE_TYPE_P(parameter, PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) return ((const pm_optional_keyword_parameter_node_t *) parameter)->name;
      return 0;
    }
    static bool fleek_name_in_parameters(pm_parser_t *parser, pm_constant_id_t name, const pm_parameters_node_t *parameters) {
      if (parameters == NULL) return false;
      const pm_node_list_t *lists[] = { &parameters->requireds, &parameters->optionals, &parameters->posts, &parameters->keywords };
      for (size_t list = 0; list < 4; list++) for (size_t index = 0; index < lists[list]->size; index++) {
        pm_constant_id_t candidate = fleek_parameter_name(lists[list]->nodes[index]);
        if (candidate != 0 && fleek_constants_equal(parser, candidate, name)) return true;
      }
      return false;
    }
    static bool fleek_control_condition(const pm_node_t *node, pm_constant_id_t name, pm_parser_t *parser, bool conditional) {
      if (node == NULL) return false;
      if (PM_NODE_TYPE_P(node, PM_IF_NODE)) {
        const pm_if_node_t *branch = (const pm_if_node_t *) node;
        return fleek_control_condition(branch->predicate, name, parser, true) || fleek_control_condition((const pm_node_t *) branch->statements, name, parser, conditional) || fleek_control_condition(branch->subsequent, name, parser, conditional);
      }
      if (PM_NODE_TYPE_P(node, PM_UNLESS_NODE)) {
        const pm_unless_node_t *branch = (const pm_unless_node_t *) node;
        return fleek_control_condition(branch->predicate, name, parser, true) || fleek_control_condition((const pm_node_t *) branch->statements, name, parser, conditional) || fleek_control_condition((const pm_node_t *) branch->else_clause, name, parser, conditional);
      }
      if (PM_NODE_TYPE_P(node, PM_CASE_NODE)) {
        const pm_case_node_t *branch = (const pm_case_node_t *) node;
        if (fleek_control_condition(branch->predicate, name, parser, true)) return true;
        for (size_t index = 0; index < branch->conditions.size; index++) if (fleek_control_condition(branch->conditions.nodes[index], name, parser, true)) return true;
        return fleek_control_condition((const pm_node_t *) branch->else_clause, name, parser, conditional);
      }
      if (PM_NODE_TYPE_P(node, PM_WHEN_NODE)) {
        const pm_when_node_t *branch = (const pm_when_node_t *) node;
        for (size_t index = 0; index < branch->conditions.size; index++) if (fleek_control_condition(branch->conditions.nodes[index], name, parser, true)) return true;
        return fleek_control_condition((const pm_node_t *) branch->statements, name, parser, conditional);
      }
      if (PM_NODE_TYPE_P(node, PM_ELSE_NODE)) return fleek_control_condition((const pm_node_t *) ((const pm_else_node_t *) node)->statements, name, parser, conditional);
      if (PM_NODE_TYPE_P(node, PM_STATEMENTS_NODE)) {
        const pm_statements_node_t *items = (const pm_statements_node_t *) node;
        for (size_t index = 0; index < items->body.size; index++) if (fleek_control_condition(items->body.nodes[index], name, parser, conditional)) return true;
        return false;
      }
      if (PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_READ_NODE)) return conditional && fleek_constants_equal(parser, ((const pm_local_variable_read_node_t *) node)->name, name);
      if (PM_NODE_TYPE_P(node, PM_AND_NODE)) {
        const pm_and_node_t *logical = (const pm_and_node_t *) node;
        return fleek_control_condition(logical->left, name, parser, true) || fleek_control_condition(logical->right, name, parser, true);
      }
      if (PM_NODE_TYPE_P(node, PM_OR_NODE)) {
        const pm_or_node_t *logical = (const pm_or_node_t *) node;
        return fleek_control_condition(logical->left, name, parser, true) || fleek_control_condition(logical->right, name, parser, true);
      }
      if (PM_NODE_TYPE_P(node, PM_CALL_NODE)) {
        const pm_call_node_t *call = (const pm_call_node_t *) node;
        if (!conditional) return false;
        return fleek_body_uses_name(parser, call->receiver, name) || fleek_body_uses_name(parser, (const pm_node_t *) call->arguments, name);
      }
      return false;
    }
    static bool fleek_record_control_line(const uint8_t *source, const pm_node_t *node, int *lines, size_t *count) {
      int line = fleek_source_line(source, node->location.start);
      for (size_t index = 0; index < *count; index++) if (lines[index] == line) return true;
      if (*count >= 128) return false;
      lines[(*count)++] = line;
      return true;
    }
    static bool fleek_control_condition_lines(const pm_node_t *node, pm_constant_id_t name, pm_parser_t *parser,
        const uint8_t *source, int *lines, size_t *count) {
      if (node == NULL) return true;
      if (PM_NODE_TYPE_P(node, PM_IF_NODE)) {
        const pm_if_node_t *branch = (const pm_if_node_t *) node;
        if (fleek_control_condition(branch->predicate, name, parser, true) && !fleek_record_control_line(source, (const pm_node_t *) branch->predicate, lines, count)) return false;
        return fleek_control_condition_lines((const pm_node_t *) branch->statements, name, parser, source, lines, count) &&
          fleek_control_condition_lines(branch->subsequent, name, parser, source, lines, count);
      }
      if (PM_NODE_TYPE_P(node, PM_UNLESS_NODE)) {
        const pm_unless_node_t *branch = (const pm_unless_node_t *) node;
        if (fleek_control_condition(branch->predicate, name, parser, true) && !fleek_record_control_line(source, (const pm_node_t *) branch->predicate, lines, count)) return false;
        return fleek_control_condition_lines((const pm_node_t *) branch->statements, name, parser, source, lines, count) &&
          fleek_control_condition_lines((const pm_node_t *) branch->else_clause, name, parser, source, lines, count);
      }
      if (PM_NODE_TYPE_P(node, PM_CASE_NODE)) {
        const pm_case_node_t *branch = (const pm_case_node_t *) node;
        if (fleek_control_condition(branch->predicate, name, parser, true) && !fleek_record_control_line(source, (const pm_node_t *) branch->predicate, lines, count)) return false;
        for (size_t index = 0; index < branch->conditions.size; index++) {
          const pm_node_t *condition = branch->conditions.nodes[index];
          if (fleek_control_condition(condition, name, parser, true) && !fleek_record_control_line(source, condition, lines, count)) return false;
        }
        return fleek_control_condition_lines((const pm_node_t *) branch->else_clause, name, parser, source, lines, count);
      }
      if (PM_NODE_TYPE_P(node, PM_WHEN_NODE)) {
        const pm_when_node_t *branch = (const pm_when_node_t *) node;
        for (size_t index = 0; index < branch->conditions.size; index++) {
          const pm_node_t *condition = branch->conditions.nodes[index];
          if (fleek_control_condition(condition, name, parser, true) && !fleek_record_control_line(source, condition, lines, count)) return false;
        }
        return fleek_control_condition_lines((const pm_node_t *) branch->statements, name, parser, source, lines, count);
      }
      if (PM_NODE_TYPE_P(node, PM_ELSE_NODE)) return fleek_control_condition_lines((const pm_node_t *) ((const pm_else_node_t *) node)->statements, name, parser, source, lines, count);
      if (PM_NODE_TYPE_P(node, PM_STATEMENTS_NODE)) {
        const pm_statements_node_t *items = (const pm_statements_node_t *) node;
        for (size_t index = 0; index < items->body.size; index++) if (!fleek_control_condition_lines(items->body.nodes[index], name, parser, source, lines, count)) return false;
        return true;
      }
      if ((PM_NODE_TYPE_P(node, PM_AND_NODE) || PM_NODE_TYPE_P(node, PM_OR_NODE)) &&
          fleek_control_condition(node, name, parser, true)) return fleek_record_control_line(source, node, lines, count);
      return true;
    }
    static bool fleek_parameter_used_outside_condition(pm_parser_t *parser, const pm_node_t *node, pm_constant_id_t name) {
      if (node == NULL) return false;
      if (PM_NODE_TYPE_P(node, PM_IF_NODE)) {
        const pm_if_node_t *branch = (const pm_if_node_t *) node;
        return fleek_parameter_used_outside_condition(parser, (const pm_node_t *) branch->statements, name) || fleek_parameter_used_outside_condition(parser, branch->subsequent, name);
      }
      if (PM_NODE_TYPE_P(node, PM_UNLESS_NODE)) {
        const pm_unless_node_t *branch = (const pm_unless_node_t *) node;
        return fleek_parameter_used_outside_condition(parser, (const pm_node_t *) branch->statements, name) || fleek_parameter_used_outside_condition(parser, (const pm_node_t *) branch->else_clause, name);
      }
      if (PM_NODE_TYPE_P(node, PM_CASE_NODE)) {
        const pm_case_node_t *branch = (const pm_case_node_t *) node;
        return fleek_parameter_used_outside_condition(parser, (const pm_node_t *) branch->else_clause, name);
      }
      if (PM_NODE_TYPE_P(node, PM_AND_NODE)) {
        return false;
      }
      if (PM_NODE_TYPE_P(node, PM_OR_NODE)) {
        return false;
      }
      if (PM_NODE_TYPE_P(node, PM_WHEN_NODE)) return fleek_parameter_used_outside_condition(parser, (const pm_node_t *) ((const pm_when_node_t *) node)->statements, name);
      if (PM_NODE_TYPE_P(node, PM_ELSE_NODE)) return fleek_parameter_used_outside_condition(parser, (const pm_node_t *) ((const pm_else_node_t *) node)->statements, name);
      if (PM_NODE_TYPE_P(node, PM_STATEMENTS_NODE)) {
        const pm_statements_node_t *items = (const pm_statements_node_t *) node;
        for (size_t index = 0; index < items->body.size; index++) if (fleek_parameter_used_outside_condition(parser, items->body.nodes[index], name)) return true;
        return false;
      }
      return fleek_body_uses_name(parser, node, name);
    }
    static bool fleek_any_parameter_used(pm_parser_t *parser, const pm_node_t *body, const pm_parameters_node_t *parameters) {
      if (parameters == NULL) return false;
      const pm_node_list_t *lists[] = { &parameters->requireds, &parameters->optionals, &parameters->posts, &parameters->keywords };
      for (size_t list = 0; list < 4; list++) for (size_t index = 0; index < lists[list]->size; index++) {
        pm_constant_id_t name = fleek_parameter_name(lists[list]->nodes[index]);
        if (name != 0 && fleek_body_uses_name(parser, body, name)) return true;
      }
      return false;
    }
    static int fleek_method_api_method(pm_parser_t *parser, const uint8_t *source, const char *class_name,
        size_t class_name_length, const pm_node_t *node, void *data) {
      (void) data;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->receiver != NULL) return -1;
      if (!fleek_method_body_supported(method->body)) return -1;
      if (method->parameters == NULL) return 0;
      if (!PM_NODE_TYPE_P((const pm_node_t *) method->parameters, PM_PARAMETERS_NODE)) return -1;
      const pm_parameters_node_t *parameters = method->parameters;
      if (parameters->rest != NULL || parameters->keyword_rest != NULL || parameters->block != NULL) return -1;
      pm_constant_t *method_name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      int line = fleek_source_line(source, method->def_keyword_loc.start);
      int findings = 0;
      for (size_t list = 0; list < 4; list++) {
        const pm_node_list_t *items = list == 0 ? &parameters->requireds : list == 1 ? &parameters->optionals : list == 2 ? &parameters->posts : &parameters->keywords;
        for (size_t index = 0; index < items->size; index++) {
          const pm_node_t *parameter = items->nodes[index];
          pm_constant_id_t name_id = fleek_parameter_name(parameter);
          if (name_id == 0) return -1;
          bool unused = !fleek_body_uses_name(parser, method->body, name_id);
          if (!unused || fleek_body_has_implicit_super(method->body)) continue;
          pm_constant_t *name = pm_constant_pool_id_to_constant(&parser->constant_pool, name_id);
          int written = snprintf(fleek_unused_parameters_buffer + fleek_unused_parameters_used,
            sizeof(fleek_unused_parameters_buffer) - fleek_unused_parameters_used,
            "%d\\t%.*s#%.*s\\t%.*s\\n", line, (int) class_name_length, class_name,
            (int) method_name->length, method_name->start, (int) name->length, name->start);
          if (written < 0 || (size_t) written >= sizeof(fleek_unused_parameters_buffer) - fleek_unused_parameters_used) return -1;
          fleek_unused_parameters_used += (size_t) written;
          findings++;
        }
      }
      bool has_control = false;
      for (size_t list = 0; list < 4; list++) {
        const pm_node_list_t *items = list == 0 ? &parameters->requireds : list == 1 ? &parameters->optionals : list == 2 ? &parameters->posts : &parameters->keywords;
        for (size_t index = 0; index < items->size; index++) {
          pm_constant_id_t name_id = fleek_parameter_name(items->nodes[index]);
          if (name_id == 0) return -1;
          int control_lines[128] = { 0 };
          size_t control_line_count = 0;
          if (!fleek_control_condition_lines(method->body, name_id, parser, source, control_lines, &control_line_count)) return -1;
          if (control_line_count > 0 && !fleek_parameter_used_outside_condition(parser, method->body, name_id)) {
            char line_list[512] = { 0 };
            size_t line_used = 0;
            for (size_t line_index = 0; line_index < control_line_count; line_index++) {
              int line_written = snprintf(line_list + line_used, sizeof(line_list) - line_used, "%s%d", line_index == 0 ? "" : ", ", control_lines[line_index]);
              if (line_written < 0 || (size_t) line_written >= sizeof(line_list) - line_used) return -1;
              line_used += (size_t) line_written;
            }
            pm_constant_t *name = pm_constant_pool_id_to_constant(&parser->constant_pool, name_id);
            int written = snprintf(fleek_control_parameter_buffer + fleek_control_parameter_used,
              sizeof(fleek_control_parameter_buffer) - fleek_control_parameter_used,
              "%s\\t%.*s#%.*s\\t%.*s\\n", line_list, (int) class_name_length, class_name,
              (int) method_name->length, method_name->start, (int) name->length, name->start);
            if (written < 0 || (size_t) written >= sizeof(fleek_control_parameter_buffer) - fleek_control_parameter_used) return -1;
            fleek_control_parameter_used += (size_t) written;
            findings++;
            has_control = true;
          }
        }
      }
      (void) has_control;
      return findings;
    }
    int fleek_control_parameter(const char *source, size_t length) {
      fleek_control_parameter_buffer[0] = 0; fleek_control_parameter_used = 0;
      return fleek_scan_method_scope(source, length, fleek_method_api_method, NULL);
    }
    const char *fleek_control_parameter_finding(void) { return fleek_control_parameter_buffer; }
    int fleek_unused_parameters(const char *source, size_t length) {
      fleek_unused_parameters_buffer[0] = 0; fleek_unused_parameters_used = 0;
      return fleek_scan_method_scope(source, length, fleek_method_api_method, NULL);
    }
    const char *fleek_unused_parameters_finding(void) { return fleek_unused_parameters_buffer; }
    typedef struct { bool has_send; bool uses_self; } fleek_utility_state_t;
    static bool fleek_utility_visit(const pm_node_t *node, void *data) {
      fleek_utility_state_t *state = (fleek_utility_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE) || PM_NODE_TYPE_P(node, PM_BLOCK_NODE)) return false;
      if (PM_NODE_TYPE_P(node, PM_CALL_NODE)) {
        const pm_call_node_t *call = (const pm_call_node_t *) node;
        state->has_send = true;
        if (call->receiver == NULL) state->uses_self = true;
      }
      if (PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_READ_NODE) || PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_WRITE_NODE) || PM_NODE_TYPE_P(node, PM_SELF_NODE)) state->uses_self = true;
      return true;
    }
    static int fleek_utility_function_method(pm_parser_t *parser, const uint8_t *source, const char *class_name,
        size_t class_name_length, const pm_node_t *node, void *data) {
      (void) data;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->body == NULL) return 0;
      if (!fleek_method_body_supported(method->body)) return -1;
      fleek_utility_state_t state = { false, false };
      pm_visit_node(method->body, fleek_utility_visit, &state);
      if (!state.has_send || state.uses_self) return 0;
      pm_constant_t *name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      int written = snprintf(fleek_utility_function_buffer + fleek_utility_function_used,
        sizeof(fleek_utility_function_buffer) - fleek_utility_function_used,
        "%d\\t%.*s#%.*s\\t\\n", fleek_source_line(source, method->def_keyword_loc.start),
        (int) class_name_length, class_name, (int) name->length, name->start);
      if (written < 0 || (size_t) written >= sizeof(fleek_utility_function_buffer) - fleek_utility_function_used) return -1;
      fleek_utility_function_used += (size_t) written;
      return 1;
    }
    int fleek_utility_function(const char *source, size_t length) {
      fleek_utility_function_buffer[0] = 0; fleek_utility_function_used = 0;
      return fleek_scan_method_scope(source, length, fleek_utility_function_method, NULL);
    }
    const char *fleek_utility_function_finding(void) { return fleek_utility_function_buffer; }
    typedef struct { const uint8_t *start; size_t length; } fleek_duplicate_call_t;
    typedef struct { fleek_duplicate_call_t calls[128]; size_t count; bool unsupported; const char *allow_calls; } fleek_duplicate_calls_t;
    typedef struct { size_t maximum; const char *allow_calls; } fleek_duplicate_options_t;
    static bool fleek_collect_duplicate_calls(const pm_node_t *node, void *data) {
      fleek_duplicate_calls_t *calls = (fleek_duplicate_calls_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      if (PM_NODE_TYPE_P(node, PM_BLOCK_NODE)) { calls->unsupported = true; return false; }
      if (!PM_NODE_TYPE_P(node, PM_CALL_NODE)) return true;
      const pm_call_node_t *call = (const pm_call_node_t *) node;
      if (call->receiver == NULL && (call->arguments == NULL || call->arguments->arguments.size == 0) && call->block == NULL) return true;
      size_t call_length = (size_t) (call->base.location.end - call->base.location.start);
      if (fleek_matches_any_pattern(call->base.location.start, call_length, calls->allow_calls)) return true;
      if (calls->count >= 128) { calls->unsupported = true; return false; }
      calls->calls[calls->count].start = call->base.location.start;
      calls->calls[calls->count].length = (size_t) (call->base.location.end - call->base.location.start);
      calls->count++;
      return true;
    }
    static int fleek_duplicate_method_call_method(pm_parser_t *parser, const uint8_t *source, const char *class_name,
        size_t class_name_length, const pm_node_t *node, void *data) {
      fleek_duplicate_options_t *options = (fleek_duplicate_options_t *) data;
      size_t maximum = options->maximum;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->body == NULL) return 0;
      if (!fleek_method_body_supported(method->body)) return -1;
      fleek_duplicate_calls_t calls = { 0 };
      calls.allow_calls = options->allow_calls;
      pm_visit_node(method->body, fleek_collect_duplicate_calls, &calls);
      if (calls.unsupported) return -1;
      pm_constant_t *method_name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      int findings = 0;
      for (size_t index = 0; index < calls.count; index++) {
        bool already_written = false;
        size_t count = 0;
        size_t used = 0;
        char lines[256] = { 0 };
        for (size_t earlier = 0; earlier < index; earlier++) {
          if (calls.calls[index].length == calls.calls[earlier].length &&
              memcmp(calls.calls[index].start, calls.calls[earlier].start, calls.calls[index].length) == 0) already_written = true;
        }
        if (already_written) continue;
        for (size_t candidate = index; candidate < calls.count; candidate++) {
          if (calls.calls[index].length != calls.calls[candidate].length ||
              memcmp(calls.calls[index].start, calls.calls[candidate].start, calls.calls[index].length) != 0) continue;
          int line = fleek_source_line(source, calls.calls[candidate].start);
          int written = snprintf(lines + used, sizeof(lines) - used, "%s%d", count == 0 ? "" : ", ", line);
          if (written < 0 || (size_t) written >= sizeof(lines) - used) return -1;
          used += (size_t) written;
          count++;
        }
        if (count <= maximum) continue;
        int written = snprintf(fleek_duplicate_method_call_buffer + fleek_duplicate_method_call_used,
          sizeof(fleek_duplicate_method_call_buffer) - fleek_duplicate_method_call_used,
          "%s\\t%.*s#%.*s\\t%.*s\\t%zu\\n", lines, (int) class_name_length, class_name,
          (int) method_name->length, method_name->start, (int) calls.calls[index].length,
          calls.calls[index].start, count);
        if (written < 0 || (size_t) written >= sizeof(fleek_duplicate_method_call_buffer) - fleek_duplicate_method_call_used) return -1;
        fleek_duplicate_method_call_used += (size_t) written;
        findings++;
      }
      return findings;
    }
    int fleek_duplicate_method_call(const char *source, size_t length, size_t maximum, const char *allow_calls) {
      fleek_duplicate_method_call_buffer[0] = 0; fleek_duplicate_method_call_used = 0;
      fleek_duplicate_options_t options = { maximum, allow_calls };
      return fleek_scan_method_scope(source, length, fleek_duplicate_method_call_method, &options);
    }
    const char *fleek_duplicate_method_call_finding(void) { return fleek_duplicate_method_call_buffer; }
    typedef struct { pm_parser_t *parser; const uint8_t *source; int lines[128]; size_t count; bool overflow; } fleek_manual_dispatch_state_t;
    static bool fleek_manual_dispatch_visit(const pm_node_t *node, void *data) {
      fleek_manual_dispatch_state_t *state = (fleek_manual_dispatch_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      if (!PM_NODE_TYPE_P(node, PM_CALL_NODE)) return true;
      const pm_call_node_t *call = (const pm_call_node_t *) node;
      if (!fleek_name_is(state->parser, call->name, "respond_to?")) return true;
      int line = fleek_source_line(state->source, call->base.location.start);
      for (size_t index = 0; index < state->count; index++) if (state->lines[index] == line) return true;
      if (state->count >= 128) { state->overflow = true; return false; }
      state->lines[state->count++] = line;
      return true;
    }
    static int fleek_manual_dispatch_method(pm_parser_t *parser, const uint8_t *source, const char *class_name,
        size_t class_name_length, const pm_node_t *node, void *data) {
      (void) data;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->receiver != NULL || method->body == NULL) return 0;
      if (!fleek_method_body_supported(method->body)) return -1;
      fleek_manual_dispatch_state_t state = { parser, source, { 0 }, 0, false };
      pm_visit_node(method->body, fleek_manual_dispatch_visit, &state);
      if (state.overflow) return -1;
      if (state.count == 0) return 0;
      char lines[512] = { 0 };
      size_t used = 0;
      for (size_t index = 0; index < state.count; index++) {
        int written = snprintf(lines + used, sizeof(lines) - used, "%s%d", index == 0 ? "" : ", ", state.lines[index]);
        if (written < 0 || (size_t) written >= sizeof(lines) - used) return -1;
        used += (size_t) written;
      }
      pm_constant_t *method_name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      int written = snprintf(fleek_manual_dispatch_buffer + fleek_manual_dispatch_used, sizeof(fleek_manual_dispatch_buffer) - fleek_manual_dispatch_used, "%s\\t%.*s#%.*s\\t\\n",
        lines, (int) class_name_length, class_name, (int) method_name->length, method_name->start);
      if (written < 0 || (size_t) written >= sizeof(fleek_manual_dispatch_buffer) - fleek_manual_dispatch_used) return -1;
      fleek_manual_dispatch_used += (size_t) written;
      return 1;
    }
    int fleek_manual_dispatch(const char *source, size_t length) {
      fleek_manual_dispatch_buffer[0] = 0; fleek_manual_dispatch_used = 0;
      return fleek_scan_method_scope(source, length, fleek_manual_dispatch_method, NULL);
    }
    const char *fleek_manual_dispatch_finding(void) { return fleek_manual_dispatch_buffer; }
    typedef struct { pm_parser_t *parser; const uint8_t *source; int lines[128]; size_t count; bool overflow; } fleek_nil_check_state_t;
    static bool fleek_nil_check_add(fleek_nil_check_state_t *state, const uint8_t *location) {
      int line = fleek_source_line(state->source, location);
      for (size_t index = 0; index < state->count; index++) if (state->lines[index] == line) return true;
      if (state->count >= 128) { state->overflow = true; return false; }
      state->lines[state->count++] = line;
      return true;
    }
    static bool fleek_nil_check_visit(const pm_node_t *node, void *data) {
      fleek_nil_check_state_t *state = (fleek_nil_check_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      if (PM_NODE_TYPE_P(node, PM_CALL_NODE)) {
        const pm_call_node_t *call = (const pm_call_node_t *) node;
        bool nil_call = fleek_name_is(state->parser, call->name, "nil?");
        bool comparison = fleek_name_is(state->parser, call->name, "==") || fleek_name_is(state->parser, call->name, "===");
        bool has_nil = call->receiver != NULL && PM_NODE_TYPE_P(call->receiver, PM_NIL_NODE);
        if (call->arguments != NULL) for (size_t index = 0; index < call->arguments->arguments.size; index++) {
          if (PM_NODE_TYPE_P(call->arguments->arguments.nodes[index], PM_NIL_NODE)) has_nil = true;
        }
        if (nil_call || (comparison && has_nil)) return fleek_nil_check_add(state, call->base.location.start);
      }
      if (PM_NODE_TYPE_P(node, PM_WHEN_NODE)) {
        const pm_when_node_t *branch = (const pm_when_node_t *) node;
        for (size_t index = 0; index < branch->conditions.size; index++) {
          if (PM_NODE_TYPE_P(branch->conditions.nodes[index], PM_NIL_NODE) && !fleek_nil_check_add(state, branch->conditions.nodes[index]->location.start)) return false;
        }
      }
      return !state->overflow;
    }
    static int fleek_nil_check_method(pm_parser_t *parser, const uint8_t *source, const char *class_name,
        size_t class_name_length, const pm_node_t *node, void *data) {
      (void) data;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->receiver != NULL || method->body == NULL) return 0;
      if (!fleek_method_body_supported(method->body)) return -1;
      fleek_nil_check_state_t state = { parser, source, { 0 }, 0, false };
      pm_visit_node(method->body, fleek_nil_check_visit, &state);
      if (state.overflow) return -1;
      if (state.count == 0) return 0;
      char lines[512] = { 0 };
      size_t used = 0;
      for (size_t index = 0; index < state.count; index++) {
        int written = snprintf(lines + used, sizeof(lines) - used, "%s%d", index == 0 ? "" : ", ", state.lines[index]);
        if (written < 0 || (size_t) written >= sizeof(lines) - used) return -1;
        used += (size_t) written;
      }
      pm_constant_t *method_name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      int written = snprintf(fleek_nil_check_buffer + fleek_nil_check_used, sizeof(fleek_nil_check_buffer) - fleek_nil_check_used,
        "%s\\t%.*s#%.*s\\t\\n", lines, (int) class_name_length, class_name, (int) method_name->length, method_name->start);
      if (written < 0 || (size_t) written >= sizeof(fleek_nil_check_buffer) - fleek_nil_check_used) return -1;
      fleek_nil_check_used += (size_t) written;
      return 1;
    }
    int fleek_nil_check(const char *source, size_t length) {
      fleek_nil_check_buffer[0] = 0; fleek_nil_check_used = 0;
      return fleek_scan_method_scope(source, length, fleek_nil_check_method, NULL);
    }
    const char *fleek_nil_check_finding(void) { return fleek_nil_check_buffer; }
    static bool fleek_missing_safe_version_exists(pm_parser_t *parser, const pm_def_node_t *method, const pm_constant_t *name) {
      if (fleek_only_scope == NULL || name->length < 2 || name->start[name->length - 1] != '!') return false;
      const pm_node_t *body = PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE) ?
        ((const pm_class_node_t *) fleek_only_scope)->body : ((const pm_module_node_t *) fleek_only_scope)->body;
      if (!PM_NODE_TYPE_P(body, PM_STATEMENTS_NODE)) return false;
      const pm_statements_node_t *statements = (const pm_statements_node_t *) body;
      for (size_t index = 0; index < statements->body.size; index++) {
        const pm_node_t *candidate_node = statements->body.nodes[index];
        if (!PM_NODE_TYPE_P(candidate_node, PM_DEF_NODE)) continue;
        const pm_def_node_t *candidate = (const pm_def_node_t *) candidate_node;
        pm_constant_t *candidate_name = pm_constant_pool_id_to_constant(&parser->constant_pool, candidate->name);
        if (candidate_name->length == name->length - 1 && memcmp(candidate_name->start, name->start, candidate_name->length) == 0) return true;
      }
      (void) method;
      return false;
    }
    static int fleek_missing_safe_method_method(pm_parser_t *parser, const uint8_t *source, const char *class_name,
        size_t class_name_length, const pm_node_t *node, void *data) {
      (void) data;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->receiver != NULL || fleek_only_scope == NULL) return 0;
      pm_constant_t *name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      if (!fleek_missing_safe_version_exists(parser, method, name)) {
        if (name->length < 2 || name->start[name->length - 1] != '!') return 0;
        int written = snprintf(fleek_missing_safe_method_buffer + fleek_missing_safe_method_used,
          sizeof(fleek_missing_safe_method_buffer) - fleek_missing_safe_method_used,
          "%d\\t%.*s\\t%.*s\\n", fleek_source_line(source, method->def_keyword_loc.start),
          (int) class_name_length, class_name, (int) name->length, name->start);
        if (written < 0 || (size_t) written >= sizeof(fleek_missing_safe_method_buffer) - fleek_missing_safe_method_used) return -1;
        fleek_missing_safe_method_used += (size_t) written;
        return 1;
      }
      return 0;
    }
    int fleek_missing_safe_method(const char *source, size_t length) {
      fleek_missing_safe_method_buffer[0] = 0; fleek_missing_safe_method_used = 0;
      return fleek_scan_method_scope(source, length, fleek_missing_safe_method_method, NULL);
    }
    const char *fleek_missing_safe_method_finding(void) { return fleek_missing_safe_method_buffer; }
    typedef struct { const uint8_t *expression; size_t length; int lines[64]; size_t count; } fleek_conditional_group_t;
    typedef struct { pm_parser_t *parser; const uint8_t *source; const char *class_name; size_t class_name_length; size_t maximum; fleek_conditional_group_t groups[128]; size_t count; bool unsupported; } fleek_repeated_conditional_state_t;
    static bool fleek_conditional_is_block_given(pm_parser_t *parser, const pm_node_t *condition) {
      if (!PM_NODE_TYPE_P(condition, PM_CALL_NODE)) return false;
      const pm_call_node_t *call = (const pm_call_node_t *) condition;
      return call->receiver == NULL && call->arguments == NULL && fleek_name_is(parser, call->name, "block_given?");
    }
    static bool fleek_record_conditional(fleek_repeated_conditional_state_t *state, pm_parser_t *parser, const pm_node_t *condition) {
      if (condition == NULL || fleek_conditional_is_block_given(parser, condition)) return true;
      size_t length = (size_t) (condition->location.end - condition->location.start);
      size_t group = 0;
      while (group < state->count && (state->groups[group].length != length || memcmp(state->groups[group].expression, condition->location.start, length) != 0)) group++;
      if (group == state->count) {
        if (state->count >= 128) { state->unsupported = true; return false; }
        state->groups[group].expression = condition->location.start;
        state->groups[group].length = length;
        state->groups[group].count = 0;
        state->count++;
      }
      fleek_conditional_group_t *entry = &state->groups[group];
      if (entry->count >= 64) { state->unsupported = true; return false; }
      entry->lines[entry->count++] = fleek_source_line(state->source, condition->location.start);
      return true;
    }
    static bool fleek_collect_repeated_conditionals_with_parser(const pm_node_t *node, void *data) {
      fleek_repeated_conditional_state_t *state = (fleek_repeated_conditional_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      if (PM_NODE_TYPE_P(node, PM_IF_NODE)) return fleek_record_conditional(state, state->parser, ((const pm_if_node_t *) node)->predicate);
      if (PM_NODE_TYPE_P(node, PM_CASE_NODE)) return fleek_record_conditional(state, state->parser, ((const pm_case_node_t *) node)->predicate);
      return true;
    }
    static bool fleek_repeated_conditional_last_method(const pm_def_node_t *method) {
      const pm_node_t *body = PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE) ?
        ((const pm_class_node_t *) fleek_only_scope)->body : ((const pm_module_node_t *) fleek_only_scope)->body;
      if (!PM_NODE_TYPE_P(body, PM_STATEMENTS_NODE)) return false;
      const pm_statements_node_t *statements = (const pm_statements_node_t *) body;
      for (size_t index = statements->body.size; index > 0; index--) if (PM_NODE_TYPE_P(statements->body.nodes[index - 1], PM_DEF_NODE)) return statements->body.nodes[index - 1] == (const pm_node_t *) method;
      return false;
    }
    static int fleek_repeated_conditional_method(pm_parser_t *parser, const uint8_t *source, const char *class_name,
        size_t class_name_length, const pm_node_t *node, void *data) {
      fleek_repeated_conditional_state_t *state = (fleek_repeated_conditional_state_t *) data;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (fleek_only_scope == NULL) return 0;
      state->parser = parser;
      state->source = source; state->class_name = class_name; state->class_name_length = class_name_length;
      if (!fleek_method_body_supported(method->body)) return -1;
      if (method->body != NULL) pm_visit_node(method->body, fleek_collect_repeated_conditionals_with_parser, state);
      if (state->unsupported) return -1;
      if (!fleek_repeated_conditional_last_method(method)) return 0;
      int findings = 0;
      for (size_t group = 0; group < state->count; group++) {
        fleek_conditional_group_t *entry = &state->groups[group];
        if (entry->count <= state->maximum) continue;
        char lines[512] = { 0 };
        size_t line_used = 0;
        for (size_t index = 0; index < entry->count; index++) {
          int line_written = snprintf(lines + line_used, sizeof(lines) - line_used, "%s%d", index == 0 ? "" : ", ", entry->lines[index]);
          if (line_written < 0 || (size_t) line_written >= sizeof(lines) - line_used) return -1;
          line_used += (size_t) line_written;
        }
        int written = snprintf(fleek_repeated_conditional_buffer + fleek_repeated_conditional_used,
          sizeof(fleek_repeated_conditional_buffer) - fleek_repeated_conditional_used,
          "%s\\t%.*s\\t%.*s\\t%zu\\n", lines, (int) state->class_name_length, state->class_name,
          (int) entry->length, entry->expression, entry->count);
        if (written < 0 || (size_t) written >= sizeof(fleek_repeated_conditional_buffer) - fleek_repeated_conditional_used) return -1;
        fleek_repeated_conditional_used += (size_t) written;
        findings++;
      }
      return findings;
    }
    int fleek_repeated_conditional(const char *source, size_t length, size_t maximum) {
      fleek_repeated_conditional_buffer[0] = 0; fleek_repeated_conditional_used = 0;
      fleek_repeated_conditional_state_t state = { 0 };
      state.source = (const uint8_t *) source;
      state.maximum = maximum;
      return fleek_scan_method_scope(source, length, fleek_repeated_conditional_method, &state);
    }
    const char *fleek_repeated_conditional_finding(void) { return fleek_repeated_conditional_buffer; }
    typedef struct { const uint8_t *start; const uint8_t *end; int line; bool increments; size_t depth; } fleek_iterator_block_t;
    typedef struct { pm_parser_t *parser; const uint8_t *source; const char *ignore_iterators; size_t maximum; fleek_iterator_block_t blocks[128]; size_t count; bool unsupported; } fleek_nested_iterator_state_t;
    static bool fleek_nested_iterator_node_supported(const pm_node_t *node, void *data) {
      bool *supported = (bool *) data;
      if (PM_NODE_TYPE_P(node, PM_BLOCK_NODE)) return true;
      if (PM_NODE_TYPE_P(node, PM_BLOCK_PARAMETERS_NODE)) return true;
      if (PM_NODE_TYPE_P(node, PM_STATEMENTS_NODE) || PM_NODE_TYPE_P(node, PM_CALL_NODE) ||
          PM_NODE_TYPE_P(node, PM_ARGUMENTS_NODE) || PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_READ_NODE) ||
          PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_WRITE_NODE) || PM_NODE_TYPE_P(node, PM_PARAMETERS_NODE) ||
          PM_NODE_TYPE_P(node, PM_REQUIRED_PARAMETER_NODE) || PM_NODE_TYPE_P(node, PM_OPTIONAL_PARAMETER_NODE) ||
          PM_NODE_TYPE_P(node, PM_REQUIRED_KEYWORD_PARAMETER_NODE) || PM_NODE_TYPE_P(node, PM_OPTIONAL_KEYWORD_PARAMETER_NODE) ||
          PM_NODE_TYPE_P(node, PM_REST_PARAMETER_NODE) || PM_NODE_TYPE_P(node, PM_KEYWORD_REST_PARAMETER_NODE) ||
          PM_NODE_TYPE_P(node, PM_ARRAY_NODE) || PM_NODE_TYPE_P(node, PM_STRING_NODE) || PM_NODE_TYPE_P(node, PM_SYMBOL_NODE) ||
          PM_NODE_TYPE_P(node, PM_INTEGER_NODE) || PM_NODE_TYPE_P(node, PM_TRUE_NODE) || PM_NODE_TYPE_P(node, PM_FALSE_NODE) ||
          PM_NODE_TYPE_P(node, PM_NIL_NODE) || PM_NODE_TYPE_P(node, PM_CONSTANT_READ_NODE) || PM_NODE_TYPE_P(node, PM_SELF_NODE)) return true;
      *supported = false;
      return false;
    }
    static bool fleek_nested_iterator_visit(const pm_node_t *node, void *data) {
      fleek_nested_iterator_state_t *state = (fleek_nested_iterator_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      if (!PM_NODE_TYPE_P(node, PM_CALL_NODE)) return true;
      const pm_call_node_t *call = (const pm_call_node_t *) node;
      if (call->block == NULL) return true;
      if (state->count >= 128) { state->unsupported = true; return false; }
      const pm_block_node_t *block = (const pm_block_node_t *) call->block;
      bool has_arguments = false;
      if (PM_NODE_TYPE_P((const pm_node_t *) block->parameters, PM_BLOCK_PARAMETERS_NODE)) {
        const pm_block_parameters_node_t *parameters = (const pm_block_parameters_node_t *) block->parameters;
        if (parameters->parameters != NULL) {
          const pm_parameters_node_t *list = (const pm_parameters_node_t *) parameters->parameters;
          has_arguments = list->requireds.size + list->optionals.size + list->posts.size + list->keywords.size +
            (list->rest != NULL) + (list->keyword_rest != NULL) > 0;
        }
      }
      size_t call_length = (size_t) (call->base.location.end - call->base.location.start);
      bool ignored = fleek_matches_any_pattern(call->base.location.start, call_length, state->ignore_iterators);
      fleek_iterator_block_t *entry = &state->blocks[state->count++];
      entry->start = block->base.location.start;
      entry->end = block->base.location.end;
      entry->line = fleek_source_line(state->source, call->base.location.start);
      entry->increments = has_arguments && !ignored;
      entry->depth = 0;
      return true;
    }
    static bool fleek_nested_iterator_body_supported(const pm_node_t *body) {
      if (body == NULL) return true;
      bool supported = true;
      pm_visit_node(body, fleek_nested_iterator_node_supported, &supported);
      return supported;
    }
    static int fleek_nested_iterator_method(pm_parser_t *parser, const uint8_t *source, const char *class_name,
        size_t class_name_length, const pm_node_t *node, void *data) {
      (void) class_name_length;
      fleek_nested_iterator_state_t *state = (fleek_nested_iterator_state_t *) data;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      state->parser = parser;
      if (method->receiver != NULL || !fleek_nested_iterator_body_supported(method->body)) return -1;
      if (method->body == NULL) return 0;
      state->source = source; state->count = 0; state->unsupported = false;
      pm_visit_node(method->body, fleek_nested_iterator_visit, state);
      if (state->unsupported) return -1;
      if (state->count == 0) return 0;
      for (size_t index = 0; index < state->count; index++) {
        fleek_iterator_block_t *block = &state->blocks[index];
        block->depth = block->increments ? 1 : 0;
        for (size_t parent = 0; parent < state->count; parent++) {
          if (parent == index) continue;
          fleek_iterator_block_t *outer = &state->blocks[parent];
          if (outer->start < block->start && outer->end >= block->end && outer->increments) block->depth++;
        }
      }
      int findings = 0;
      for (size_t depth = 1; depth <= state->count; depth++) {
        char lines[512] = { 0 };
        size_t used = 0;
        size_t count = 0;
        for (size_t index = 0; index < state->count; index++) {
          fleek_iterator_block_t *block = &state->blocks[index];
          if (block->depth != depth || depth <= state->maximum) continue;
          bool leaf = true;
          for (size_t child = 0; child < state->count; child++) {
            if (child != index && state->blocks[index].start < state->blocks[child].start && state->blocks[index].end >= state->blocks[child].end) leaf = false;
          }
          if (!leaf) continue;
          int written = snprintf(lines + used, sizeof(lines) - used, "%s%d", count == 0 ? "" : ", ", block->line);
          if (written < 0 || (size_t) written >= sizeof(lines) - used) return -1;
          used += (size_t) written; count++;
        }
        if (count == 0) continue;
        pm_constant_t *method_name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
        int written = snprintf(fleek_nested_iterators_buffer + fleek_nested_iterators_used,
          sizeof(fleek_nested_iterators_buffer) - fleek_nested_iterators_used,
          "%s\\t%.*s#%.*s\\t\\t%zu\\n", lines, (int) class_name_length, class_name,
          (int) method_name->length, method_name->start, depth);
        if (written < 0 || (size_t) written >= sizeof(fleek_nested_iterators_buffer) - fleek_nested_iterators_used) return -1;
        fleek_nested_iterators_used += (size_t) written;
        findings++;
      }
      return findings;
    }
    int fleek_nested_iterators(const char *source, size_t length, size_t maximum, const char *ignore_iterators) {
      fleek_nested_iterators_buffer[0] = 0; fleek_nested_iterators_used = 0;
      fleek_nested_iterator_state_t state = { 0 };
      state.source = (const uint8_t *) source;
      state.ignore_iterators = ignore_iterators;
      state.maximum = maximum;
      return fleek_scan_method_scope(source, length, fleek_nested_iterator_method, &state);
    }
    const char *fleek_nested_iterators_finding(void) { return fleek_nested_iterators_buffer; }
    typedef struct { pm_constant_id_t name; int lines[128]; size_t count; } fleek_receiver_refs_t;
    typedef struct { pm_parser_t *parser; const uint8_t *source; fleek_receiver_refs_t receivers[64]; size_t receiver_count; size_t self_count; bool unsupported; } fleek_feature_envy_state_t;
    static bool fleek_feature_envy_visit(const pm_node_t *node, void *data) {
      fleek_feature_envy_state_t *state = (fleek_feature_envy_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      if (PM_NODE_TYPE_P(node, PM_CALL_NODE)) {
        const pm_call_node_t *call = (const pm_call_node_t *) node;
        if (call->receiver == NULL || PM_NODE_TYPE_P(call->receiver, PM_SELF_NODE)) { state->self_count++; return true; }
        if (!PM_NODE_TYPE_P(call->receiver, PM_LOCAL_VARIABLE_READ_NODE)) return true;
        pm_constant_id_t name = ((const pm_local_variable_read_node_t *) call->receiver)->name;
        size_t receiver = 0;
        while (receiver < state->receiver_count && state->receivers[receiver].name != name) receiver++;
        if (receiver == state->receiver_count) {
          if (state->receiver_count >= 64) { state->unsupported = true; return false; }
          state->receivers[receiver].name = name;
          state->receivers[receiver].count = 0;
          state->receiver_count++;
        }
        fleek_receiver_refs_t *refs = &state->receivers[receiver];
        if (refs->count >= 128) { state->unsupported = true; return false; }
        refs->lines[refs->count++] = fleek_source_line(state->source, call->base.location.start);
      }
      if (PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_READ_NODE) || PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_WRITE_NODE)) state->self_count++;
      return !state->unsupported;
    }
    static int fleek_feature_envy_method(pm_parser_t *parser, const uint8_t *source, const char *class_name,
        size_t class_name_length, const pm_node_t *node, void *data) {
      (void) data;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->receiver != NULL || method->body == NULL) return 0;
      if (!fleek_method_body_supported(method->body)) return -1;
      fleek_feature_envy_state_t state = { parser, source, { 0 }, 0, 0, false };
      pm_visit_node(method->body, fleek_feature_envy_visit, &state);
      if (state.unsupported) return -1;
      if (state.self_count == 0) return 0;
      size_t maximum = 0;
      for (size_t index = 0; index < state.receiver_count; index++) if (state.receivers[index].count > maximum) maximum = state.receivers[index].count;
      if (maximum <= state.self_count) return 0;
      pm_constant_t *method_name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      int findings = 0;
      for (size_t index = 0; index < state.receiver_count; index++) {
        fleek_receiver_refs_t *refs = &state.receivers[index];
        if (refs->count != maximum) continue;
        char lines[512] = { 0 };
        size_t used = 0;
        for (size_t line = 0; line < refs->count; line++) {
          int written = snprintf(lines + used, sizeof(lines) - used, "%s%d", line == 0 ? "" : ", ", refs->lines[line]);
          if (written < 0 || (size_t) written >= sizeof(lines) - used) return -1;
          used += (size_t) written;
        }
        pm_constant_t *receiver_name = pm_constant_pool_id_to_constant(&parser->constant_pool, refs->name);
        int written = snprintf(fleek_feature_envy_buffer + fleek_feature_envy_used,
          sizeof(fleek_feature_envy_buffer) - fleek_feature_envy_used,
          "%s\\t%.*s#%.*s\\t%.*s\\n", lines, (int) class_name_length, class_name,
          (int) method_name->length, method_name->start, (int) receiver_name->length, receiver_name->start);
        if (written < 0 || (size_t) written >= sizeof(fleek_feature_envy_buffer) - fleek_feature_envy_used) return -1;
        fleek_feature_envy_used += (size_t) written;
        findings++;
      }
      return findings;
    }
    int fleek_feature_envy(const char *source, size_t length) {
      fleek_feature_envy_buffer[0] = 0; fleek_feature_envy_used = 0;
      return fleek_scan_method_scope(source, length, fleek_feature_envy_method, NULL);
    }
    const char *fleek_feature_envy_finding(void) { return fleek_feature_envy_buffer; }

    static bool fleek_class_count_visit(const pm_node_t *node, void *data) {
      fleek_scope_count_state_t *state = (fleek_scope_count_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE) || PM_NODE_TYPE_P(node, PM_MODULE_NODE) || PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      if (PM_NODE_TYPE_P(node, PM_CONSTANT_WRITE_NODE) || PM_NODE_TYPE_P(node, PM_CONSTANT_PATH_WRITE_NODE) || PM_NODE_TYPE_P(node, PM_CONSTANT_AND_WRITE_NODE) || PM_NODE_TYPE_P(node, PM_CONSTANT_OR_WRITE_NODE) || PM_NODE_TYPE_P(node, PM_CONSTANT_OPERATOR_WRITE_NODE) || PM_NODE_TYPE_P(node, PM_CONSTANT_PATH_AND_WRITE_NODE) || PM_NODE_TYPE_P(node, PM_CONSTANT_PATH_OR_WRITE_NODE) || PM_NODE_TYPE_P(node, PM_CONSTANT_PATH_OPERATOR_WRITE_NODE)) state->count++;
      return true;
    }
    static bool fleek_ivar_count_visit(const pm_node_t *node, void *data) {
      fleek_parameter_names_t *variables = (fleek_parameter_names_t *) data;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE) || PM_NODE_TYPE_P(node, PM_MODULE_NODE)) return false;
      pm_constant_id_t name = 0;
      if (PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_WRITE_NODE)) name = ((const pm_instance_variable_write_node_t *) node)->name;
      else if (PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_AND_WRITE_NODE)) name = ((const pm_instance_variable_and_write_node_t *) node)->name;
      else if (PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_OR_WRITE_NODE)) name = ((const pm_instance_variable_or_write_node_t *) node)->name;
      if (name != 0) {
        size_t index = 0;
        while (index < variables->count && variables->names[index] != name) index++;
        if (index == variables->count && variables->count < 128) variables->names[variables->count++] = name;
      }
      return true;
    }
    typedef struct { bool found; } fleek_nested_method_state_t;
    static bool fleek_find_nested_method(const pm_node_t *node, void *data) {
      fleek_nested_method_state_t *state = (fleek_nested_method_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) { state->found = true; return false; }
      return !PM_NODE_TYPE_P(node, PM_CLASS_NODE) && !PM_NODE_TYPE_P(node, PM_MODULE_NODE);
    }
    static int fleek_count_scope(const char *source, size_t length, const char *detector, size_t threshold) {
      if (memchr(source, 0, length) != NULL) return -2;
      fleek_class_count = fleek_module_count = 0; fleek_only_scope = NULL;
      pm_options_t options = {0}; options.line = 1; options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser; pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -1; }
      pm_visit_node(root, fleek_collect_classes, NULL);
      if (fleek_class_count + fleek_module_count == 0) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0; }
      if (fleek_class_count + fleek_module_count != 1 || fleek_only_scope == NULL) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }
      const pm_node_t *body = PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE) ? ((const pm_class_node_t *) fleek_only_scope)->body : ((const pm_module_node_t *) fleek_only_scope)->body;
      const pm_node_t *constant_path = PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE) ? ((const pm_class_node_t *) fleek_only_scope)->constant_path : ((const pm_module_node_t *) fleek_only_scope)->constant_path;
      if (!PM_NODE_TYPE_P(constant_path, PM_CONSTANT_READ_NODE) || (body != NULL && !PM_NODE_TYPE_P(body, PM_STATEMENTS_NODE))) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }
      pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) constant_path)->name);
      size_t class_line = fleek_source_line((const uint8_t *) source, PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE) ? ((const pm_class_node_t *) fleek_only_scope)->class_keyword_loc.start : ((const pm_module_node_t *) fleek_only_scope)->module_keyword_loc.start);
      size_t count = 0; int status = 0;
      if (strcmp(detector, "TooManyConstants") == 0) {
        fleek_scope_count_state_t state = { 0 };
        if (body != NULL) pm_visit_node(body, fleek_class_count_visit, &state);
        count = state.count;
      } else if (strcmp(detector, "TooManyInstanceVariables") == 0) {
        fleek_parameter_names_t variables = { { 0 }, 0 };
        if (body != NULL) pm_visit_node(body, fleek_ivar_count_visit, &variables);
        count = variables.count;
        if (count == 128) status = -4;
      } else if (strcmp(detector, "TooManyMethods") == 0) {
        const pm_statements_node_t *statements = body == NULL ? NULL : (const pm_statements_node_t *) body;
        if (statements != NULL) for (size_t index = 0; index < statements->body.size; index++) {
          const pm_node_t *child = statements->body.nodes[index];
          if (PM_NODE_TYPE_P(child, PM_DEF_NODE)) { if (((const pm_def_node_t *) child)->receiver == NULL) count++; }
          else {
            fleek_nested_method_state_t nested = { false }; pm_visit_node(child, fleek_find_nested_method, &nested);
            if (nested.found) status = -4;
          }
        }
      }
      bool partial = status == -4 && strcmp(detector, "TooManyMethods") == 0;
      if ((status == 0 || partial) && count > threshold) {
        char *buffer = strcmp(detector, "TooManyInstanceVariables") == 0 ? fleek_too_many_instance_variables_buffer : strcmp(detector, "TooManyMethods") == 0 ? fleek_too_many_methods_buffer : fleek_too_many_constants_buffer;
        int written = snprintf(buffer, 4096, "%zu\\t%.*s\\t%zu\\t\\n", class_line, (int) class_name->length, class_name->start, count);
        if (written < 0 || written >= 4096) status = -4; else status = partial ? -5 : 1;
      }
      pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return status;
    }
    int fleek_too_many_instance_variables(const char *source, size_t length, size_t maximum) { fleek_too_many_instance_variables_buffer[0] = 0; return fleek_count_scope(source, length, "TooManyInstanceVariables", maximum); }
    const char *fleek_too_many_instance_variables_finding(void) { return fleek_too_many_instance_variables_buffer; }
    int fleek_too_many_methods(const char *source, size_t length, size_t maximum) { fleek_too_many_methods_buffer[0] = 0; return fleek_count_scope(source, length, "TooManyMethods", maximum); }
    const char *fleek_too_many_methods_finding(void) { return fleek_too_many_methods_buffer; }
    int fleek_too_many_constants(const char *source, size_t length, size_t maximum) { fleek_too_many_constants_buffer[0] = 0; return fleek_count_scope(source, length, "TooManyConstants", maximum); }
    const char *fleek_too_many_constants_finding(void) { return fleek_too_many_constants_buffer; }
    static int fleek_too_many_statements_method(pm_parser_t *parser, const uint8_t *source, const char *class_name, size_t class_name_length, const pm_node_t *node, void *data) {
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->body == NULL) return 0;
      if (!PM_NODE_TYPE_P(method->body, PM_STATEMENTS_NODE)) return -1;
      size_t count = ((const pm_statements_node_t *) method->body)->body.size;
      const pm_statements_node_t *body = (const pm_statements_node_t *) method->body;
      for (size_t index = 0; index < body->body.size; index++) {
        const pm_node_t *statement = body->body.nodes[index];
        if (PM_NODE_TYPE_P(statement, PM_IF_NODE) || PM_NODE_TYPE_P(statement, PM_UNLESS_NODE) || PM_NODE_TYPE_P(statement, PM_WHILE_NODE) || PM_NODE_TYPE_P(statement, PM_UNTIL_NODE) || PM_NODE_TYPE_P(statement, PM_FOR_NODE) || PM_NODE_TYPE_P(statement, PM_CASE_NODE) || PM_NODE_TYPE_P(statement, PM_BEGIN_NODE)) return -1;
      }
      if (fleek_name_is(parser, method->name, "initialize") || count <= *(size_t *) data) return 0;
      pm_constant_t *method_name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      int written = snprintf(fleek_too_many_statements_buffer + fleek_too_many_statements_used, sizeof(fleek_too_many_statements_buffer) - fleek_too_many_statements_used, "%d\\t%.*s#%s%.*s\\t%zu\\t\\n", fleek_source_line(source, method->def_keyword_loc.start), (int) class_name_length, class_name, method->receiver == NULL ? "" : "self.", (int) method_name->length, method_name->start, count);
      if (written < 0 || (size_t) written >= sizeof(fleek_too_many_statements_buffer) - fleek_too_many_statements_used) return -1;
      fleek_too_many_statements_used += (size_t) written;
      return 1;
    }
    static bool fleek_has_singleton_class(const pm_node_t *node, void *data) {
      bool *found = (bool *) data;
      if (PM_NODE_TYPE_P(node, PM_SINGLETON_CLASS_NODE)) { *found = true; return false; }
      return !PM_NODE_TYPE_P(node, PM_DEF_NODE);
    }
    static int fleek_scan_too_many_statements(const char *source, size_t length, size_t maximum) {
      if (memchr(source, 0, length) != NULL) return -2;
      pm_options_t options = {0}; options.line = 1; options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser; pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      bool found = false;
      bool parse_error = parser.error_list.head != NULL;
      if (!parse_error) pm_visit_node(root, fleek_has_singleton_class, &found);
      pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
      if (parse_error) return -1;
      int result = fleek_scan_method_scope(source, length, fleek_too_many_statements_method, &maximum);
      if (found && result > 0) return -5;
      if (result == -4 && fleek_too_many_statements_used > 0) return -5;
      if (found) return -4;
      return result;
    }
    int fleek_too_many_statements(const char *source, size_t length, size_t maximum) { fleek_too_many_statements_buffer[0] = 0; fleek_too_many_statements_used = 0; return fleek_scan_too_many_statements(source, length, maximum); }
    const char *fleek_too_many_statements_finding(void) { return fleek_too_many_statements_buffer; }
    typedef struct { const char *reject; const char *accept; } fleek_name_patterns_t;
    static int fleek_uncommunicative_method_name_method(pm_parser_t *parser, const uint8_t *source, const char *class_name, size_t class_name_length, const pm_node_t *node, void *data) {
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      pm_constant_t *name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      fleek_name_patterns_t *patterns = (fleek_name_patterns_t *) data;
      if (fleek_matches_any_pattern((const uint8_t *) name->start, name->length, patterns->accept)) return 0;
      if (!fleek_matches_any_pattern((const uint8_t *) name->start, name->length, patterns->reject)) return 0;
      int written = snprintf(fleek_uncommunicative_method_name_buffer + fleek_uncommunicative_method_name_used, sizeof(fleek_uncommunicative_method_name_buffer) - fleek_uncommunicative_method_name_used, "%zu\\t%.*s#%s%.*s\\t%.*s\\n", fleek_source_line(source, method->def_keyword_loc.start), (int) class_name_length, class_name, method->receiver == NULL ? "" : "self.", (int) name->length, name->start, (int) name->length, name->start);
      if (written < 0 || (size_t) written >= sizeof(fleek_uncommunicative_method_name_buffer) - fleek_uncommunicative_method_name_used) return -1;
      fleek_uncommunicative_method_name_used += (size_t) written;
      return 1;
    }
    int fleek_uncommunicative_method_name(const char *source, size_t length, const char *reject, const char *accept) {
      fleek_uncommunicative_method_name_buffer[0] = 0;
      fleek_uncommunicative_method_name_used = 0;
      fleek_name_patterns_t patterns = { reject, accept };
      int result = fleek_scan_method_scope(source, length, fleek_uncommunicative_method_name_method, &patterns);
      return result == -4 && fleek_uncommunicative_method_name_used > 0 ? -5 : result;
    }
    const char *fleek_uncommunicative_method_name_finding(void) { return fleek_uncommunicative_method_name_buffer; }
    typedef struct { pm_parser_t *parser; const uint8_t *source; fleek_name_patterns_t *patterns; const pm_node_t **scopes; size_t scope_count; bool unsupported; } fleek_module_name_state_t;
    static bool fleek_collect_module_name_scope(const pm_node_t *node, void *data) {
      fleek_module_name_state_t *state = (fleek_module_name_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE) || PM_NODE_TYPE_P(node, PM_MODULE_NODE)) {
        if (state->scope_count >= 256) { state->unsupported = true; return false; }
        state->scopes[state->scope_count++] = node;
      }
      return true;
    }
    static bool fleek_uncommunicative_module_name_node(const pm_node_t *node, void *data) {
      fleek_module_name_state_t *state = (fleek_module_name_state_t *) data;
      const pm_node_t *path = NULL;
      const uint8_t *keyword = NULL;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE)) { const pm_class_node_t *scope = (const pm_class_node_t *) node; path = scope->constant_path; keyword = scope->class_keyword_loc.start; }
      else if (PM_NODE_TYPE_P(node, PM_MODULE_NODE)) { const pm_module_node_t *scope = (const pm_module_node_t *) node; path = scope->constant_path; keyword = scope->module_keyword_loc.start; }
      else return true;
      for (size_t index = 0; index < state->scope_count; index++) {
        const pm_node_t *candidate = state->scopes[index];
        if (candidate != node && candidate->location.start < node->location.start && candidate->location.end >= node->location.end) {
          state->unsupported = true;
          return true;
        }
      }
      if (!PM_NODE_TYPE_P(path, PM_CONSTANT_READ_NODE)) { state->unsupported = true; return true; }
      pm_constant_t *name = pm_constant_pool_id_to_constant(&state->parser->constant_pool, ((const pm_constant_read_node_t *) path)->name);
      if (fleek_matches_any_pattern((const uint8_t *) name->start, name->length, state->patterns->accept)) return true;
      if (!fleek_matches_any_pattern((const uint8_t *) name->start, name->length, state->patterns->reject)) return true;
      int written = snprintf(fleek_uncommunicative_module_name_buffer + fleek_uncommunicative_module_name_used, sizeof(fleek_uncommunicative_module_name_buffer) - fleek_uncommunicative_module_name_used, "%d\\t%.*s\\t%.*s\\n", fleek_source_line(state->source, keyword), (int) name->length, name->start, (int) name->length, name->start);
      if (written < 0 || (size_t) written >= sizeof(fleek_uncommunicative_module_name_buffer) - fleek_uncommunicative_module_name_used) { state->unsupported = true; return true; }
      fleek_uncommunicative_module_name_used += (size_t) written;
      return true;
    }
    int fleek_uncommunicative_module_name(const char *source, size_t length, const char *reject, const char *accept) {
      fleek_uncommunicative_module_name_buffer[0] = 0; fleek_uncommunicative_module_name_used = 0;
      if (memchr(source, 0, length) != NULL) return -2;
      pm_options_t options = {0}; options.line = 1; options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser; pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -1; }
      fleek_name_patterns_t patterns = { reject, accept };
      const pm_node_t *scopes[256];
      fleek_module_name_state_t state = { &parser, (const uint8_t *) source, &patterns, scopes, 0, false };
      pm_visit_node(root, fleek_collect_module_name_scope, &state);
      pm_visit_node(root, fleek_uncommunicative_module_name_node, &state);
      pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
      return state.unsupported ? (fleek_uncommunicative_module_name_used > 0 ? -5 : -4) : 0;
    }
    const char *fleek_uncommunicative_module_name_finding(void) { return fleek_uncommunicative_module_name_buffer; }
    static int fleek_uncommunicative_parameter_name_method(pm_parser_t *parser, const uint8_t *source, const char *class_name, size_t class_name_length, const pm_node_t *node, void *data) {
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->receiver != NULL || method->parameters == NULL || !PM_NODE_TYPE_P((const pm_node_t *) method->parameters, PM_PARAMETERS_NODE)) return method->parameters == NULL ? 0 : -1;
      const pm_parameters_node_t *parameters = method->parameters;
      if (parameters->rest != NULL || parameters->keyword_rest != NULL || parameters->block != NULL) return -1;
      fleek_name_patterns_t *patterns = (fleek_name_patterns_t *) data;
      pm_constant_t *method_name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      int findings = 0;
      const pm_node_list_t *lists[] = { &parameters->requireds, &parameters->optionals, &parameters->posts, &parameters->keywords };
      for (size_t list = 0; list < 4; list++) for (size_t index = 0; index < lists[list]->size; index++) {
        pm_constant_id_t name_id = fleek_parameter_name(lists[list]->nodes[index]);
        if (name_id == 0) return -1;
        pm_constant_t *name = pm_constant_pool_id_to_constant(&parser->constant_pool, name_id);
        if (fleek_matches_any_pattern((const uint8_t *) name->start, name->length, patterns->accept) || !fleek_matches_any_pattern((const uint8_t *) name->start, name->length, patterns->reject)) continue;
        bool used = fleek_body_uses_name(parser, method->body, name_id);
        if (name->start[0] == '_' && !used) continue;
        int written = snprintf(fleek_uncommunicative_parameter_name_buffer + fleek_uncommunicative_parameter_name_used, sizeof(fleek_uncommunicative_parameter_name_buffer) - fleek_uncommunicative_parameter_name_used, "%d\\t%.*s#%.*s\\t%.*s\\n", fleek_source_line(source, method->def_keyword_loc.start), (int) class_name_length, class_name, (int) method_name->length, method_name->start, (int) name->length, name->start);
        if (written < 0 || (size_t) written >= sizeof(fleek_uncommunicative_parameter_name_buffer) - fleek_uncommunicative_parameter_name_used) return -1;
        fleek_uncommunicative_parameter_name_used += (size_t) written;
        findings++;
      }
      return findings;
    }
    int fleek_uncommunicative_parameter_name(const char *source, size_t length, const char *reject, const char *accept) {
      fleek_uncommunicative_parameter_name_buffer[0] = 0; fleek_uncommunicative_parameter_name_used = 0;
      fleek_name_patterns_t patterns = { reject, accept };
      int result = fleek_scan_method_scope(source, length, fleek_uncommunicative_parameter_name_method, &patterns);
      return result == -4 && fleek_uncommunicative_parameter_name_used > 0 ? -5 : result;
    }
    const char *fleek_uncommunicative_parameter_name_finding(void) { return fleek_uncommunicative_parameter_name_buffer; }
    typedef struct { pm_parser_t *parser; const uint8_t *source; const char *context; size_t used; fleek_name_patterns_t *patterns; bool unsupported; } fleek_variable_name_state_t;
    static bool fleek_uncommunicative_variable_name_node(const pm_node_t *node, void *data) {
      fleek_variable_name_state_t *state = (fleek_variable_name_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE) || PM_NODE_TYPE_P(node, PM_CLASS_NODE) || PM_NODE_TYPE_P(node, PM_MODULE_NODE)) return false;
      if (PM_NODE_TYPE_P(node, PM_BLOCK_PARAMETERS_NODE)) { state->unsupported = true; return true; }
      if (!PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_WRITE_NODE)) return true;
      const pm_local_variable_write_node_t *write = (const pm_local_variable_write_node_t *) node;
      pm_constant_t *name = pm_constant_pool_id_to_constant(&state->parser->constant_pool, write->name);
      if (fleek_matches_any_pattern((const uint8_t *) name->start, name->length, state->patterns->accept) || !fleek_matches_any_pattern((const uint8_t *) name->start, name->length, state->patterns->reject)) return true;
      int written = snprintf(fleek_uncommunicative_variable_name_buffer + fleek_uncommunicative_variable_name_used, sizeof(fleek_uncommunicative_variable_name_buffer) - fleek_uncommunicative_variable_name_used, "%d\\t%s\\t%.*s\\n", fleek_source_line(state->source, write->base.location.start), state->context, (int) name->length, name->start);
      if (written < 0 || (size_t) written >= sizeof(fleek_uncommunicative_variable_name_buffer) - fleek_uncommunicative_variable_name_used) { state->unsupported = true; return true; }
      fleek_uncommunicative_variable_name_used += (size_t) written;
      state->used++;
      return true;
    }
    static bool fleek_uncommunicative_variable_unhandled_node(const pm_node_t *node, void *data) {
      bool *unsupported = (bool *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      if (PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_WRITE_NODE) || PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_WRITE_NODE) || PM_NODE_TYPE_P(node, PM_BLOCK_PARAMETERS_NODE)) *unsupported = true;
      return !*unsupported;
    }
    static int fleek_uncommunicative_variable_name_method(pm_parser_t *parser, const uint8_t *source, const char *class_name, size_t class_name_length, const pm_node_t *node, void *data) {
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->receiver != NULL) return -1;
      if (method->body == NULL) return 0;
      pm_constant_t *method_name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      char context[256];
      int written = snprintf(context, sizeof(context), "%.*s#%.*s", (int) class_name_length, class_name, (int) method_name->length, method_name->start);
      if (written < 0 || (size_t) written >= sizeof(context)) return -1;
      fleek_variable_name_state_t *state = (fleek_variable_name_state_t *) data;
      size_t previous = state->used;
      state->parser = parser; state->source = source; state->context = context;
      pm_visit_node(method->body, fleek_uncommunicative_variable_name_node, state);
      return state->unsupported ? -1 : (int) (state->used - previous);
    }
    int fleek_uncommunicative_variable_name(const char *source, size_t length, const char *reject, const char *accept) {
      fleek_uncommunicative_variable_name_buffer[0] = 0; fleek_uncommunicative_variable_name_used = 0;
      if (memchr(source, 0, length) != NULL) return -2;
      pm_options_t options = {0}; options.line = 1; options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser; pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -1; }
      bool unsupported = false;
      pm_visit_node(root, fleek_uncommunicative_variable_unhandled_node, &unsupported);
      pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
      fleek_name_patterns_t patterns = { reject, accept };
      fleek_variable_name_state_t state = { NULL, (const uint8_t *) source, "", 0, &patterns, false };
      int result = fleek_scan_method_scope(source, length, fleek_uncommunicative_variable_name_method, &state);
      return unsupported || result == -4 || state.unsupported ? (state.used > 0 ? -5 : -4) : result;
    }
    const char *fleek_uncommunicative_variable_name_finding(void) { return fleek_uncommunicative_variable_name_buffer; }
    static bool fleek_data_clump_method_has(const fleek_data_clump_state_t *state, size_t method, pm_constant_id_t name) {
      for (size_t parameter = 0; parameter < state->counts[method]; parameter++) if (state->names[method][parameter] == name) return true;
      return false;
    }
    static bool fleek_data_clump_same_group(const fleek_data_clump_state_t *state, const size_t *matching, size_t matching_count, pm_constant_id_t name) {
      for (size_t method = 0; method < state->methods; method++) {
        bool expected = false;
        for (size_t index = 0; index < matching_count; index++) if (matching[index] == method) expected = true;
        if (fleek_data_clump_method_has(state, method, name) != expected) return false;
      }
      return true;
    }
    int fleek_data_clump(const char *source, size_t length, size_t max_copies, size_t min_clump_size) {
      fleek_data_clump_buffer[0] = 0; fleek_data_clump_used = 0;
      if (memchr(source, 0, length) != NULL) return -2;
      fleek_class_count = fleek_module_count = 0; fleek_only_scope = NULL;
      pm_options_t options = {0}; options.line = 1; options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser; pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -1; }
      pm_visit_node(root, fleek_collect_classes, NULL);
      if (fleek_class_count + fleek_module_count == 0) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0; }
      if (fleek_class_count + fleek_module_count != 1 || fleek_only_scope == NULL) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }
      const pm_node_t *constant_path = PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE) ? ((const pm_class_node_t *) fleek_only_scope)->constant_path : ((const pm_module_node_t *) fleek_only_scope)->constant_path;
      const pm_node_t *body = PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE) ? ((const pm_class_node_t *) fleek_only_scope)->body : ((const pm_module_node_t *) fleek_only_scope)->body;
      if (!PM_NODE_TYPE_P(constant_path, PM_CONSTANT_READ_NODE) || (body != NULL && !PM_NODE_TYPE_P(body, PM_STATEMENTS_NODE))) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }
      pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) constant_path)->name);
      fleek_data_clump_state_t state = { max_copies, min_clump_size, { { 0 } }, { 0 }, { 0 }, 0, false };
      if (body != NULL) {
        const pm_statements_node_t *statements = (const pm_statements_node_t *) body;
        if (statements->body.size > 128) state.methods = 128;
        for (size_t index = 0; index < statements->body.size && state.methods < 128; index++) {
          const pm_node_t *child = statements->body.nodes[index];
          if (PM_NODE_TYPE_P(child, PM_DEF_NODE)) {
            if (!fleek_data_clump_method(child, (const uint8_t *) source, &state)) break;
          } else {
            fleek_nested_method_state_t nested = { false }; pm_visit_node(child, fleek_find_nested_method, &nested);
            if (nested.found) state.unsupported = true;
          }
        }
      }
      if (state.methods == 128 && body != NULL && ((const pm_statements_node_t *) body)->body.size > 128) state.unsupported = true;
      size_t findings = 0;
      for (size_t method = 0; method < state.methods; method++) for (size_t parameter = 0; parameter < state.counts[method]; parameter++) {
        pm_constant_id_t name = state.names[method][parameter];
        bool seen = false;
        for (size_t earlier_method = 0; earlier_method < method; earlier_method++) for (size_t earlier_parameter = 0; earlier_parameter < state.counts[earlier_method]; earlier_parameter++) if (state.names[earlier_method][earlier_parameter] == name) seen = true;
        if (seen) continue;
        size_t matching[128]; size_t matching_count = 0;
        for (size_t candidate = 0; candidate < state.methods; candidate++) {
          bool has_name = false;
          for (size_t candidate_parameter = 0; candidate_parameter < state.counts[candidate]; candidate_parameter++) if (state.names[candidate][candidate_parameter] == name) has_name = true;
          if (has_name) matching[matching_count++] = candidate;
        }
        if (matching_count <= max_copies) continue;
        for (size_t candidate = 0; candidate < state.methods; candidate++) for (size_t candidate_parameter = 0; candidate_parameter < state.counts[candidate]; candidate_parameter++) {
          pm_constant_id_t candidate_name = state.names[candidate][candidate_parameter]; size_t copies = 0;
          for (size_t member = 0; member < state.methods; member++) if (fleek_data_clump_method_has(&state, member, candidate_name)) copies++;
          bool overlaps = false;
          for (size_t member = 0; member < matching_count; member++) if (fleek_data_clump_method_has(&state, matching[member], candidate_name)) overlaps = true;
          if (copies > max_copies && overlaps && !fleek_data_clump_same_group(&state, matching, matching_count, candidate_name)) state.unsupported = true;
        }
        if (method != matching[0]) continue;
        bool earlier_common = false;
        for (size_t earlier_parameter = 0; earlier_parameter < parameter; earlier_parameter++) {
          pm_constant_id_t earlier_name = state.names[method][earlier_parameter];
          size_t earlier_copies = 0;
          for (size_t candidate = 0; candidate < state.methods; candidate++) if (fleek_data_clump_method_has(&state, candidate, earlier_name)) earlier_copies++;
          if (earlier_copies > max_copies) earlier_common = true;
        }
        if (earlier_common) continue;
        char clump[512] = { 0 }; size_t clump_used = 0; size_t names_added = 0;
        pm_constant_id_t clump_names[64];
        for (size_t candidate_parameter = 0; candidate_parameter < state.counts[method]; candidate_parameter++) {
          pm_constant_id_t common = state.names[method][candidate_parameter]; size_t copies = 0;
          for (size_t candidate = 0; candidate < state.methods; candidate++) for (size_t pos = 0; pos < state.counts[candidate]; pos++) if (state.names[candidate][pos] == common) { copies++; break; }
          if (copies <= max_copies) continue;
          clump_names[names_added++] = common;
        }
        for (size_t left = 0; left < names_added; left++) for (size_t right = left + 1; right < names_added; right++) {
          pm_constant_t *left_name = pm_constant_pool_id_to_constant(&parser.constant_pool, clump_names[left]);
          pm_constant_t *right_name = pm_constant_pool_id_to_constant(&parser.constant_pool, clump_names[right]);
          size_t common_length = left_name->length < right_name->length ? left_name->length : right_name->length;
          int order = memcmp(left_name->start, right_name->start, common_length);
          if (order == 0) order = left_name->length < right_name->length ? -1 : left_name->length > right_name->length;
          if (order > 0) { pm_constant_id_t temporary = clump_names[left]; clump_names[left] = clump_names[right]; clump_names[right] = temporary; }
        }
        clump_used = 0;
        for (size_t name_index = 0; name_index < names_added; name_index++) {
          pm_constant_t *param_name = pm_constant_pool_id_to_constant(&parser.constant_pool, clump_names[name_index]);
          int added = snprintf(clump + clump_used, sizeof(clump) - clump_used, "%s'%.*s'", name_index == 0 ? "" : ", ", (int) param_name->length, param_name->start);
          if (added < 0 || (size_t) added >= sizeof(clump) - clump_used) { findings = 128; break; }
          clump_used += (size_t) added;
        }
        if (findings == 128) break;
        if (names_added < min_clump_size) continue;
        char lines[512] = { 0 }; size_t lines_used = 0;
        for (size_t copy = 0; copy < matching_count; copy++) {
          size_t line = state.lines[matching[copy]];
          bool line_seen = false;
          for (size_t old = 0; old < copy; old++) if (state.lines[matching[old]] == line) line_seen = true;
          if (line_seen) continue;
          int line_written = snprintf(lines + lines_used, sizeof(lines) - lines_used, "%s%zu", lines_used == 0 ? "" : ", ", line);
          if (line_written < 0 || (size_t) line_written >= sizeof(lines) - lines_used) { findings = 128; break; }
          lines_used += (size_t) line_written;
        }
        if (findings == 128) break;
        int written = snprintf(fleek_data_clump_buffer + fleek_data_clump_used, sizeof(fleek_data_clump_buffer) - fleek_data_clump_used, "%s\\t%.*s\\t[%s]\\t%zu\\n", lines, (int) class_name->length, class_name->start, clump, matching_count);
        if (written < 0 || (size_t) written >= sizeof(fleek_data_clump_buffer) - fleek_data_clump_used) { findings = 128; break; }
        fleek_data_clump_used += (size_t) written; findings++;
      }
      pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
      if (findings == 128) return -4;
      return state.unsupported ? (findings > 0 ? -5 : -4) : (int) findings;
    }
    const char *fleek_data_clump_finding(void) { return fleek_data_clump_buffer; }

    int fleek_class_variable(const char *source, size_t length) {
      fleek_finding_buffer[0] = 0;
      fleek_class_count = fleek_module_count = fleek_finding_count = fleek_unsupported = 0;
      fleek_suppressed = fleek_bad_suppression = 0;
      fleek_group_count = 0;
      fleek_only_scope = NULL;
      fleek_namespace_scope = NULL;
      fleek_scope_name[0] = 0;
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
      bool simple_class = fleek_class_count == 1 && fleek_module_count == 0;
      bool simple_module = fleek_class_count == 0 && fleek_module_count == 1;
      bool namespaced_scope = fleek_scope_contains(fleek_namespace_scope, fleek_only_scope) &&
        fleek_module_has_direct_child(fleek_namespace_scope, fleek_only_scope) &&
        ((fleek_class_count == 1 && fleek_module_count == 1) || (fleek_class_count == 0 && fleek_module_count == 2));
      if ((!simple_class && !simple_module && !namespaced_scope) || fleek_unsupported) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      if (namespaced_scope) {
        const pm_node_t *namespace_body = PM_NODE_TYPE_P(fleek_namespace_scope, PM_MODULE_NODE) ? ((const pm_module_node_t *) fleek_namespace_scope)->body : NULL;
        bool namespace_has_occurrences = false;
        if (namespace_body != NULL) pm_visit_node(namespace_body, fleek_namespace_has_class_variables, &namespace_has_occurrences);
        if (namespace_has_occurrences) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }
      }
      const pm_node_t *scope_node = fleek_only_scope;
      pm_node_t *constant_path = NULL;
      pm_node_t *scope_body = NULL;
      const uint8_t *scope_keyword = NULL;
      pm_node_t *namespace_constant_path = NULL;
      if (fleek_class_count == 1) {
        const pm_class_node_t *class_node = (const pm_class_node_t *) scope_node;
        constant_path = class_node->constant_path;
        scope_body = class_node->body;
        scope_keyword = class_node->class_keyword_loc.start;
      } else {
        const pm_module_node_t *module_node = (const pm_module_node_t *) scope_node;
        constant_path = module_node->constant_path;
        scope_body = module_node->body;
        scope_keyword = module_node->module_keyword_loc.start;
      }
      if (scope_node == NULL || !PM_NODE_TYPE_P(constant_path, PM_CONSTANT_READ_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((pm_constant_read_node_t *) constant_path)->name);
      const char *scope_name = (const char *) class_name->start;
      size_t scope_name_length = class_name->length;
      if (namespaced_scope) {
        const pm_module_node_t *namespace_node = (const pm_module_node_t *) fleek_namespace_scope;
        namespace_constant_path = namespace_node->constant_path;
        if (!PM_NODE_TYPE_P(namespace_constant_path, PM_CONSTANT_READ_NODE)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        pm_constant_t *namespace_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((pm_constant_read_node_t *) namespace_constant_path)->name);
        int written = snprintf(fleek_scope_name, sizeof(fleek_scope_name), "%.*s::%.*s", (int) namespace_name->length, namespace_name->start, (int) class_name->length, class_name->start);
        if (written < 0 || (size_t) written >= sizeof(fleek_scope_name)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        scope_name = fleek_scope_name;
        scope_name_length = (size_t) written;
      }
      fleek_class_t scope = { &parser, scope_name, scope_name_length, 0 };
      pm_list_node_t *comment_node = parser.comment_list.head;
      while (comment_node != NULL) {
        pm_comment_t *comment = (pm_comment_t *) comment_node;
        int suppression = fleek_comment_suppression(comment);
        if (comment->location.end <= scope_keyword && suppression != 0) {
          if (fleek_only_comments_between(comment->location.end, scope_keyword)) {
            if (suppression < 0) fleek_bad_suppression = 1;
            if (suppression == 1) fleek_suppressed = 1;
          }
        }
        comment_node = comment_node->next;
      }
      if (fleek_bad_suppression) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -5;
      }
      if (fleek_suppressed) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
      }
      if (scope_body != NULL) pm_visit_node(scope_body, fleek_class_variables, &scope);
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

    enum { FLEEK_DUPLICATION_UNSUPPORTED_STATEMENT = 0, FLEEK_DUPLICATION_CALL_STATEMENT = 1, FLEEK_DUPLICATION_INTEGER_STATEMENT = 2, FLEEK_DUPLICATION_RUBY4_AND_STATEMENT = 3 };

    static int fleek_duplication_statement_tag(const pm_node_t *node) {
      if (PM_NODE_TYPE_P(node, PM_CALL_NODE)) {
        const pm_call_node_t *call = (const pm_call_node_t *) node;
        if (call->receiver != NULL || call->block != NULL || (call->arguments != NULL && call->arguments->arguments.size != 0)) return FLEEK_DUPLICATION_UNSUPPORTED_STATEMENT;
        return FLEEK_DUPLICATION_CALL_STATEMENT;
      }
      if (PM_NODE_TYPE_P(node, PM_INTEGER_NODE)) return FLEEK_DUPLICATION_INTEGER_STATEMENT;
      if (PM_NODE_TYPE_P(node, PM_AND_NODE)) {
        const pm_and_node_t *logical_and = (const pm_and_node_t *) node;
        if (PM_NODE_TYPE_P(logical_and->left, PM_INTEGER_NODE) && PM_NODE_TYPE_P(logical_and->right, PM_TRUE_NODE)) return FLEEK_DUPLICATION_RUBY4_AND_STATEMENT;
      }
      return FLEEK_DUPLICATION_UNSUPPORTED_STATEMENT;
    }

    static bool fleek_duplication_method(const pm_node_t *node, const uint8_t *source, fleek_duplication_method_t *result) {
      if (!PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->receiver != NULL || method->parameters != NULL || method->body == NULL || !PM_NODE_TYPE_P(method->body, PM_STATEMENTS_NODE)) return false;
      const pm_statements_node_t *body = (const pm_statements_node_t *) method->body;
      if (body->body.size > 128) return false;
      result->shape_count = body->body.size;
      result->line = 1;
      for (const uint8_t *cursor = source; cursor < method->def_keyword_loc.start; cursor++) if (*cursor == '\\n') result->line++;
      for (size_t statement = 0; statement < body->body.size; statement++) {
        int tag = fleek_duplication_statement_tag(body->body.nodes[statement]);
        if (tag == FLEEK_DUPLICATION_UNSUPPORTED_STATEMENT) return false;
        if (tag == FLEEK_DUPLICATION_RUBY4_AND_STATEMENT && statement + 1 != body->body.size) return false;
        result->data.shapes[statement] = tag;
      }
      return true;
    }

    typedef struct { fleek_duplication_method_t *method; bool overflow; } fleek_duplication_ast_t;
    static void fleek_duplication_collect_class_node(const pm_node_t *node, fleek_duplication_ast_t *ast);
    static bool fleek_duplication_collect_class_child(const pm_node_t *node, void *data) {
      fleek_duplication_collect_class_node(node, (fleek_duplication_ast_t *) data);
      return false;
    }
    static bool fleek_duplication_class_node_supported(const pm_node_t *node) {
      return PM_NODE_TYPE_P(node, PM_CALL_NODE) || PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_WRITE_NODE) ||
        PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_READ_NODE) || PM_NODE_TYPE_P(node, PM_STRING_NODE) ||
        PM_NODE_TYPE_P(node, PM_SYMBOL_NODE) || PM_NODE_TYPE_P(node, PM_INTEGER_NODE) ||
        PM_NODE_TYPE_P(node, PM_TRUE_NODE) || PM_NODE_TYPE_P(node, PM_FALSE_NODE) || PM_NODE_TYPE_P(node, PM_AND_NODE) || PM_NODE_TYPE_P(node, PM_OR_NODE) ||
        PM_NODE_TYPE_P(node, PM_CONSTANT_READ_NODE) || PM_NODE_TYPE_P(node, PM_KEYWORD_HASH_NODE) ||
        PM_NODE_TYPE_P(node, PM_ASSOC_NODE) || PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_READ_NODE) || PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_WRITE_NODE) ||
        PM_NODE_TYPE_P(node, PM_RETURN_NODE) || PM_NODE_TYPE_P(node, PM_IF_NODE) || PM_NODE_TYPE_P(node, PM_UNLESS_NODE) || PM_NODE_TYPE_P(node, PM_ELSE_NODE);
    }
    static void fleek_duplication_collect_class_node(const pm_node_t *node, fleek_duplication_ast_t *ast) {
      if (PM_NODE_TYPE_P(node, PM_ARGUMENTS_NODE)) { pm_visit_child_nodes(node, fleek_duplication_collect_class_child, ast); return; }
      if (PM_NODE_TYPE_P(node, PM_STATEMENTS_NODE)) {
        const pm_statements_node_t *statements = (const pm_statements_node_t *) node;
        if (statements->body.size > 128) { ast->overflow = true; return; }
        pm_visit_child_nodes(node, fleek_duplication_collect_class_child, ast);
        return;
      }
      if (ast->method->shape_count == 128 || ast->method->data.ast.tree_count + 2 > 256 || !fleek_duplication_class_node_supported(node)) { ast->overflow = true; return; }
      size_t index = ast->method->shape_count++;
      ast->method->data.ast.nodes[index] = node;
      ast->method->data.ast.tree_starts[index] = (uint16_t) ast->method->data.ast.tree_count;
      ast->method->data.ast.tree[ast->method->data.ast.tree_count++] = (int16_t) node->type;
      pm_visit_child_nodes(node, fleek_duplication_collect_class_child, ast);
      ast->method->data.ast.tree[ast->method->data.ast.tree_count++] = (int16_t) (-(int) node->type - 1);
      ast->method->data.ast.tree_ends[index] = (uint16_t) ast->method->data.ast.tree_count;
      ast->method->data.ast.node_ends[index] = (uint8_t) ast->method->shape_count;
    }
    static bool fleek_duplication_optional_default_supported(const pm_node_t *node) {
      return PM_NODE_TYPE_P(node, PM_INTEGER_NODE) || PM_NODE_TYPE_P(node, PM_STRING_NODE) ||
        PM_NODE_TYPE_P(node, PM_SYMBOL_NODE) || PM_NODE_TYPE_P(node, PM_TRUE_NODE) ||
        PM_NODE_TYPE_P(node, PM_FALSE_NODE) || PM_NODE_TYPE_P(node, PM_NIL_NODE);
    }
    static bool fleek_duplication_class_parameters(const pm_node_t *node, fleek_duplication_method_t *result) {
      if (node == NULL) return true;
      if (!PM_NODE_TYPE_P(node, PM_PARAMETERS_NODE)) return false;
      const pm_parameters_node_t *parameters = (const pm_parameters_node_t *) node;
      if (parameters->requireds.size + parameters->optionals.size > 8 || parameters->rest != NULL ||
          parameters->posts.size != 0 || parameters->keywords.size != 0 || parameters->keyword_rest != NULL || parameters->block != NULL) return false;
      for (size_t index = 0; index < parameters->requireds.size; index++) if (!PM_NODE_TYPE_P(parameters->requireds.nodes[index], PM_REQUIRED_PARAMETER_NODE)) return false;
      for (size_t index = 0; index < parameters->optionals.size; index++) {
        const pm_node_t *optional = parameters->optionals.nodes[index];
        if (!PM_NODE_TYPE_P(optional, PM_OPTIONAL_PARAMETER_NODE) ||
            !fleek_duplication_optional_default_supported(((const pm_optional_parameter_node_t *) optional)->value)) return false;
        result->parameter_mass += 2;
      }
      return true;
    }
    static bool fleek_duplication_class_method(const pm_node_t *node, const uint8_t *source, fleek_duplication_method_t *result) {
      if (!PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      result->parameter_mass = 0;
      if (method->receiver != NULL || !fleek_duplication_class_parameters((const pm_node_t *) method->parameters, result) || method->body == NULL || method->equal_loc.start != NULL || !PM_NODE_TYPE_P(method->body, PM_STATEMENTS_NODE)) return false;
      fleek_duplication_ast_t ast = { result, false };
      fleek_duplication_collect_class_node(method->body, &ast);
      if (ast.overflow || result->shape_count == 0) return false;
      result->line = 1;
      for (const uint8_t *cursor = source; cursor < method->def_keyword_loc.start; cursor++) if (*cursor == '\\n') result->line++;
      return true;
    }
    static bool fleek_duplication_constant_path_names(const pm_node_t *constant_path, pm_constant_id_t *names, size_t capacity, size_t *count) {
      size_t found = 0;
      const pm_node_t *cursor = constant_path;
      while (cursor != NULL) {
        if (PM_NODE_TYPE_P(cursor, PM_CONSTANT_READ_NODE)) {
          if (found == capacity) return false;
          names[found++] = ((const pm_constant_read_node_t *) cursor)->name;
          cursor = NULL;
        } else if (PM_NODE_TYPE_P(cursor, PM_CONSTANT_PATH_NODE)) {
          const pm_constant_path_node_t *path = (const pm_constant_path_node_t *) cursor;
          if (path->parent == NULL || found == capacity) return false;
          names[found++] = path->name;
          cursor = path->parent;
        } else {
          return false;
        }
      }
      if (found == 0) return false;
      for (size_t index = 0; index < found / 2; index++) {
        pm_constant_id_t name = names[index];
        names[index] = names[found - index - 1];
        names[found - index - 1] = name;
      }
      *count = found;
      return true;
    }
    static bool fleek_duplication_class_shapes_equal(const fleek_duplication_method_t *left, const fleek_duplication_method_t *right) {
      if (left->shape_count != right->shape_count || left->data.ast.tree_count != right->data.ast.tree_count) return false;
      for (size_t index = 0; index < left->data.ast.tree_count; index++) if (left->data.ast.tree[index] != right->data.ast.tree[index]) return false;
      return true;
    }
    static bool fleek_duplication_class_node_massless(const pm_node_t *node) {
      return PM_NODE_TYPE_P(node, PM_KEYWORD_HASH_NODE) || PM_NODE_TYPE_P(node, PM_ELSE_NODE);
    }
    static bool fleek_duplication_class_subtrees_equal(const fleek_duplication_method_t *left, size_t left_node, const fleek_duplication_method_t *right, size_t right_node) {
      size_t left_length = left->data.ast.tree_ends[left_node] - left->data.ast.tree_starts[left_node];
      size_t right_length = right->data.ast.tree_ends[right_node] - right->data.ast.tree_starts[right_node];
      if (left_length != right_length) return false;
      for (size_t index = 0; index < left_length; index++) if (left->data.ast.tree[left->data.ast.tree_starts[left_node] + index] != right->data.ast.tree[right->data.ast.tree_starts[right_node] + index]) return false;
      return true;
    }
    static size_t fleek_duplication_class_subtree_mass(const fleek_duplication_method_t *method, size_t node) {
      size_t mass = method->data.ast.node_ends[node] - node;
      for (size_t index = node; index < method->data.ast.node_ends[node]; index++) if (fleek_duplication_class_node_massless(method->data.ast.nodes[index])) mass--;
      return mass;
    }
    static bool fleek_duplication_append_group(const char *node, bool identical, size_t node_mass, const int *lines, size_t count) {
      size_t group_mass = node_mass * count;
      size_t group_score = group_mass * (identical ? count : 1);
      size_t remaining = sizeof(fleek_duplication_buffer) - fleek_duplication_buffer_used;
      int written = snprintf(fleek_duplication_buffer + fleek_duplication_buffer_used, remaining, "%s%s\\t%s\\t%zu\\t%zu", fleek_duplication_buffer_used == 0 ? "" : "\\n", node, identical ? "identical" : "similar", group_mass, group_score);
      if (written < 0 || (size_t) written >= remaining) return false;
      fleek_duplication_buffer_used += (size_t) written;
      for (size_t index = 0; index < count; index++) {
        remaining = sizeof(fleek_duplication_buffer) - fleek_duplication_buffer_used;
        written = snprintf(fleek_duplication_buffer + fleek_duplication_buffer_used, remaining, "%s%d", index == 0 ? "\\t" : ",", lines[index]);
        if (written < 0 || (size_t) written >= remaining) return false;
        fleek_duplication_buffer_used += (size_t) written;
      }
      fleek_duplication_total_score += (int) group_score;
      return true;
    }
    static bool fleek_constants_equal(pm_parser_t *parser, pm_constant_id_t left, pm_constant_id_t right);
    static bool fleek_duplication_optional_defaults_equal(const pm_node_t *left, const pm_node_t *right) {
      if (left->type != right->type) return false;
      if (PM_NODE_TYPE_P(left, PM_INTEGER_NODE)) return pm_integer_compare(&((const pm_integer_node_t *) left)->value, &((const pm_integer_node_t *) right)->value) == 0;
      if (PM_NODE_TYPE_P(left, PM_STRING_NODE) || PM_NODE_TYPE_P(left, PM_SYMBOL_NODE)) {
        const pm_string_t *left_value = PM_NODE_TYPE_P(left, PM_STRING_NODE) ? &((const pm_string_node_t *) left)->unescaped : &((const pm_symbol_node_t *) left)->unescaped;
        const pm_string_t *right_value = PM_NODE_TYPE_P(right, PM_STRING_NODE) ? &((const pm_string_node_t *) right)->unescaped : &((const pm_symbol_node_t *) right)->unescaped;
        return pm_string_length(left_value) == pm_string_length(right_value) &&
          memcmp(pm_string_source(left_value), pm_string_source(right_value), pm_string_length(left_value)) == 0;
      }
      return PM_NODE_TYPE_P(left, PM_TRUE_NODE) || PM_NODE_TYPE_P(left, PM_FALSE_NODE) || PM_NODE_TYPE_P(left, PM_NIL_NODE);
    }
    static size_t fleek_duplication_optional_parameter_count(const pm_def_node_t *method) {
      return method->parameters == NULL ? 0 : ((const pm_parameters_node_t *) method->parameters)->optionals.size;
    }
    static bool fleek_duplication_class_parameters_equal(pm_parser_t *parser, const pm_def_node_t *left, const pm_def_node_t *right) {
      if (left->parameters == NULL || right->parameters == NULL) return left->parameters == right->parameters;
      const pm_parameters_node_t *left_parameters = (const pm_parameters_node_t *) left->parameters;
      const pm_parameters_node_t *right_parameters = (const pm_parameters_node_t *) right->parameters;
      if (left_parameters->requireds.size != right_parameters->requireds.size || left_parameters->optionals.size != right_parameters->optionals.size) return false;
      for (size_t index = 0; index < left_parameters->requireds.size; index++) {
        const pm_required_parameter_node_t *left_parameter = (const pm_required_parameter_node_t *) left_parameters->requireds.nodes[index];
        const pm_required_parameter_node_t *right_parameter = (const pm_required_parameter_node_t *) right_parameters->requireds.nodes[index];
        if (!fleek_constants_equal(parser, left_parameter->name, right_parameter->name)) return false;
      }
      for (size_t index = 0; index < left_parameters->optionals.size; index++) {
        const pm_optional_parameter_node_t *left_parameter = (const pm_optional_parameter_node_t *) left_parameters->optionals.nodes[index];
        const pm_optional_parameter_node_t *right_parameter = (const pm_optional_parameter_node_t *) right_parameters->optionals.nodes[index];
        if (!fleek_constants_equal(parser, left_parameter->name, right_parameter->name) ||
            !fleek_duplication_optional_defaults_equal(left_parameter->value, right_parameter->value)) return false;
      }
      return true;
    }
    static bool fleek_duplication_class_values_equal(pm_parser_t *parser, const fleek_duplication_method_t *left, const fleek_duplication_method_t *right) {
      for (size_t index = 0; index < left->shape_count; index++) {
        const pm_node_t *first = left->data.ast.nodes[index];
        const pm_node_t *second = right->data.ast.nodes[index];
        if (first->type != second->type) return false;
        if (PM_NODE_TYPE_P(first, PM_CALL_NODE) && !fleek_constants_equal(parser, ((const pm_call_node_t *) first)->name, ((const pm_call_node_t *) second)->name)) return false;
        if (PM_NODE_TYPE_P(first, PM_CONSTANT_READ_NODE) && !fleek_constants_equal(parser, ((const pm_constant_read_node_t *) first)->name, ((const pm_constant_read_node_t *) second)->name)) return false;
        if (PM_NODE_TYPE_P(first, PM_LOCAL_VARIABLE_READ_NODE) && !fleek_constants_equal(parser, ((const pm_local_variable_read_node_t *) first)->name, ((const pm_local_variable_read_node_t *) second)->name)) return false;
        if (PM_NODE_TYPE_P(first, PM_LOCAL_VARIABLE_WRITE_NODE) && !fleek_constants_equal(parser, ((const pm_local_variable_write_node_t *) first)->name, ((const pm_local_variable_write_node_t *) second)->name)) return false;
        if (PM_NODE_TYPE_P(first, PM_INSTANCE_VARIABLE_READ_NODE) && !fleek_constants_equal(parser, ((const pm_instance_variable_read_node_t *) first)->name, ((const pm_instance_variable_read_node_t *) second)->name)) return false;
        if (PM_NODE_TYPE_P(first, PM_INSTANCE_VARIABLE_WRITE_NODE) && !fleek_constants_equal(parser, ((const pm_instance_variable_write_node_t *) first)->name, ((const pm_instance_variable_write_node_t *) second)->name)) return false;
        if (PM_NODE_TYPE_P(first, PM_INTEGER_NODE) && pm_integer_compare(&((const pm_integer_node_t *) first)->value, &((const pm_integer_node_t *) second)->value) != 0) return false;
        if ((PM_NODE_TYPE_P(first, PM_STRING_NODE) || PM_NODE_TYPE_P(first, PM_SYMBOL_NODE)) &&
            !fleek_duplication_optional_defaults_equal(first, second)) return false;
      }
      return true;
    }

    static bool fleek_duplication_collect_class_methods(const pm_node_t *node, size_t class_depth, const uint8_t *source, fleek_duplication_class_candidates_t *set) {
      if (!PM_NODE_TYPE_P(node, PM_CLASS_NODE)) return false;
      const pm_class_node_t *class_node = (const pm_class_node_t *) node;
      if (class_node->constant_path == NULL || !PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE) ||
          (class_node->body != NULL && !PM_NODE_TYPE_P(class_node->body, PM_STATEMENTS_NODE))) return false;
      size_t scope_index = set->scope_count++;
      size_t first_candidate = set->count;
      size_t body_count = 0;
      if (class_node->body != NULL) {
        const pm_statements_node_t *body = (const pm_statements_node_t *) class_node->body;
        if (body->body.size > 32) return false;
        body_count = body->body.size;
        if (body->body.size == 1 && PM_NODE_TYPE_P(body->body.nodes[0], PM_CLASS_NODE)) {
          const pm_class_node_t *nested_class = (const pm_class_node_t *) body->body.nodes[0];
          if (!PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE) ||
              !PM_NODE_TYPE_P(nested_class->constant_path, PM_CONSTANT_READ_NODE) || nested_class->body == NULL ||
              !PM_NODE_TYPE_P(nested_class->body, PM_STATEMENTS_NODE)) { fleek_duplication_partial = 1; return true; }
          if (class_depth >= 6) { fleek_duplication_partial = 1; return true; }
          if (!fleek_duplication_collect_class_methods((const pm_node_t *) nested_class, class_depth + 1, source, set)) return false;
          for (size_t index = first_candidate; index < set->count; index++) {
            if (set->candidates[index].scope_depth >= 8) { fleek_duplication_partial = 1; continue; }
            for (size_t name = set->candidates[index].scope_depth; name > 0; name--) set->candidates[index].scope_names[name] = set->candidates[index].scope_names[name - 1];
            set->candidates[index].scope_names[0] = ((const pm_constant_read_node_t *) class_node->constant_path)->name;
            set->candidates[index].scope_depth++;
            set->candidates[index].scope_mass++;
            set->scope_lines[index] = fleek_source_line(source, class_node->base.location.start);
          }
          return true;
        }
        if (body->body.size > 1) {
          bool only_classes = true;
          for (size_t index = 0; index < body->body.size; index++) if (!PM_NODE_TYPE_P(body->body.nodes[index], PM_CLASS_NODE)) only_classes = false;
          if (only_classes) {
            if (class_depth >= 5) { fleek_duplication_partial = 1; return true; }
            size_t sibling_first_candidate = set->count;
            bool siblings_complete = true;
            for (size_t index = 0; index < body->body.size; index++) {
              const pm_class_node_t *nested_class = (const pm_class_node_t *) body->body.nodes[index];
              if (!PM_NODE_TYPE_P(nested_class->constant_path, PM_CONSTANT_READ_NODE) || nested_class->body == NULL ||
                  !PM_NODE_TYPE_P(nested_class->body, PM_STATEMENTS_NODE)) { fleek_duplication_partial = 1; siblings_complete = false; continue; }
              const pm_statements_node_t *nested_body = (const pm_statements_node_t *) nested_class->body;
              pm_constant_id_t inner_name = 0;
              const pm_statements_node_t *method_body = nested_body;
              bool direct_methods = nested_body->body.size > 0;
              for (size_t method = 0; method < nested_body->body.size; method++) if (!PM_NODE_TYPE_P(nested_body->body.nodes[method], PM_DEF_NODE)) direct_methods = false;
              if (!direct_methods && nested_body->body.size == 1 && class_depth < 5 && PM_NODE_TYPE_P(nested_body->body.nodes[0], PM_CLASS_NODE)) {
                const pm_class_node_t *inner_class = (const pm_class_node_t *) nested_body->body.nodes[0];
                if (PM_NODE_TYPE_P(inner_class->constant_path, PM_CONSTANT_READ_NODE) && inner_class->body != NULL && PM_NODE_TYPE_P(inner_class->body, PM_STATEMENTS_NODE)) {
                  method_body = (const pm_statements_node_t *) inner_class->body;
                  inner_name = ((const pm_constant_read_node_t *) inner_class->constant_path)->name;
                }
              }
              if (method_body == nested_body && !direct_methods) {
                fleek_duplication_partial = 1; siblings_complete = false; continue;
              }
              if (method_body->body.size == 0) { fleek_duplication_partial = 1; siblings_complete = false; continue; }
              for (size_t method = 0; method < method_body->body.size; method++) {
                const pm_node_t *method_node = method_body->body.nodes[method];
                if (!PM_NODE_TYPE_P(method_node, PM_DEF_NODE) || set->count == 24 || !fleek_duplication_class_method(method_node, source, &set->candidates[set->count])) {
                  fleek_duplication_partial = 1; siblings_complete = false; continue;
                }
                size_t candidate = set->count++;
                set->methods[candidate] = (const pm_def_node_t *) method_node;
                set->scope_indices[candidate] = scope_index;
                set->candidates[candidate].scope_kind = 1;
                set->candidates[candidate].scope_names[0] = ((const pm_constant_read_node_t *) nested_class->constant_path)->name;
                if (inner_name != 0) set->candidates[candidate].scope_names[1] = inner_name;
                set->candidates[candidate].scope_depth = inner_name == 0 ? 1 : 2;
                set->candidates[candidate].scope_mass = inner_name == 0 ? 1 : 2;
              }
            }
            for (size_t index = sibling_first_candidate; index < set->count; index++) {
              if (set->candidates[index].scope_depth >= 8) { fleek_duplication_partial = 1; continue; }
              for (size_t name = set->candidates[index].scope_depth; name > 0; name--) set->candidates[index].scope_names[name] = set->candidates[index].scope_names[name - 1];
              set->candidates[index].scope_names[0] = ((const pm_constant_read_node_t *) class_node->constant_path)->name;
              set->candidates[index].scope_depth++;
              set->candidates[index].scope_mass++;
              set->scope_lines[index] = fleek_source_line(source, class_node->base.location.start);
              set->scope_body_counts[index] = set->count - sibling_first_candidate + (siblings_complete ? 0 : 1);
              set->scope_candidate_counts[index] = set->count - sibling_first_candidate;
            }
            return true;
          }
        }
        for (size_t index = 0; index < body->body.size; index++) {
          const pm_node_t *child = body->body.nodes[index];
          if (!PM_NODE_TYPE_P(child, PM_DEF_NODE)) { fleek_duplication_partial = 1; continue; }
          if (set->count == 24 || !fleek_duplication_class_method(child, source, &set->candidates[set->count])) { fleek_duplication_partial = 1; continue; }
          set->methods[set->count] = (const pm_def_node_t *) child;
          set->scope_indices[set->count] = scope_index;
          set->count++;
        }
      }
      for (size_t index = first_candidate; index < set->count; index++) {
        set->scope_body_counts[index] = body_count;
        set->scope_candidate_counts[index] = set->count - first_candidate;
        set->scope_lines[index] = fleek_source_line(source, class_node->base.location.start);
        set->candidates[index].scope_kind = 1;
        set->candidates[index].scope_names[0] = ((const pm_constant_read_node_t *) class_node->constant_path)->name;
        set->candidates[index].scope_depth = 1;
        set->candidates[index].scope_mass = 1;
      }
      return true;
    }
    static bool fleek_duplication_collect_namespace_methods(const pm_module_node_t *scope_node, const pm_constant_id_t *scope_names, size_t scope_depth, const pm_statements_node_t *body, const uint8_t *source, fleek_duplication_class_candidates_t *set) {
      size_t scope_index = set->scope_count++;
      size_t first_candidate = set->count;
      size_t body_count = body->body.size;
      for (size_t index = 0; index < body->body.size; index++) {
        const pm_node_t *child = body->body.nodes[index];
        if (PM_NODE_TYPE_P(child, PM_NIL_NODE)) continue;
        if (!PM_NODE_TYPE_P(child, PM_DEF_NODE) || set->count == 24 ||
            !fleek_duplication_class_method(child, source, &set->candidates[set->count])) {
          fleek_duplication_partial = 1;
          continue;
        }
        set->methods[set->count] = (const pm_def_node_t *) child;
        set->scope_indices[set->count] = scope_index;
        set->scope_lines[set->count] = fleek_source_line(source, scope_node->base.location.start);
        set->candidates[set->count].scope_kind = 2;
        set->candidates[set->count].scope_depth = scope_depth;
        set->candidates[set->count].scope_mass = scope_depth;
        for (size_t name = 0; name < scope_depth; name++) set->candidates[set->count].scope_names[name] = scope_names[name];
        set->count++;
      }
      for (size_t index = first_candidate; index < set->count; index++) {
        set->scope_body_counts[index] = body_count;
        set->scope_candidate_counts[index] = set->count - first_candidate;
      }
      return true;
    }

    static bool fleek_duplication_collect_nested_module_methods(const pm_module_node_t *scope_node, const pm_module_node_t *current, pm_constant_id_t *scope_names, size_t depth, const uint8_t *source, fleek_duplication_class_candidates_t *set) {
      if (depth == 11 || !PM_NODE_TYPE_P(current->constant_path, PM_CONSTANT_READ_NODE)) { fleek_duplication_partial = 1; return true; }
      scope_names[depth] = ((const pm_constant_read_node_t *) current->constant_path)->name;
      if (current->body == NULL) return true;
      if (!PM_NODE_TYPE_P(current->body, PM_STATEMENTS_NODE)) return false;
      const pm_statements_node_t *body = (const pm_statements_node_t *) current->body;
      if (body->body.size > 32) return false;
      bool has_method = false;
      for (size_t index = 0; index < body->body.size; index++) if (PM_NODE_TYPE_P(body->body.nodes[index], PM_DEF_NODE)) has_method = true;
      if (has_method) return fleek_duplication_collect_namespace_methods(scope_node, scope_names, depth + 1, body, source, set);
      if (body->body.size == 1 && PM_NODE_TYPE_P(body->body.nodes[0], PM_MODULE_NODE)) {
        return fleek_duplication_collect_nested_module_methods(scope_node, (const pm_module_node_t *) body->body.nodes[0], scope_names, depth + 1, source, set);
      }
      if (body->body.size == 1 && PM_NODE_TYPE_P(body->body.nodes[0], PM_CLASS_NODE)) {
        const pm_class_node_t *class_node = (const pm_class_node_t *) body->body.nodes[0];
        if (depth >= 10 || !PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE)) { fleek_duplication_partial = 1; return true; }
        size_t first_candidate = set->count;
        if (!fleek_duplication_collect_class_methods((const pm_node_t *) class_node, 1, source, set)) return false;
        scope_names[depth + 1] = ((const pm_constant_read_node_t *) class_node->constant_path)->name;
        for (size_t index = first_candidate; index < set->count; index++) {
          set->candidates[index].scope_kind = 2;
          set->candidates[index].scope_depth = depth + 2;
          set->candidates[index].scope_mass = depth + 2;
          for (size_t name = 0; name <= depth + 1; name++) set->candidates[index].scope_names[name] = scope_names[name];
          set->scope_lines[index] = fleek_source_line(source, scope_node->base.location.start);
        }
        return true;
      }
      if (body->body.size != 0) fleek_duplication_partial = 1;
      return true;
    }

    static bool fleek_duplication_collect_qualified_namespace_classes(const pm_module_node_t *module_node, const pm_constant_id_t *module_names, size_t module_name_count, const pm_statements_node_t *body, const uint8_t *source, fleek_duplication_class_candidates_t *set) {
      size_t scope_index = set->scope_count++;
      size_t first_candidate = set->count;
      size_t module_candidate_count = 0;
      size_t module_class_count = 0;
      bool module_complete = true;
      for (size_t child_index = 0; child_index < body->body.size; child_index++) {
        const pm_node_t *child = body->body.nodes[child_index];
        if (!PM_NODE_TYPE_P(child, PM_CLASS_NODE)) { fleek_duplication_partial = 1; module_complete = false; continue; }
        const pm_class_node_t *class_node = (const pm_class_node_t *) child;
        size_t class_first_candidate = set->count;
        if (!PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE) || class_node->body == NULL ||
            !PM_NODE_TYPE_P(class_node->body, PM_STATEMENTS_NODE) ||
            !fleek_duplication_collect_class_methods(child, 1, source, set)) { fleek_duplication_partial = 1; module_complete = false; continue; }
        const pm_statements_node_t *class_body = (const pm_statements_node_t *) class_node->body;
        size_t class_candidate_count = set->count - class_first_candidate;
        if (class_body->body.size == 0 || class_body->body.size != class_candidate_count) {
          fleek_duplication_partial = 1; module_complete = false;
          continue;
        }
        module_class_count++;
        for (size_t candidate = class_first_candidate; candidate < set->count; candidate++) {
          set->scope_indices[candidate] = scope_index;
          set->scope_lines[candidate] = fleek_source_line(source, module_node->base.location.start);
          set->candidates[candidate].scope_kind = 2;
          set->candidates[candidate].scope_depth = module_name_count + 1;
          for (size_t name = 0; name < module_name_count; name++) set->candidates[candidate].scope_names[name] = module_names[name];
          set->candidates[candidate].scope_names[module_name_count] = ((const pm_constant_read_node_t *) class_node->constant_path)->name;
          module_candidate_count++;
        }
      }
      for (size_t index = first_candidate; index < set->count; index++) {
        if (set->scope_indices[index] != scope_index) continue;
        set->scope_body_counts[index] = module_candidate_count + (module_complete ? 0 : 1);
        set->scope_candidate_counts[index] = module_candidate_count;
        set->candidates[index].scope_mass = module_name_count + module_class_count + 1;
      }
      return true;
    }

    static bool fleek_duplication_collect_namespace_classes(const pm_node_t *node, const uint8_t *source, fleek_duplication_class_candidates_t *set) {
      if (!PM_NODE_TYPE_P(node, PM_MODULE_NODE)) return false;
      const pm_module_node_t *module_node = (const pm_module_node_t *) node;
      pm_constant_id_t module_names[15] = { 0 };
      size_t module_name_count = 0;
      if (!fleek_duplication_constant_path_names(module_node->constant_path, module_names, 15, &module_name_count)) { fleek_duplication_partial = 1; return true; }
      set->namespace_count++;
      if (module_node->body == NULL) return true;
      if (!PM_NODE_TYPE_P(module_node->body, PM_STATEMENTS_NODE)) return false;
      const pm_statements_node_t *body = (const pm_statements_node_t *) module_node->body;
      if (body->body.size > 32) return false;
      if (module_name_count > 1) {
        if (body->body.size == 0) return true;
        if (module_name_count >= 15) { fleek_duplication_partial = 1; return true; }
        if (body->body.size > 1) return fleek_duplication_collect_qualified_namespace_classes(module_node, module_names, module_name_count, body, source, set);
        if (!PM_NODE_TYPE_P(body->body.nodes[0], PM_CLASS_NODE)) { fleek_duplication_partial = 1; return true; }
        const pm_class_node_t *class_node = (const pm_class_node_t *) body->body.nodes[0];
        size_t first_candidate = set->count;
        if (class_node->body != NULL && !PM_NODE_TYPE_P(class_node->body, PM_STATEMENTS_NODE)) { fleek_duplication_partial = 1; return true; }
        if (!PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE) ||
            !fleek_duplication_collect_class_methods((const pm_node_t *) class_node, 1, source, set)) { fleek_duplication_partial = 1; return true; }
        for (size_t index = first_candidate; index < set->count; index++) {
          set->candidates[index].scope_kind = 2;
          set->candidates[index].scope_depth = module_name_count + 1;
          set->candidates[index].scope_mass = module_name_count + 2;
          for (size_t name = 0; name < module_name_count; name++) set->candidates[index].scope_names[name] = module_names[name];
          set->candidates[index].scope_names[module_name_count] = ((const pm_constant_read_node_t *) class_node->constant_path)->name;
          set->scope_lines[index] = fleek_source_line(source, module_node->base.location.start);
        }
        return true;
      }
      for (size_t index = 0; index < body->body.size; index++) {
        if (PM_NODE_TYPE_P(body->body.nodes[index], PM_DEF_NODE)) {
          return fleek_duplication_collect_namespace_methods(module_node, module_names, module_name_count, body, source, set);
        }
      }
      if (body->body.size == 1 && PM_NODE_TYPE_P(body->body.nodes[0], PM_MODULE_NODE)) {
        return fleek_duplication_collect_nested_module_methods(module_node,
          (const pm_module_node_t *) body->body.nodes[0], module_names, module_name_count, source, set);
      }
      for (size_t index = 0; index < body->body.size; index++) {
        const pm_node_t *child = body->body.nodes[index];
        if (PM_NODE_TYPE_P(child, PM_CLASS_NODE)) {
          if (!fleek_duplication_collect_class_methods(child, 1, source, set)) return false;
        } else if (!PM_NODE_TYPE_P(child, PM_NIL_NODE)) {
          fleek_duplication_partial = 1;
        }
      }
      return true;
    }

    static size_t fleek_duplication_class_method_mass(const fleek_duplication_method_t *method) {
      size_t mass = 2 + method->shape_count + method->parameter_mass;
      for (size_t index = 0; index < method->shape_count; index++) if (fleek_duplication_class_node_massless(method->data.ast.nodes[index])) mass--;
      return mass;
    }
    static bool fleek_duplication_candidate_shapes_equal(const fleek_duplication_class_candidates_t *set, size_t left, size_t right) {
      return fleek_duplication_class_shapes_equal(&set->candidates[left], &set->candidates[right]) &&
        fleek_duplication_optional_parameter_count(set->methods[left]) == fleek_duplication_optional_parameter_count(set->methods[right]);
    }
    static bool fleek_duplication_scope_candidate_first(const fleek_duplication_class_candidates_t *set, size_t index) {
      for (size_t prior = 0; prior < index; prior++) if (set->scope_indices[prior] == set->scope_indices[index]) return false;
      return true;
    }
    static bool fleek_duplication_scope_candidate_complete(const fleek_duplication_class_candidates_t *set, size_t index) {
      return set->candidates[index].scope_kind != 0 && set->scope_candidate_counts[index] > 0 &&
        set->scope_body_counts[index] == set->scope_candidate_counts[index];
    }
    static size_t fleek_duplication_scope_method_mass(const fleek_duplication_class_candidates_t *set, size_t index) {
      size_t mass = 0;
      for (size_t candidate = 0; candidate < set->count; candidate++) {
        if (set->scope_indices[candidate] == set->scope_indices[index]) mass += fleek_duplication_class_method_mass(&set->candidates[candidate]);
      }
      return mass;
    }
    static size_t fleek_duplication_scope_mass(pm_parser_t *parser, const fleek_duplication_class_candidates_t *set, size_t index) {
      if (set->candidates[index].scope_kind != 1) return set->candidates[index].scope_mass;
      size_t mass = 0;
      size_t common_prefix = set->candidates[index].scope_depth;
      size_t unique_paths = 0;
      for (size_t candidate = 0; candidate < set->count; candidate++) {
        if (set->scope_indices[candidate] != set->scope_indices[index]) continue;
        bool duplicate_path = false;
        for (size_t prior = 0; prior < candidate; prior++) {
          if (set->scope_indices[prior] != set->scope_indices[index] || set->candidates[prior].scope_depth != set->candidates[candidate].scope_depth) continue;
          size_t name = 0;
          while (name < set->candidates[candidate].scope_depth && fleek_constants_equal(parser, set->candidates[prior].scope_names[name], set->candidates[candidate].scope_names[name])) name++;
          if (name == set->candidates[candidate].scope_depth) { duplicate_path = true; break; }
        }
        if (duplicate_path) continue;
        mass += set->candidates[candidate].scope_mass;
        size_t name = 0;
        while (name < common_prefix && fleek_constants_equal(parser, set->candidates[index].scope_names[name], set->candidates[candidate].scope_names[name])) name++;
        common_prefix = name;
        unique_paths++;
      }
      return mass - common_prefix * (unique_paths - 1);
    }
    static bool fleek_duplication_scope_candidates_equal(const fleek_duplication_class_candidates_t *set, size_t left, size_t right) {
      /* Each scope collector appends its method candidates contiguously in source order. */
      for (size_t offset = 0; offset < set->scope_candidate_counts[left]; offset++) {
        if (!fleek_duplication_candidate_shapes_equal(set, left + offset, right + offset)) return false;
      }
      return true;
    }
    static bool fleek_duplication_scope_candidates_match(const fleek_duplication_class_candidates_t *set, size_t left, size_t right, size_t mass_threshold) {
      return set->scope_indices[left] != set->scope_indices[right] &&
        fleek_duplication_scope_candidate_first(set, left) && fleek_duplication_scope_candidate_first(set, right) &&
        fleek_duplication_scope_candidate_complete(set, left) && fleek_duplication_scope_candidate_complete(set, right) &&
        set->candidates[left].scope_kind == set->candidates[right].scope_kind &&
        set->candidates[left].scope_depth == set->candidates[right].scope_depth &&
        set->scope_candidate_counts[left] == set->scope_candidate_counts[right] &&
        fleek_duplication_scope_method_mass(set, left) + 1 >= mass_threshold &&
        fleek_duplication_scope_candidates_equal(set, left, right);
    }
    static bool fleek_duplication_candidate_values_equal(pm_parser_t *parser, const fleek_duplication_class_candidates_t *set, size_t left, size_t right, bool include_scope_name) {
      const pm_def_node_t *first = set->methods[left];
      const pm_def_node_t *second = set->methods[right];
      if (include_scope_name && set->candidates[left].scope_depth != set->candidates[right].scope_depth) return false;
      if (include_scope_name) {
        for (size_t name = 0; name < set->candidates[left].scope_depth; name++) {
          if (!fleek_constants_equal(parser, set->candidates[left].scope_names[name], set->candidates[right].scope_names[name])) return false;
        }
      }
      return fleek_constants_equal(parser, first->name, second->name) &&
        fleek_duplication_class_parameters_equal(parser, first, second) &&
        fleek_duplication_class_values_equal(parser, &set->candidates[left], &set->candidates[right]);
    }
    static bool fleek_duplication_has_partial_subtree(const fleek_duplication_class_candidates_t *set, int mass_threshold) {
      for (size_t left = 0; left < set->count; left++) {
        for (size_t right = left + 1; right < set->count; right++) {
          bool same_shape = fleek_duplication_candidate_shapes_equal(set, left, right);
          size_t mass = fleek_duplication_class_method_mass(&set->candidates[left]);
          if (same_shape && fleek_duplication_scope_candidates_match(set, left, right, (size_t) mass_threshold)) continue;
          if (same_shape && mass >= (size_t) mass_threshold) continue;
          for (size_t left_node = 0; left_node < set->candidates[left].shape_count; left_node++) {
            for (size_t right_node = 0; right_node < set->candidates[right].shape_count; right_node++) {
              size_t left_mass = fleek_duplication_class_subtree_mass(&set->candidates[left], left_node);
              size_t right_mass = fleek_duplication_class_subtree_mass(&set->candidates[right], right_node);
              if (left_mass >= (size_t) mass_threshold && left_mass == right_mass &&
                  fleek_duplication_class_subtrees_equal(&set->candidates[left], left_node, &set->candidates[right], right_node)) return true;
            }
          }
        }
      }
      return false;
    }
    static bool fleek_duplication_emit_scope_groups(pm_parser_t *parser, const fleek_duplication_class_candidates_t *set, int mass_threshold, bool *covered) {
      bool grouped[24] = { false };
      for (size_t first = 0; first < set->count; first++) {
        if (grouped[first] || !fleek_duplication_scope_candidate_first(set, first) || !fleek_duplication_scope_candidate_complete(set, first)) continue;
        size_t members[24] = { first };
        size_t count = 1;
        for (size_t candidate = first + 1; candidate < set->count; candidate++) {
          if (grouped[candidate] || !fleek_duplication_scope_candidate_first(set, candidate) || !fleek_duplication_scope_candidate_complete(set, candidate) ||
              !fleek_duplication_scope_candidates_match(set, first, candidate, (size_t) mass_threshold)) continue;
          members[count++] = candidate;
        }
        if (count < 2) continue;
        int lines[24] = { 0 };
        bool identical = true;
        for (size_t index = 0; index < count; index++) {
          size_t candidate = members[index];
          lines[index] = set->scope_lines[candidate];
          for (size_t offset = 0; offset < set->scope_candidate_counts[candidate]; offset++) {
            size_t first_method = members[0] + offset;
            size_t candidate_method = candidate + offset;
            covered[candidate_method] = true;
            grouped[candidate_method] = true;
            if (!fleek_duplication_candidate_values_equal(parser, set, first_method, candidate_method, true)) identical = false;
          }
        }
        const char *node = set->candidates[first].scope_kind == 1 ? "class" : "module";
        size_t node_mass = fleek_duplication_scope_method_mass(set, first) + fleek_duplication_scope_mass(parser, set, first);
        if (!fleek_duplication_append_group(node, identical, node_mass, lines, count)) return false;
      }
      return true;
    }
    static bool fleek_duplication_emit_method_groups(pm_parser_t *parser, const fleek_duplication_class_candidates_t *set, int mass_threshold, const bool *covered) {
      bool grouped[24] = { false };
      for (size_t first = 0; first < set->count; first++) {
        if (grouped[first]) continue;
        size_t members[24] = { first };
        size_t count = 1;
        for (size_t candidate = first + 1; candidate < set->count; candidate++) {
          if (!grouped[candidate] && fleek_duplication_candidate_shapes_equal(set, first, candidate)) members[count++] = candidate;
        }
        if (count < 2) continue;
        for (size_t index = 0; index < count; index++) grouped[members[index]] = true;
        bool pruned = false;
        bool identical = true;
        int lines[24] = { 0 };
        for (size_t index = 0; index < count; index++) {
          size_t candidate = members[index];
          if (covered[candidate]) pruned = true;
          lines[index] = set->candidates[candidate].line;
          if (!fleek_duplication_candidate_values_equal(parser, set, members[0], candidate, false)) identical = false;
        }
        size_t node_mass = fleek_duplication_class_method_mass(&set->candidates[first]);
        if (!pruned && node_mass >= (size_t) mass_threshold &&
            !fleek_duplication_append_group("defn", identical, node_mass, lines, count)) return false;
      }
      return true;
    }
    static bool fleek_duplication_analyze_scoped_candidates(pm_parser_t *parser, const fleek_duplication_class_candidates_t *set, int mass_threshold) {
      if (fleek_duplication_has_partial_subtree(set, mass_threshold)) return false;
      bool covered[24] = { false };
      return fleek_duplication_emit_scope_groups(parser, set, mass_threshold, covered) &&
        fleek_duplication_emit_method_groups(parser, set, mass_threshold, covered);
    }

    static bool fleek_ffi_declaration_module(const pm_node_t *node, pm_parser_t *parser) {
      if (!PM_NODE_TYPE_P(node, PM_MODULE_NODE)) return false;
      const pm_module_node_t *module_node = (const pm_module_node_t *) node;
      if (!PM_NODE_TYPE_P(module_node->constant_path, PM_CONSTANT_READ_NODE) || module_node->body == NULL || !PM_NODE_TYPE_P(module_node->body, PM_STATEMENTS_NODE)) return false;
      const pm_statements_node_t *body = (const pm_statements_node_t *) module_node->body;
      if (body->body.size != 1 || !PM_NODE_TYPE_P(body->body.nodes[0], PM_CALL_NODE)) return false;
      const pm_call_node_t *declaration = (const pm_call_node_t *) body->body.nodes[0];
      pm_constant_t *name = pm_constant_pool_id_to_constant(&parser->constant_pool, declaration->name);
      return declaration->receiver == NULL && declaration->block == NULL && name->length == 8 && memcmp(name->start, "ffi_func", 8) == 0;
    }

    static bool fleek_constants_equal(pm_parser_t *parser, pm_constant_id_t left, pm_constant_id_t right) {
      pm_constant_t *left_constant = pm_constant_pool_id_to_constant(&parser->constant_pool, left);
      pm_constant_t *right_constant = pm_constant_pool_id_to_constant(&parser->constant_pool, right);
      return left_constant->length == right_constant->length && memcmp(left_constant->start, right_constant->start, left_constant->length) == 0;
    }

    static bool fleek_duplication_methods_identical(pm_parser_t *parser, const pm_def_node_t *left, const pm_def_node_t *right) {
      if (!fleek_constants_equal(parser, left->name, right->name)) return false;
      const pm_statements_node_t *left_body = (const pm_statements_node_t *) left->body;
      const pm_statements_node_t *right_body = (const pm_statements_node_t *) right->body;
      for (size_t index = 0; index < left_body->body.size; index++) {
        const pm_node_t *left_statement = left_body->body.nodes[index];
        const pm_node_t *right_statement = right_body->body.nodes[index];
        if (PM_NODE_TYPE_P(left_statement, PM_CALL_NODE) && PM_NODE_TYPE_P(right_statement, PM_CALL_NODE)) {
          if (!fleek_constants_equal(parser, ((const pm_call_node_t *) left_statement)->name, ((const pm_call_node_t *) right_statement)->name)) return false;
        } else if (PM_NODE_TYPE_P(left_statement, PM_INTEGER_NODE) && PM_NODE_TYPE_P(right_statement, PM_INTEGER_NODE)) {
          if (pm_integer_compare(&((const pm_integer_node_t *) left_statement)->value, &((const pm_integer_node_t *) right_statement)->value) != 0) return false;
        } else if (PM_NODE_TYPE_P(left_statement, PM_AND_NODE) && PM_NODE_TYPE_P(right_statement, PM_AND_NODE)) {
          const pm_and_node_t *left_and = (const pm_and_node_t *) left_statement;
          const pm_and_node_t *right_and = (const pm_and_node_t *) right_statement;
          if (pm_integer_compare(&((const pm_integer_node_t *) left_and->left)->value, &((const pm_integer_node_t *) right_and->left)->value) != 0) return false;
        } else {
          return false;
        }
      }
      return true;
    }

    int fleek_structural_duplication(const char *source, size_t length, int mass_threshold) {
      fleek_duplication_buffer[0] = 0;
      fleek_duplication_buffer_used = 0;
      fleek_duplication_total_score = 0;
      fleek_duplication_partial = 0;
      if (memchr(source, 0, length) != NULL) return FLEEK_DUPLICATION_NUL_SOURCE;
      pm_options_t options = {0};
      options.line = 1;
      options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser;
      pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_PARSE_ERROR;
      }
      if (!PM_NODE_TYPE_P(root, PM_PROGRAM_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
      }
      const pm_program_node_t *program = (const pm_program_node_t *) root;
      if (program->statements == NULL) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
      }
      fleek_duplication_method_t first_method = {0}, second_method = {0};
      const pm_def_node_t *methods[2] = { NULL, NULL };
      fleek_duplication_class_candidates_t class_candidates = {0};
      size_t method_count = 0;
      size_t scope_count = 0;
      size_t ffi_module_count = 0;
      for (size_t index = 0; index < program->statements->body.size; index++) {
        pm_node_t *statement = program->statements->body.nodes[index];
        if (PM_NODE_TYPE_P(statement, PM_CLASS_NODE)) {
          if (method_count != 0 || ffi_module_count != 0 || !fleek_duplication_collect_class_methods(statement, 1, (const uint8_t *) source, &class_candidates)) {
            pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
          }
          scope_count++;
          continue;
        }
        if (PM_NODE_TYPE_P(statement, PM_MODULE_NODE)) {
          if (method_count != 0 || ffi_module_count != 0) {
            pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
          }
          if (fleek_ffi_declaration_module(statement, &parser)) {
            if (scope_count != 0 || class_candidates.count != 0) {
              pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
            }
            ffi_module_count++;
          } else if (!fleek_duplication_collect_namespace_classes(statement, (const uint8_t *) source, &class_candidates)) {
            pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
          } else {
            scope_count = class_candidates.scope_count;
          }
          continue;
        }
        if (!PM_NODE_TYPE_P(statement, PM_DEF_NODE) || scope_count != 0) {
          if (!PM_NODE_TYPE_P(statement, PM_NIL_NODE)) {
            pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
          }
          continue;
        }
        if (method_count == 2 || !fleek_duplication_method(statement, (const uint8_t *) source, method_count == 0 ? &first_method : &second_method)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
        }
        methods[method_count++] = (const pm_def_node_t *) statement;
      }
      if (scope_count != 0) {
        if (method_count != 0) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
        }
        if (class_candidates.count < 2) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
        }
        if (!fleek_duplication_analyze_scoped_candidates(&parser, &class_candidates, mass_threshold)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
        }
        int score = fleek_duplication_total_score;
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
        return score;
      }
      if (class_candidates.namespace_count != 0 && scope_count == 0 && method_count == 0) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
      }
      if (method_count != 2) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
      }
      const pm_def_node_t *first = methods[0];
      const pm_def_node_t *second = methods[1];
      size_t mass = 2 + first_method.shape_count + first_method.parameter_mass;
      for (size_t index = 0; index < first_method.shape_count; index++) {
        if (first_method.data.shapes[index] == FLEEK_DUPLICATION_RUBY4_AND_STATEMENT) mass += 2;
      }
      bool same_shape = first_method.shape_count == second_method.shape_count;
      for (size_t index = 0; same_shape && index < first_method.shape_count; index++) same_shape = first_method.data.shapes[index] == second_method.data.shapes[index];
      bool identical = same_shape && fleek_duplication_methods_identical(&parser, first, second);
      if (same_shape && mass >= (size_t) mass_threshold) {
        int lines[2] = { first_method.line, second_method.line };
        if (!fleek_duplication_append_group("defn", identical, mass, lines, 2)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
        }
      }
      int score = fleek_duplication_total_score;
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return score;
    }

    const char *fleek_structural_duplication_finding(void) { return fleek_duplication_buffer; }
    int fleek_structural_duplication_partial(void) { return fleek_duplication_partial; }

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
    ffi_func :fleek_attribute, [:str, :size_t], :int
    ffi_func :fleek_attribute_finding, [], :str
    ffi_func :fleek_instance_variable_assumption, [:str, :size_t], :int
    ffi_func :fleek_instance_variable_assumption_finding, [], :str
    ffi_func :fleek_subclassed_from_core_class, [:str, :size_t], :int
    ffi_func :fleek_subclassed_from_core_class_finding, [], :str
    ffi_func :fleek_module_initialize, [:str, :size_t], :int
    ffi_func :fleek_module_initialize_finding, [], :str
    ffi_func :fleek_irresponsible_module, [:str, :size_t], :int
    ffi_func :fleek_irresponsible_module_finding, [], :str
    ffi_func :fleek_long_parameter_list, [:str, :size_t, :size_t], :int
    ffi_func :fleek_long_parameter_list_finding, [], :str
    ffi_func :fleek_boolean_parameter, [:str, :size_t], :int
    ffi_func :fleek_boolean_parameter_finding, [], :str
    ffi_func :fleek_long_yield_list, [:str, :size_t, :size_t], :int
    ffi_func :fleek_long_yield_list_finding, [], :str
    ffi_func :fleek_control_parameter, [:str, :size_t], :int
    ffi_func :fleek_control_parameter_finding, [], :str
    ffi_func :fleek_unused_parameters, [:str, :size_t], :int
    ffi_func :fleek_unused_parameters_finding, [], :str
    ffi_func :fleek_utility_function, [:str, :size_t], :int
    ffi_func :fleek_utility_function_finding, [], :str
    ffi_func :fleek_duplicate_method_call, [:str, :size_t, :size_t, :str], :int
    ffi_func :fleek_duplicate_method_call_finding, [], :str
    ffi_func :fleek_manual_dispatch, [:str, :size_t], :int
    ffi_func :fleek_manual_dispatch_finding, [], :str
    ffi_func :fleek_nil_check, [:str, :size_t], :int
    ffi_func :fleek_nil_check_finding, [], :str
    ffi_func :fleek_missing_safe_method, [:str, :size_t], :int
    ffi_func :fleek_missing_safe_method_finding, [], :str
    ffi_func :fleek_repeated_conditional, [:str, :size_t, :size_t], :int
    ffi_func :fleek_repeated_conditional_finding, [], :str
    ffi_func :fleek_nested_iterators, [:str, :size_t, :size_t, :str], :int
    ffi_func :fleek_nested_iterators_finding, [], :str
    ffi_func :fleek_feature_envy, [:str, :size_t], :int
    ffi_func :fleek_feature_envy_finding, [], :str
    ffi_func :fleek_data_clump, [:str, :size_t, :size_t, :size_t], :int
    ffi_func :fleek_data_clump_finding, [], :str
    ffi_func :fleek_too_many_constants, [:str, :size_t, :size_t], :int
    ffi_func :fleek_too_many_constants_finding, [], :str
    ffi_func :fleek_too_many_instance_variables, [:str, :size_t, :size_t], :int
    ffi_func :fleek_too_many_instance_variables_finding, [], :str
    ffi_func :fleek_too_many_methods, [:str, :size_t, :size_t], :int
    ffi_func :fleek_too_many_methods_finding, [], :str
    ffi_func :fleek_too_many_statements, [:str, :size_t, :size_t], :int
    ffi_func :fleek_too_many_statements_finding, [], :str
    ffi_func :fleek_uncommunicative_method_name, [:str, :size_t, :str, :str], :int
    ffi_func :fleek_uncommunicative_method_name_finding, [], :str
    ffi_func :fleek_uncommunicative_module_name, [:str, :size_t, :str, :str], :int
    ffi_func :fleek_uncommunicative_module_name_finding, [], :str
    ffi_func :fleek_uncommunicative_parameter_name, [:str, :size_t, :str, :str], :int
    ffi_func :fleek_uncommunicative_parameter_name_finding, [], :str
    ffi_func :fleek_uncommunicative_variable_name, [:str, :size_t, :str, :str], :int
    ffi_func :fleek_uncommunicative_variable_name_finding, [], :str
    ffi_func :fleek_structural_duplication, [:str, :size_t, :int], :int
    ffi_func :fleek_structural_duplication_finding, [], :str
    ffi_func :fleek_structural_duplication_partial, [], :int
  end

  # Imports the deliberately bounded Reek YAML subset used by this check.
  # :reek:ControlParameter
  # :reek:DataClump
  # :reek:DuplicateMethodCall
  # :reek:FeatureEnvy
  # :reek:InstanceVariableAssumption
  # :reek:LongParameterList
  # :reek:RepeatedConditional
  # :reek:TooManyInstanceVariables
  # :reek:TooManyMethods
  # :reek:TooManyStatements
  # :reek:UnusedParameters
  # :reek:UtilityFunction
  class ReekConfiguration
    OPT_IN_DETECTORS = %w[UnusedPrivateMethod].freeze
    DETECTORS = (CheckProfiles::DEFAULT_CHECKS.select { |check| check.start_with?("reek:") }.map { |check| check.delete_prefix("reek:") } + OPT_IN_DETECTORS).freeze

    def initialize
      @error = ""
      @excludes = []
      @exclude_paths = []
      @scope_paths = []
      @scope_excludes = []
      @detector_enabled = []
      @scope_detector_enabled = []
      @detector_settings = []
      @scope_detector_settings = []
      @detector_excludes = []
      @scope_detector_excludes = []
      @list_detector = ""
      @list_setting = ""
    end

    def self.load(explicit_path)
      path = explicit_path.empty? ? discovered_path : explicit_path
      configuration = ReekConfiguration.new
      configuration.read(path) unless path.empty?
      configuration
    end

    def self.discovered_path
      directory = Dir.pwd
      loop do
        candidate = "#{directory}/.reek.yml"
        return candidate if File.file?(candidate)
        parent = File.dirname(directory)
        break if parent == directory
        directory = parent
      end
      home = File.expand_path("~/.reek.yml")
      File.file?(home) ? home : ""
    end

    def error
      @error
    end

    def read(path)
      @path = path
      source = File.read(path)
      parse(source)
    rescue SystemCallError
      @error = "file cannot be read: #{Fleek.quote_text(path)}"
    end

    def parse(source)
      @section = ""
      @global_detector = ""
      @scope_detector = ""
      @scope_index = -1
      @list_target = ""
      source.lines.each_with_index { |line, index| parse_line(line, index + 1) }
    end

    def parse_line(line, number)
      return unless @error.empty?
      content = line.strip
      return if content.empty? || content.start_with?("#") || content == "---" || content == "..."

      indentation = line.length - line.lstrip.length
      @current_indentation = indentation
      return parse_list_item(content, indentation, number) if content.start_with?("-")

      key, value = mapping_entry(content, number)
      return if key.empty?
      @list_target = ""
      return parse_root(key, value, number) if indentation == 0
      return parse_detector_field(key, value, number) if @section == "detectors"
      return parse_directory_field(key, value, number) if @section == "directories"
      return parse_exclude_path(key, value, indentation, number) if @section == "exclude_paths"

      fail_config(number, "unexpected indentation or key #{key}")
    end

    def parse_root(key, value, number)
      unless ["detectors", "directories", "exclude_paths"].include?(key) && value.empty?
        fail_config(number, "unsupported Reek YAML key #{key}")
        return
      end
      @section = key
      @list_target = "exclude_paths" if key == "exclude_paths"
    end

    def parse_detector_field(key, value, number)
      indentation = line_indentation
      detector = @global_detector
      if detector_mapping?(indentation, key, value, 2)
        @global_detector = key
        @list_target = ""
      elsif indentation == 2
        fail_config(number, "unsupported enabled detector #{key}")
      elsif !detector.empty? && indentation == 4
        parse_detector_option(key, value, number, detector, false)
      elsif append_detector_list_item(value, number, indentation, detector, false)
        return
      else
        fail_config(number, "unsupported detector setting #{key}")
      end
    end

    def parse_directory_field(key, value, number)
      indentation = line_indentation
      if indentation == 2
        return fail_config(number, "directory scope must use a mapping") unless value.empty?
        @scope_paths << scalar(key, number)
        @scope_excludes << ""
        @scope_index = @scope_paths.length - 1
        @scope_detector = ""
      elsif detector_mapping?(indentation, key, value, 4) && @scope_index >= 0
        @scope_detector = key
      elsif indentation == 4
        fail_config(number, "unsupported enabled directory detector #{key}")
      elsif indentation == 6 && !@scope_detector.empty?
        parse_detector_option(key, value, number, @scope_detector, true)
      elsif append_detector_list_item(value, number, indentation, @scope_detector, true)
        return
      else
        fail_config(number, "unsupported directory setting #{key}")
      end
    end

    def append_detector_list_item(value, number, indentation, detector, scoped)
      expected = scoped ? 8 : 6
      setting_target = scoped ? "scope_detector_setting" : "global_detector_setting"
      exclusion_target = scoped ? "scope_excludes" : "global_excludes"
      return false unless indentation == expected && !detector.empty?
      return false unless @list_target == setting_target || @list_target == exclusion_target
      append_list_item(value, number)
      true
    end

    def detector_mapping?(indentation, key, value, expected_indentation)
      indentation == expected_indentation && DETECTORS.include?(key) && value.empty?
    end

    def exclusion_list?(indentation, detector, expected_indentation, target)
      indentation == expected_indentation && !detector.empty? && @list_target == target
    end

    def parse_exclude_path(key, value, indentation, number)
      fail_config(number, "exclude_paths accepts a YAML list; unexpected key #{key}")
    end

    def parse_options(key, value, number, detector, scoped)
      if key == "exclude" && value.empty?
        clear_context_excludes(detector, scoped)
        @list_target = scoped ? "scope_excludes" : "global_excludes"
      elsif key == "exclude" && value == "[]"
        clear_context_excludes(detector, scoped)
      else
        fail_config(number, "unsupported #{detector} setting #{key}")
      end
    end

    def clear_context_excludes(detector, scoped)
      if detector == "ClassVariable"
        scoped ? @scope_excludes[@scope_index] = "" : @excludes = []
      elsif scoped
        prefix = "#{@scope_index}:#{detector}="
        @scope_detector_excludes.reject! { |entry| entry.start_with?(prefix) }
      else
        prefix = "#{detector}="
        @detector_excludes.reject! { |entry| entry.start_with?(prefix) }
      end
    end

    def parse_detector_option(key, value, number, detector, scoped)
      if key == "enabled" && ["true", "false"].include?(value)
        if scoped
          @scope_detector_enabled << "#{@scope_index}:#{detector}=#{value}"
        else
          @detector_enabled << "#{detector}=#{value}"
        end
      elsif detector == "MissingSafeMethod" && key == "exclude"
        parse_setting_list(key, value, number, detector, scoped)
      elsif list_detector_setting?(detector, key)
        parse_setting_list(key, value, number, detector, scoped)
      elsif key == "exclude"
        parse_options(key, value, number, detector, scoped)
      elsif valid_detector_setting?(detector, key, value)
        settings = scoped ? @scope_detector_settings : @detector_settings
        settings << [scoped ? @scope_index : -1, detector, key, value]
      else
        fail_config(number, "unsupported detector setting #{key}")
      end
    end

    def list_detector_setting?(detector, key)
      (detector == "DuplicateMethodCall" && key == "allow_calls") ||
        (detector == "NestedIterators" && key == "ignore_iterators") ||
        (detector.start_with?("Uncommunicative") && ["reject", "accept"].include?(key))
    end

    def parse_setting_list(key, value, number, detector, scoped)
      unless value.empty? || value == "[]"
        fail_config(number, "unsupported #{detector} setting #{key}")
        return
      end
      settings = scoped ? @scope_detector_settings : @detector_settings
      settings.reject! { |setting| setting[0] == (scoped ? @scope_index : -1) && setting[1] == detector && setting[2] == key }
      settings << [scoped ? @scope_index : -1, detector, key, ""]
      @list_detector = detector
      @list_setting = key
      @list_target = value == "[]" ? "" : scoped ? "scope_detector_setting" : "global_detector_setting"
    end

    def valid_detector_setting?(detector, key, value)
      return value.match?(/\A[0-9]+\z/) if key == "max_params" && ["LongParameterList", "LongYieldList"].include?(detector)
      return value.match?(/\A[0-9]+\z/) if key == "max_calls" && detector == "DuplicateMethodCall"
      return value.match?(/\A[0-9]+\z/) if key == "max_ifs" && detector == "RepeatedConditional"
      return value.match?(/\A[0-9]+\z/) if key == "max_allowed_nesting" && detector == "NestedIterators"
      return value.match?(/\A[0-9]+\z/) if key == "max_copies" && detector == "DataClump"
      return value.match?(/\A[0-9]+\z/) if key == "min_clump_size" && detector == "DataClump"
      return value.match?(/\A[0-9]+\z/) if key == "max_constants" && detector == "TooManyConstants"
      return value.match?(/\A[0-9]+\z/) if key == "max_instance_variables" && detector == "TooManyInstanceVariables"
      return value.match?(/\A[0-9]+\z/) if key == "max_methods" && detector == "TooManyMethods"
      return value.match?(/\A[0-9]+\z/) if key == "max_statements" && detector == "TooManyStatements"
      detector == "UtilityFunction" && key == "public_methods_only" && ["true", "false"].include?(value)
    end

    def parse_list_item(content, indentation, number)
      expected = if @list_target == "exclude_paths"
                   2
                 elsif @list_target == "global_excludes"
                   6
                 elsif @list_target == "scope_excludes"
                   8
                 elsif @list_target == "global_detector_setting"
                   6
                 elsif @list_target == "scope_detector_setting"
                   8
                 else
                   -1
                 end
      return fail_config(number, "unexpected YAML list item") if indentation != expected

      append_list_item(content[1..].strip, number)
    end

    def append_list_item(value, number)
      item = scalar(value, number)
      if @list_target == "exclude_paths"
        @exclude_paths << item
      elsif @list_target == "global_excludes"
        @global_detector == "ClassVariable" ? @excludes << item : @detector_excludes << "#{@global_detector}=#{item}"
      elsif @list_target == "scope_excludes"
        if @scope_detector == "ClassVariable"
          @scope_excludes[@scope_index] = "#{@scope_excludes[@scope_index]}#{item}\n"
        else
          @scope_detector_excludes << "#{@scope_index}:#{@scope_detector}=#{item}"
        end
      elsif @list_target == "global_detector_setting"
        @detector_settings << [-1, @list_detector, @list_setting, item]
      elsif @list_target == "scope_detector_setting"
        @scope_detector_settings << [@scope_index, @list_detector, @list_setting, item]
      else
        fail_config(number, "unexpected YAML list item")
      end
    end

    def mapping_entry(content, number)
      separator = content.index(":")
      unless separator
        fail_config(number, "malformed YAML mapping")
        return ["", ""]
      end
      key = content[0...separator].strip
      value = content[(separator + 1)..].strip
      [scalar(key, number), clean_value(value)]
    end

    def clean_value(value)
      comment = value.index(" #")
      comment ? value[0...comment].strip : value
    end

    def scalar(value, number)
      value = value.strip
      if value.start_with?("'", '"')
        quote = value[0]
        unless value.end_with?(quote) && value.length >= 2 && !value[1...-1].include?("\\")
          fail_config(number, "unsupported quoted scalar")
          return ""
        end
        value[1...-1]
      elsif invalid_yaml_scalar?(value)
        fail_config(number, "unsupported YAML scalar")
        ""
      else
        value
      end
    end

    def line_indentation
      @current_indentation
    end

    def invalid_yaml_scalar?(value)
      value.empty? || ["[", ",", "{", "}", ": "].any? { |part| value.include?(part) } || value.end_with?(":")
    end

    def fail_config(number, message)
      @error = "#{Fleek.quote_text(@path)}:#{number}: #{message}" if @error.empty?
    end

    def disabled_for?(path)
      index = best_scope(path)
      !effective_detector_enabled("ClassVariable", index)
    end

    def detector_enabled_for?(name, path)
      effective_detector_enabled(name, best_scope(path))
    end

    def detector_enabled_anywhere?(name, paths)
      return effective_detector_enabled(name, -1) if paths.empty?
      paths.any? { |path| effective_detector_enabled(name, best_scope(path)) }
    end

    def enabled_opt_in_detectors(paths)
      OPT_IN_DETECTORS.select { |name| detector_enabled_anywhere?(name, paths) }
    end

    def detector_setting(name, key, path)
      scope_index = best_scope(path)
      scoped = @scope_detector_settings.select { |setting| setting[0] == scope_index && setting[1] == name && setting[2] == key }
      values = scoped.empty? ? @detector_settings.select { |setting| setting[1] == name && setting[2] == key } : scoped
      return nil if values.empty?
      values.map { |setting| setting[3] }.reject(&:empty?).join("\n")
    end

    def excluded_method_name?(path, name)
      (detector_setting("MissingSafeMethod", "exclude", path) || "").split("\n").include?(name)
    end

    def effective_detector_enabled(name, scope_index)
      default = name != "UnusedPrivateMethod"
      if scope_index >= 0
        scope_setting = @scope_detector_enabled.find { |setting| setting.start_with?("#{scope_index}:#{name}=") }
        return false if scope_setting == "#{scope_index}:#{name}=false"
        return true if scope_setting == "#{scope_index}:#{name}=true"
      end
      global_setting = @detector_enabled.find { |setting| setting.start_with?("#{name}=") }
      return false if global_setting == "#{name}=false"
      global_setting == "#{name}=true" || default
    end

    def excluded_context?(path, context, detector = "ClassVariable")
      index = best_scope(path)
      return excluded_class_variable_context?(index, context) if detector == "ClassVariable"
      scoped = @scope_detector_excludes.select { |entry| entry.start_with?("#{index}:#{detector}=") }.map { |entry| entry.split("=", 2)[1] }
      exclusions = scoped.empty? ? detector_excludes(detector) : scoped
      exclusions.any? { |excluded| context.include?(excluded) }
    end

    def excluded_class_variable_context?(index, context)
      exclusions = index >= 0 ? @scope_excludes[index].split("\n") : @excludes
      exclusions.any? { |excluded| context.include?(excluded) }
    end

    def detector_excludes(detector)
      @detector_excludes.select { |entry| entry.start_with?("#{detector}=") }.map { |entry| entry.split("=", 2)[1] }
    end

    def excluded_path?(path)
      actual = File.expand_path(path)
      @exclude_paths.any? do |pattern|
        File.fnmatch?(File.expand_path(pattern), actual) || actual.start_with?("#{File.expand_path(pattern)}/")
      end
    end

    def best_scope(path)
      directory = File.expand_path(File.dirname(path))
      selected = -1
      @scope_paths.each_with_index do |pattern, index|
        expanded = File.expand_path(pattern)
        matches = directory == expanded || directory.start_with?("#{expanded}/") || File.fnmatch?(expanded, directory)
        selected = index if matches && (selected < 0 || pattern.length > @scope_paths[selected].length)
      end
      selected
    end
  end

  def self.print_help
    puts "Usage: fleek [--help | --version]"
    print_analysis_usage
    print_help_identity
    print_help_reporting
  end

  def self.print_help_identity
    puts "Fleek #{VERSION} is a native Ruby analysis CLI."
    puts "References: Flay #{FLAY_REFERENCE}; Reek #{REEK_REFERENCE}."
    puts "Compiler: Spinel #{SPINEL_RELEASE}."
  end

  def self.print_help_reporting
    puts "Supported checks: reek:Attribute, reek:ClassVariable, reek:InstanceVariableAssumption, reek:IrresponsibleModule, reek:ModuleInitialize, reek:SubclassedFromCoreClass, and flay:StructuralDuplication; other checks and machine formats are unsupported."
    puts "Analysis requires --checks; selected and run checks are shown separately."
    puts "Select both with --checks flay:StructuralDuplication,reek:ClassVariable; .flayignore and Reek exclusions apply separately."
    puts "Report: stable text v1; diagnostics on stderr; uncovered checks are reported as not run."
  end

  def self.print_analysis_usage
    puts "       fleek --parse-ruby4 SOURCE (parser prototype; runs no checks)"
    puts "       fleek --checks reek:ClassVariable[,flay:StructuralDuplication] [--reek-config FILE] SOURCE"
    puts "       fleek --checks flay:StructuralDuplication,reek:ClassVariable [--mass MASS] [--reek-config FILE] SOURCE..."
    puts "       fleek --checks reek:ClassVariable [--reek-config FILE] --stdin SOURCE [PATH...]"
    puts "       fleek --checks flay:StructuralDuplication [--mass MASS] SOURCE"
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
    puts "Fleek #{VERSION} (Flay #{FLAY_REFERENCE}; Reek #{REEK_REFERENCE}; Spinel #{SPINEL_RELEASE}; supported checks: reek:Attribute, reek:ClassVariable, reek:InstanceVariableAssumption, reek:IrresponsibleModule, reek:ModuleInitialize, reek:SubclassedFromCoreClass, flay:StructuralDuplication; report: text v1)"
    puts "Analysis requires explicit --checks selection; unsupported checks and machine formats are rejected."
    0
  end

  def self.input_error(arguments)
    if arguments.empty?
      "ERROR: Select supported checks and source inputs."
    else
      "ERROR: Requested check or input is unsupported in this release."
    end
  end

  def self.unsupported_format_requested?(arguments)
    arguments.include?("--format") || arguments.include?("--json") || arguments.include?("--yaml") || arguments.include?("--sarif") || arguments.any? { |argument| argument.start_with?("--format=") }
  end

  def self.report_unsupported_format
    warn "ERROR: Unsupported output format; only stable text output is available."
    1
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
    warn "Use long options: --checks, --mass, and --reek-config."
    warn "Usage: fleek [--help | --version]"
    1
  end

  def self.parse_ruby4_requested?(arguments)
    arguments.length == 2 && arguments[0] == "--parse-ruby4"
  end

  # :reek:BooleanParameter
  def self.run_structural_duplication(inputs, joint_run = false)
    ignore_patterns, input_error = duplication_analysis_options(inputs)
    return report_duplication_input_failure(input_error) unless input_error == ""
    report = duplication_input_report(inputs, ignore_patterns)
    read_and_analyze_duplication(report, joint_run)
  end

  def self.duplication_analysis_options(inputs)
    input_error = structural_duplication_input_error(inputs)
    return [[], input_error] unless input_error.length.zero?
    load_flay_ignore_patterns
  end

  def self.duplication_input_report(inputs, ignore_patterns)
    files, errors = discover_sources(duplication_source_paths(inputs), ReekConfiguration.new)
    included, excluded = partition_flay_sources(files, ignore_patterns)
    DuplicationReport.new(included, errors.sort_by(&:path), [], duplication_mass_threshold(inputs), excluded, nil, nil, false, [], "included")
  end

  def self.partition_flay_sources(files, patterns)
    included, excluded = files.partition { |path| !flay_ignored?(path, patterns) }
    [included.sort, excluded.sort]
  end

  def self.load_flay_ignore_patterns
    File.file?(".flayignore") ? [File.read(".flayignore").split("\n"), ""] : [[], ""]
  rescue SystemCallError
    [[], "Cannot read .flayignore."]
  end

  def self.flay_ignored?(path, patterns)
    patterns.any? { |pattern| flay_ignore_match?(path, pattern) }
  end

  def self.flay_ignore_match?(path, pattern)
    absolute_pattern = File.expand_path(pattern)
    absolute_path = File.expand_path(path)
    return File.fnmatch?(absolute_pattern.chomp("/"), File.dirname(absolute_path), File::FNM_PATHNAME) if pattern.end_with?("/")
    File.fnmatch?(absolute_pattern, absolute_path, pattern.include?("/") ? 0 : File::FNM_PATHNAME)
  end

  def self.structural_duplication_input_error(inputs)
    mass_error = duplication_mass_error(inputs)
    return mass_error unless mass_error.empty?
    duplication_source_input_error(inputs)
  end

  def self.duplication_mass_error(inputs)
    return "--mass may be specified only once." if inputs.count("--mass") > 1
    mass_index = duplication_mass_index(inputs)
    return "" if mass_index == inputs.length
    return "" if valid_duplication_mass?(inputs[mass_index + 1])
    "--mass requires an integer from 3 through 2147483647 for the supported syntax."
  end

  def self.valid_duplication_mass?(mass_value)
    return false unless mass_value && mass_value.match?(/\A[0-9]+\z/)
    mass = mass_value.to_i
    mass >= 3 && mass <= 2_147_483_647
  end

  def self.duplication_source_input_error(inputs)
    unsupported_option = inputs.find { |input| input.start_with?("-") && input != "--mass" }
    return "Unsupported Flay option: #{quote_text(unsupported_option)}" if unsupported_option
    return "flay:StructuralDuplication requires at least one Ruby source path." if duplication_source_paths(inputs).empty?
    ""
  end

  def self.duplication_source_paths(inputs)
    mass_index = duplication_mass_index(inputs)
    inputs.take(mass_index) + inputs.drop([mass_index + 2, inputs.length].min)
  end

  def self.duplication_mass_index(inputs)
    inputs.index("--mass") || inputs.length
  end

  def self.duplication_mass_threshold(inputs)
    mass_index = duplication_mass_index(inputs)
    inputs.fetch(mass_index + 1, NativePrism::FLAY_DEFAULT_MASS).to_i
  end

  def self.duplication_path_error(path)
    quoted_path = quote_text(path)
    return "Expected Ruby source (.rb): #{quoted_path}" unless path.end_with?(".rb")
    return "Cannot read source file: #{quoted_path}" unless File.file?(path) && File.readable?(path)
    ""
  end

  # :reek:BooleanParameter
  def self.read_and_analyze_duplication(report, combined_input = false)
    paths = report.paths
    return report_without_duplication_sources(report, combined_input) if paths.empty?
    report.source, report.source_map = combine_duplication_sources(paths)
    analyze_structural_duplication(report, combined_input)
  rescue SystemCallError
    report_duplication_read_failure(report, combined_input)
  end

  # :reek:BooleanParameter
  def self.report_without_duplication_sources(report, combined_input)
    report_duplication_discovery_failure(report, combined_input)
  end

  # :reek:BooleanParameter
  def self.report_duplication_read_failure(report, combined_input)
    report.errors = report.errors + [SourceFailure.new(report.paths.last, "ERROR: Cannot read source file", :source)]
    report_duplication_discovery_failure(report, combined_input)
  end

  def self.combine_duplication_sources(paths)
    source = ""
    source_map = []
    paths.each { |path| source = append_duplication_source(source, source_map, path) }
    [source, source_map]
  end

  def self.append_duplication_source(source, source_map, path)
    content = File.binread(path)
    source_map << [path, source.count("\n") + 1]
    source + content + (content.end_with?("\n") ? "" : "\n")
  end

  # :reek:BooleanParameter
  def self.analyze_structural_duplication(report, combined_analysis = false)
    run_native_duplication(report)
    result = report.result
    return report_duplication_analysis_failure(report, combined_analysis) if result + 1 <= 0
    print_duplication_report(report, result, combined_analysis)
  end

  def self.run_native_duplication(report)
    source = report.source
    report.result = NativePrism.fleek_structural_duplication(source, source.bytesize, report.mass_threshold)
    mark_partial_duplication_report(report)
  end

  def self.mark_partial_duplication_report(report)
    return unless NativePrism.fleek_structural_duplication_partial == 1
    report.partial = true
    report.partial_paths = report.paths
    report.source_scope = "partial"
  end

  # :reek:BooleanParameter
  def self.report_duplication_analysis_failure(report, combined_analysis)
    print_duplication_header(report, combined_analysis)
    report_invalid_duplication_sources(report, combined_analysis)
  end

  # :reek:BooleanParameter
  def self.report_invalid_duplication_sources(report, combined_error = false)
    return report_unsupported_duplication_sources(report, combined_error) if report.result == NativePrism::DUPLICATION_UNSUPPORTED_SOURCE
    return report_single_duplication_parse_failure(report, combined_error) if report.paths.length == 1
    warn "ERROR: Combined source set could not be parsed; no duplication results were analyzed."
    report_duplication_failure_summary(report, combined_error)
  end

  # :reek:BooleanParameter
  def self.report_single_duplication_parse_failure(report, combined_parse = false)
    report_parse_failure(report.paths[0], report.source, report.result)
    report_duplication_failure_summary(report, combined_parse)
  end

  # :reek:BooleanParameter
  def self.report_duplication_discovery_failure(report, combined_discovery = false)
    warn "ERROR: .flayignore excluded every selected source; no duplication analysis ran." if report.errors.empty?
    print_duplication_header(report, combined_discovery)
    report_duplication_error_summary(report, combined_discovery)
  end

  def self.report_duplication_input_failure(message)
    warn "ERROR: #{message}"
    warn "Use --mass MASS; check-specific options use long names."
    1
  end

  # :reek:BooleanParameter
  def self.report_unsupported_duplication_sources(report, combined_syntax = false)
    warn "ERROR: unsupported Flay candidate syntax; selected sources must use exactly two top-level parameterless methods, bounded methods in simple classes or one-level namespaces, direct methods in one simple module or a sole nested-module chain up to eleven modules, one direct class under a sole nested-module chain up to ten modules, nested class chains through six classes with existing bounded direct-sibling and wrapper forms, or direct classes with supported methods under a relative qualified module path with two to fourteen constant components; scopes allow at most 32 direct body entries and 24 supported candidates total; methods accept up to 8 required or literal-default optional positional parameters, bounded if/else/unless branches, boolean OR expressions, return statements with supported values, and local-variable assignments (no rest, keyword, or block parameters), using supported call, literal, local-variable-read, and keyword-hash AST forms; unsupported or partial subtree matches are incomplete."
    report_duplication_errors(report.errors)
    report_duplication_failure_summary(report, combined_syntax)
  end

  def self.report_duplication_errors(errors)
    errors.each { |error| report_input_error(error) }
  end

  # :reek:BooleanParameter
  # :reek:ControlParameter
  # :reek:RepeatedConditional
  # :reek:DuplicateMethodCall
  def self.report_duplication_error_summary(report, combined_coverage = false)
    errors = report.errors
    excluded = report.excluded_paths
    report_duplication_errors(errors)
    coverage = Coverage.new(errors.length + excluded.length, 0, errors.length, excluded.length, "incomplete")
    report_duplication_coverage(coverage, combined_coverage)
  end

  # :reek:BooleanParameter
  # :reek:ControlParameter
  # :reek:RepeatedConditional
  # :reek:TooManyStatements
  def self.report_duplication_failure_summary(report, combined_coverage = false)
    failed_count = report.paths.length + report.errors.length
    excluded_count = report.excluded_paths.length
    selected_count = failed_count + excluded_count
    coverage = Coverage.new(selected_count, 0, failed_count, excluded_count, "incomplete")
    report_duplication_coverage(coverage, combined_coverage)
  end

  # :reek:BooleanParameter
  # :reek:ControlParameter
  def self.report_duplication_coverage(coverage, combined_coverage)
    return report_combined_duplication_coverage(coverage) if combined_coverage
    report_input_summary(coverage.selected, coverage.analyzed, coverage.failed, coverage.excluded, coverage.state)
    1
  end

  def self.report_combined_duplication_coverage(coverage)
    report_section_coverage("Duplication", coverage)
    1
  end

  # :reek:BooleanParameter
  # :reek:ControlParameter
  # :reek:RepeatedConditional
  def self.print_duplication_header(report, duplication_header_mode = false)
    print_duplication_metadata(report.mass_threshold) unless duplication_header_mode
    puts "Sources:"
    print_duplication_source_rows(report)
    puts "Duplication:"
  end

  def self.print_duplication_source_rows(report)
    report.paths.each { |path| print_duplication_source(path, report.source_scope) }
    print_duplication_failed_sources(report.errors)
    print_duplication_excluded_sources(report.excluded_paths)
  end

  def self.print_duplication_included_sources(paths)
    paths.each { |path| print_duplication_source(path, "included") }
  end

  def self.print_duplication_failed_sources(errors)
    errors.each { |error| print_duplication_source(error.path, "failed") }
  end

  def self.print_duplication_excluded_sources(paths)
    paths.each { |path| print_duplication_source(path, "excluded") }
  end

  def self.print_duplication_source(path, scope)
    puts "  Source: #{quote_text(path)} scope=#{scope}"
  end

  def self.print_duplication_metadata(mass_threshold)
    puts "Fleek report v1"
    puts "References: Flay #{FLAY_REFERENCE}; Reek #{REEK_REFERENCE}; Spinel #{SPINEL_RELEASE}"
    puts "Checks selected: flay:StructuralDuplication"
    puts "Checks run: flay:StructuralDuplication"
    puts "Scope limits: parameterless top-level methods, class methods in simple classes and one-level namespaces, direct methods in one simple module or a sole nested-module chain up to eleven modules, one direct class under a sole nested-module chain up to ten modules, nested class chains through six classes with existing bounded direct-sibling and wrapper forms, or direct classes with supported methods under a relative qualified module path with two to fourteen constant components; methods accept up to 8 required or literal-default optional positional parameters, bounded if/else/unless branches, boolean OR expressions, return statements with supported values, and local-variable assignments; partial results are marked incomplete; partial subtree groups fail; Flay mass #{mass_threshold}."
  end

  # :reek:BooleanParameter
  def self.print_duplication_report(report, score, combined_report = false)
    print_duplication_header(report, combined_report)
    warn_partial_duplication_results(report)
    print_duplication_results(report.paths, score, report.source_map)
    print_duplication_status(report, score, combined_report)
  end

  def self.warn_partial_duplication_results(report)
    warn "WARNING: Partial results may omit Flay candidates; unsupported class or method forms were not analyzed." unless report.partial_paths.empty?
  end

  # :reek:ControlParameter
  # :reek:BooleanParameter
  # :reek:RepeatedConditional
  def self.print_duplication_status(report, score, combined_status = false)
    status = duplication_exit_status(report.errors.length + report.partial_paths.length, score)
    coverage = duplication_coverage(report, status)
    print_duplication_coverage(coverage, combined_status)
    status
  end

  # :reek:ControlParameter
  def self.duplication_exit_status(failed_count, score)
    return 1 if failed_count > 0
    score == 0 ? 0 : 2
  end

  def self.duplication_coverage(report, status)
    excluded = report.excluded_paths.length
    selected = report.paths.length + report.errors.length + excluded
    Coverage.new(selected, duplication_analyzed_count(report), duplication_failed_count(report), excluded, report_state(status))
  end

  def self.duplication_analyzed_count(report)
    report.paths.length - report.partial_paths.length
  end

  def self.duplication_failed_count(report)
    report.errors.length + report.partial_paths.length
  end

  # :reek:BooleanParameter
  # :reek:ControlParameter
  def self.print_duplication_coverage(coverage, combined_status)
    return report_section_coverage("Duplication", coverage) if combined_status
    report_input_summary(coverage.selected, coverage.analyzed, coverage.failed, coverage.excluded, coverage.state)
  end

  def self.print_duplication_results(paths, score, source_map)
    groups = score > 0 ? print_duplication_groups(source_map) : []
    puts "Total duplication score: #{score}"
    paths.each { |path| puts "File duplication score: #{quote_text(path)} score=#{duplication_file_score(path, groups)}" }
  end

  def self.duplication_file_score(path, groups)
    score = 0
    groups.each { |group| score += duplication_group_file_score(path, group) }
    score
  end

  def self.duplication_group_file_score(path, group)
    locations = group.locations
    count = 0
    locations.each { |location| count += 1 if location.start_with?("#{path}:") }
    count * group.score / locations.length
  end

  def self.print_duplication_groups(source_map)
    groups = duplication_groups(source_map)
    groups.each { |group| print_duplication_group(group) }
    groups
  end

  def self.duplication_groups(source_map)
    records = NativePrism.fleek_structural_duplication_finding.split("\n")
    records.map { |record| duplication_group(record, source_map) }.sort_by { |group| duplication_group_sort_key(group) }
  end

  def self.duplication_group(record, source_map)
    node, kind, mass, score, lines = record.split("\t")
    DuplicationGroup.new(node, kind, mass.to_i, score.to_i, duplication_group_locations(lines, source_map))
  end

  def self.duplication_group_locations(lines, source_map)
    locations = lines.split(",").map { |line| duplication_source_location(line.to_i, source_map) }
    locations.sort_by { |location| duplication_location_sort_key(location) }
  end

  def self.duplication_group_sort_key(group)
    [-group.score, duplication_location_sort_key(group.locations[0]), group.node]
  end

  def self.print_duplication_group(group)
    puts duplication_group_report_line(group)
  end

  def self.duplication_group_report_line(group)
    "  Group: check=\"flay:StructuralDuplication\" node=#{quote_text(group.node)} kind=#{quote_text(group.kind)} locations=#{quote_text(group.locations.join(","))} mass=#{group.mass} score=#{group.score}"
  end

  def self.duplication_location_sort_key(location)
    path, line = location.split(":")
    [path, line.to_i]
  end

  def self.duplication_source_location(line, source_map)
    source = source_map.reverse.find { |_path, start_line| line >= start_line }
    "#{source[0]}:#{line - source[1] + 1}"
  end

  # :reek:TooManyStatements
  # :reek:BooleanParameter
  def self.run_class_variable(inputs, combined_run = false)
    config_path, source_inputs, option_error = extract_reek_configuration(inputs)
    return report_configuration_error(option_error) unless option_error.empty?
    configuration = ReekConfiguration.load(config_path)
    configuration_error = configuration.error
    return report_configuration_error(configuration_error) unless configuration_error.empty?
    return run_class_variable_with_stdin(source_inputs, configuration) if source_inputs[0] == "--stdin"

    raw_files = raw_class_variable_files(source_inputs, combined_run)
    excluded_paths = raw_files.select { |path| configuration.excluded_path?(path) }
    files, errors = discover_sources(source_inputs, configuration)
    return report_disabled_check(files + errors, configuration) if disabled_input?(files, configuration)

    print_text_report_header(files, configuration, "", errors, combined_run, excluded_paths)
    report_input_errors(errors)
    summary = ClassVariableSummary.new(files, errors, configuration, combined_run, excluded_paths)
    summarize_class_variable_inputs(summary)
  end

  # :reek:ControlParameter
  def self.raw_class_variable_files(source_inputs, combined_run)
    files, = combined_run ? discover_sources(source_inputs, ReekConfiguration.new) : [[], []]
    files
  end

  REEK_DETECTORS = {
    "Attribute" => ["public literal attr_accessor and attr_writer declarations in one simple class or module", "%s is a writable attribute"],
    "InstanceVariableAssumption" => ["direct instance methods in one simple class", "%s assumes too much for instance variable '%s'"],
    "SubclassedFromCoreClass" => ["one simple class inheriting directly from Array, Hash, or String", "%s inherits from core class '%s'"],
    "ModuleInitialize" => ["one simple module with direct instance methods", "%s has initialize method"],
    "IrresponsibleModule" => ["one simple class or module", "%s has no descriptive comment"],
    "LongParameterList" => ["one simple class or module with direct instance methods and supported parameter lists", "%s has %s parameters"],
    "BooleanParameter" => ["one simple class or module with direct instance methods and supported parameter lists", "%s has boolean parameter '%s'"],
    "LongYieldList" => ["one simple class or module with direct instance methods", "%s yields %s parameters"],
    "ControlParameter" => ["simple methods with direct conditionals", "%s is controlled by argument '%s'"],
    "UnusedParameters" => ["simple method parameter lists and supported method bodies", "%s has unused parameter '%s'"],
    "UtilityFunction" => ["direct instance methods without inherited overrides", "%s doesn't depend on instance state (maybe move it to another class?)"],
    "DuplicateMethodCall" => ["direct method calls with identical source form", "%s calls '%s' %s times"],
    "ManualDispatch" => ["simple method bodies containing respond_to?", "%s manually dispatches method call"],
    "NilCheck" => ["simple method bodies with nil? or nil comparisons", "%s performs a nil-check"],
    "MissingSafeMethod" => ["direct bang methods without matching non-bang methods", "%s has missing safe method '%s'"],
    "RepeatedConditional" => ["simple method conditions compared across one class", "%s tests '%s' at least %s times"],
    "NestedIterators" => ["simple method bodies with block iterators", "%s contains iterators nested %s deep"],
    "FeatureEnvy" => ["simple methods with local-variable receiver calls and self references", "%s refers to '%s' more than self (maybe move it to another class?)"],
    "DataClump" => ["direct instance methods with matching parameter names", "%s takes parameters %s to %s methods"],
    "TooManyConstants" => ["one simple class or module's direct constant assignments", "%s has %s constants"],
    "TooManyInstanceVariables" => ["one simple class's instance variables", "%s has at least %s instance variables"],
    "TooManyMethods" => ["one simple class's direct instance methods", "%s has at least %s methods"],
    "TooManyStatements" => ["simple method bodies with statement counting", "%s has approx %s statements"],
    "UncommunicativeMethodName" => ["direct methods in one simple class or module", "%s has the name '%s'"],
    "UncommunicativeModuleName" => ["simple class and module constant names", "%s has the name '%s'"],
    "UncommunicativeParameterName" => ["simple method parameters", "%s has the parameter name '%s'"],
    "UncommunicativeVariableName" => ["simple local assignments in direct methods", "%s has the variable name '%s'"]
  }.freeze
  UNCOMMUNICATIVE_NAME_DEFAULTS = {
    "UncommunicativeMethodName" => ["^[a-z]$\n[0-9]$\n[A-Z]", ""],
    "UncommunicativeModuleName" => ["^.$\n[0-9]$", ""],
    "UncommunicativeParameterName" => ["^.$\n[0-9]$\n[A-Z]\n^_", ""],
    "UncommunicativeVariableName" => ["^.$\n[0-9]$\n[A-Z]", "^_$"]
  }.freeze

  def self.run_attribute(inputs)
    run_reek_detector(inputs, "Attribute", :single)
  end

  def self.run_instance_variable_assumption(inputs)
    run_reek_detector(inputs, "InstanceVariableAssumption", :single)
  end

  def self.run_subclassed_from_core_class(inputs)
    run_reek_detector(inputs, "SubclassedFromCoreClass", :single)
  end

  def self.run_module_initialize(inputs)
    run_reek_detector(inputs, "ModuleInitialize", :single)
  end

  def self.run_irresponsible_module(inputs)
    run_reek_detector(inputs, "IrresponsibleModule", :single)
  end

  def self.run_long_parameter_list(inputs)
    run_reek_detector(inputs, "LongParameterList", :single)
  end

  def self.run_boolean_parameter(inputs)
    run_reek_detector(inputs, "BooleanParameter", :single)
  end

  def self.run_long_yield_list(inputs)
    run_reek_detector(inputs, "LongYieldList", :single)
  end

  def self.run_control_parameter(inputs)
    run_reek_detector(inputs, "ControlParameter", :single)
  end

  def self.run_unused_parameters(inputs)
    run_reek_detector(inputs, "UnusedParameters", :single)
  end

  def self.run_utility_function(inputs)
    run_reek_detector(inputs, "UtilityFunction", :single)
  end

  # :reek:TooManyStatements
  def self.run_reek_detector(inputs, detector, report_mode)
    configuration, source_inputs, error = reek_detector_configuration(inputs)
    return report_configuration_error(error) if error.length.positive?
    files, errors = discover_sources(source_inputs, ReekConfiguration.new)
    selected, excluded, disabled = detector_source_sets(files, configuration, detector)
    return report_detector_disabled(detector, disabled.first) if detector_fully_disabled?(files, errors, selected, excluded)
    run_reek_detector_files(detector, report_mode, configuration, files, errors, selected, excluded, disabled)
  end

  def self.reek_detector_configuration(inputs)
    parse_reek_configuration(inputs)
  end

  # :reek:LongParameterList
  # :reek:TooManyStatements
  # :reek:DuplicateMethodCall
  def self.run_reek_detector_files(detector, report_mode, configuration, files, errors, selected, excluded, disabled)
    print_reek_detector_header(detector, files, errors, excluded, disabled, report_mode)
    report_input_errors(errors)
    results = selected.map { |path| analyze_reek_detector(path, detector, configuration) } + Array.new(errors.length, 1)
    analyzed = results.count { |result| result == 0 || result == 2 || result == -5 }
    failed = results.count(1) + results.count(-5)
    status = failed > 0 ? 1 : results.max || (excluded.empty? ? 0 : 1)
    report_reek_detector_coverage(detector, selected.length + errors.length, analyzed, failed, excluded.length, report_mode, status)
    status
  end

  # :reek:LongParameterList
  def self.detector_fully_disabled?(files, errors, selected, excluded)
    !files.empty? && selected.empty? && excluded.empty? && errors.empty?
  end

  def self.report_detector_disabled(detector, path)
    warn "ERROR: Reek #{detector} is disabled by configuration for #{quote_text(path)}; no analysis ran."
    1
  end

  # :reek:ControlParameter
  # :reek:LongParameterList
  # :reek:TooManyStatements
  def self.print_reek_detector_header(detector, files, errors, excluded, disabled, report_mode)
    if report_mode == :single
      print_report_identity
      puts "Checks selected: reek:#{detector}"
      puts "Checks run: reek:#{detector}"
      puts "Scope limits: #{detector_scope_limit(detector)}; unsupported source is incomplete."
    end
    puts "#{detector} findings:"
    print_reek_detector_sources(files, errors, excluded, disabled)
    puts "Findings:"
  end

  def self.detector_scope_limit(detector)
    REEK_DETECTORS.fetch(detector)[0]
  end

  # :reek:TooManyStatements
  def self.analyze_reek_detector(path, detector, configuration)
    source = File.binread(path)
    settings = native_detector_settings(configuration, detector, path)
    visibility_setting = detector == "UtilityFunction" && configuration.detector_setting(detector, "public_methods_only", path) == "true"
    result = visibility_setting ? -4 : run_native_reek_detector(detector, source, settings)
    report_reek_detector_result(path, detector, result, configuration)
  rescue SystemCallError
    warn "ERROR: Cannot read source file: #{quote_text(path)}"
    1
  end

  # Completes detector reporting while retaining partial findings on bounded syntax.
  # :reek:TooManyStatements
  # :reek:LongParameterList
  def self.report_reek_detector_result(path, detector, result, configuration)
    unsupported = result == -4
    partial = result == -5
    return report_reek_detector_parse_failure(path, detector) if result < 0 && !unsupported && !partial
    findings = unsupported ? [] : print_reek_detector_findings(path, detector, native_reek_findings(detector), configuration)
    return report_reek_detector_unsupported(path, detector) if unsupported || partial
    findings.empty? ? 0 : 2
  end

  # :reek:ControlParameter
  # :reek:TooManyStatements
  def self.native_detector_settings(configuration, detector, path)
    if UNCOMMUNICATIVE_NAME_DEFAULTS.key?(detector)
      reject, accept = UNCOMMUNICATIVE_NAME_DEFAULTS.fetch(detector)
      return [0, configuration.detector_setting(detector, "reject", path) || reject, configuration.detector_setting(detector, "accept", path) || accept]
    end
    limits = { "DuplicateMethodCall" => ["max_calls", "1"], "NestedIterators" => ["max_allowed_nesting", "1"], "RepeatedConditional" => ["max_ifs", "2"], "DataClump" => ["max_copies", "2"], "TooManyConstants" => ["max_constants", "5"], "TooManyInstanceVariables" => ["max_instance_variables", "4"], "TooManyMethods" => ["max_methods", "15"], "TooManyStatements" => ["max_statements", "5"] }
    key, fallback = limits.fetch(detector, ["max_params", "3"])
    maximum = Integer(configuration.detector_setting(detector, key, path) || fallback, 10)
    allow_calls = detector == "DataClump" ? configuration.detector_setting(detector, "min_clump_size", path) || "2" : configuration.detector_setting("DuplicateMethodCall", "allow_calls", path) || ""
    ignored = configuration.detector_setting("NestedIterators", "ignore_iterators", path) || "Tempfile.create\ntap"
    [maximum, allow_calls, ignored]
  end

  # :reek:ControlParameter
  # :reek:LongParameterList
  # :reek:TooManyStatements
  def self.run_native_reek_detector(detector, source, settings)
    length = source.bytesize
    maximum = settings[0]
    option = settings[1]
    accepted_names = settings[2]
    minimum = Integer(option, 10) if detector == "DataClump"
    case detector
    when "Attribute" then NativePrism.fleek_attribute(source, length)
    when "InstanceVariableAssumption" then NativePrism.fleek_instance_variable_assumption(source, length)
    when "SubclassedFromCoreClass" then NativePrism.fleek_subclassed_from_core_class(source, length)
    when "ModuleInitialize" then NativePrism.fleek_module_initialize(source, length)
    when "IrresponsibleModule" then NativePrism.fleek_irresponsible_module(source, length)
    when "LongParameterList" then NativePrism.fleek_long_parameter_list(source, length, maximum)
    when "BooleanParameter" then NativePrism.fleek_boolean_parameter(source, length)
    when "LongYieldList" then NativePrism.fleek_long_yield_list(source, length, maximum)
    when "ControlParameter" then NativePrism.fleek_control_parameter(source, length)
    when "UnusedParameters" then NativePrism.fleek_unused_parameters(source, length)
    when "UtilityFunction" then NativePrism.fleek_utility_function(source, length)
    when "DuplicateMethodCall"
      NativePrism.fleek_duplicate_method_call(source, length, maximum, option)
    when "ManualDispatch" then NativePrism.fleek_manual_dispatch(source, length)
    when "NilCheck" then NativePrism.fleek_nil_check(source, length)
    when "MissingSafeMethod" then NativePrism.fleek_missing_safe_method(source, length)
    when "RepeatedConditional" then NativePrism.fleek_repeated_conditional(source, length, maximum)
    when "NestedIterators"
      NativePrism.fleek_nested_iterators(source, length, maximum, accepted_names)
    when "FeatureEnvy" then NativePrism.fleek_feature_envy(source, length)
    when "DataClump" then NativePrism.fleek_data_clump(source, length, maximum, minimum)
    when "TooManyConstants" then NativePrism.fleek_too_many_constants(source, length, maximum)
    when "TooManyInstanceVariables" then NativePrism.fleek_too_many_instance_variables(source, length, maximum)
    when "TooManyMethods" then NativePrism.fleek_too_many_methods(source, length, maximum)
    when "TooManyStatements" then NativePrism.fleek_too_many_statements(source, length, maximum)
    when "UncommunicativeMethodName" then NativePrism.fleek_uncommunicative_method_name(source, length, option, accepted_names)
    when "UncommunicativeModuleName" then NativePrism.fleek_uncommunicative_module_name(source, length, option, accepted_names)
    when "UncommunicativeParameterName" then NativePrism.fleek_uncommunicative_parameter_name(source, length, option, accepted_names)
    when "UncommunicativeVariableName" then NativePrism.fleek_uncommunicative_variable_name(source, length, option, accepted_names)
    end
  end

  # :reek:ControlParameter
  # :reek:TooManyStatements
  def self.native_reek_findings(detector)
    case detector
    when "Attribute" then NativePrism.fleek_attribute_finding
    when "InstanceVariableAssumption" then NativePrism.fleek_instance_variable_assumption_finding
    when "SubclassedFromCoreClass" then NativePrism.fleek_subclassed_from_core_class_finding
    when "ModuleInitialize" then NativePrism.fleek_module_initialize_finding
    when "IrresponsibleModule" then NativePrism.fleek_irresponsible_module_finding
    when "LongParameterList" then NativePrism.fleek_long_parameter_list_finding
    when "BooleanParameter" then NativePrism.fleek_boolean_parameter_finding
    when "LongYieldList" then NativePrism.fleek_long_yield_list_finding
    when "ControlParameter" then NativePrism.fleek_control_parameter_finding
    when "UnusedParameters" then NativePrism.fleek_unused_parameters_finding
    when "UtilityFunction" then NativePrism.fleek_utility_function_finding
    when "DuplicateMethodCall" then NativePrism.fleek_duplicate_method_call_finding
    when "ManualDispatch" then NativePrism.fleek_manual_dispatch_finding
    when "NilCheck" then NativePrism.fleek_nil_check_finding
    when "MissingSafeMethod" then NativePrism.fleek_missing_safe_method_finding
    when "RepeatedConditional" then NativePrism.fleek_repeated_conditional_finding
    when "NestedIterators" then NativePrism.fleek_nested_iterators_finding
    when "FeatureEnvy" then NativePrism.fleek_feature_envy_finding
    when "DataClump" then NativePrism.fleek_data_clump_finding
    when "TooManyConstants" then NativePrism.fleek_too_many_constants_finding
    when "TooManyInstanceVariables" then NativePrism.fleek_too_many_instance_variables_finding
    when "TooManyMethods" then NativePrism.fleek_too_many_methods_finding
    when "TooManyStatements" then NativePrism.fleek_too_many_statements_finding
    when "UncommunicativeMethodName" then NativePrism.fleek_uncommunicative_method_name_finding
    when "UncommunicativeModuleName" then NativePrism.fleek_uncommunicative_module_name_finding
    when "UncommunicativeParameterName" then NativePrism.fleek_uncommunicative_parameter_name_finding
    when "UncommunicativeVariableName" then NativePrism.fleek_uncommunicative_variable_name_finding
    end
  end

  def self.report_reek_detector_unsupported(path, detector)
    warn "ERROR: #{quote_text(path)}: #{detector} supports #{detector_scope_limit(detector)}; other shapes are unsupported."
    1
  end

  def self.report_reek_detector_parse_failure(path, detector)
    warn "ERROR: #{quote_text(path)}: #{detector} source could not be parsed by the pinned Ruby 4.0 grammar."
    1
  end

  # :reek:LongParameterList
  # :reek:TooManyStatements
  def self.print_reek_detector_findings(path, detector, findings, configuration)
    rows = findings.split("\n")
    rows.reject! do |finding|
      line, context, name = finding.split("\t")
      detector == "MissingSafeMethod" ? configuration.excluded_method_name?(path, name) : configuration.excluded_context?(path, context, detector)
    end
    rows.sort_by! { |finding| reek_finding_sort_key(finding) }
    rows.each { |finding| print_reek_detector_finding(path, detector, finding) }
    rows
  end

  def self.reek_finding_sort_key(finding)
    fields = finding.split("\t")
    [fields[1], fields[0].to_i]
  end

  def self.print_reek_detector_finding(path, detector, finding)
    line, context, name, count = finding.split("\t")
    puts "  Finding: check=\"reek:#{detector}\" source=#{quote_text(path)} lines=#{quote_text(line)} context=#{quote_text(context)} name=#{quote_text(name || context)} message=#{quote_text(reek_detector_message(detector, line, context, name, count))}"
  end

  # :reek:LongParameterList
  # :reek:DuplicateMethodCall
  # :reek:RepeatedConditional
  # :reek:TooManyStatements
  def self.reek_detector_message(detector, line, context, name, count = "")
    template = REEK_DETECTORS.fetch(detector)[1]
    arguments = if ["DuplicateMethodCall", "RepeatedConditional", "DataClump"].include?(detector)
                  [context, name, count]
                elsif ["ManualDispatch", "NilCheck"].include?(detector)
                  [context]
                elsif detector == "NestedIterators"
                  [context, count]
                else
                  [context, name]
                end
    description = template % arguments
    "[#{line}]:#{detector}: #{description} [https://github.com/troessner/reek/blob/v6.6.0/docs/#{detector.gsub(/([a-z])([A-Z])/, '\\1-\\2')}.md]"
  end

  # :reek:ControlParameter
  # :reek:LongParameterList
  def self.report_reek_detector_coverage(detector, selected, analyzed, failed, excluded, report_mode, status)
    coverage = Coverage.new(selected, analyzed, failed, excluded, report_state(status))
    return report_section_coverage(detector, coverage) if report_mode == :combined
    report_input_summary(selected, analyzed, failed, excluded, coverage.state)
  end

  # :reek:DuplicateMethodCall
  # :reek:TooManyStatements
  def self.detector_source_sets(files, configuration, detector)
    excluded = files.select { |path| configuration.excluded_path?(path) }
    disabled = files.reject { |path| excluded.include?(path) || configuration.detector_enabled_for?(detector, path) }
    selected = files.reject { |path| excluded.include?(path) || disabled.include?(path) }
    [selected, excluded, disabled]
  end

  # :reek:LongParameterList
  def self.print_reek_detector_sources(files, errors, excluded, disabled)
    files.each { |path| print_duplication_source(path, reek_source_scope(path, excluded, disabled)) }
    errors.each { |error| print_duplication_source(error.path, "failed") }
  end

  def self.reek_source_scope(path, excluded, disabled)
    return "excluded" if excluded.include?(path)
    return "disabled" if disabled.include?(path)
    "included"
  end

  # :reek:TooManyStatements
  def self.extract_reek_configuration(inputs)
    remaining = inputs.dup
    option_index = remaining.index("--reek-config")
    return ["", remaining, ""] unless option_index
    option = remaining.slice!(option_index, 2)
    return ["", [], "--reek-config requires a file."] unless option.length == 2
    config_path = option[1]
    return ["", [], "--reek-config requires a non-empty file path."] if config_path.empty?
    return ["", [], "--reek-config may appear only once."] if remaining.include?("--reek-config")
    [config_path, remaining, ""]
  end

  def self.report_configuration_error(message)
    warn "ERROR: Reek configuration #{message}"
    1
  end

  # :reek:TooManyStatements
  def self.run_combined_checks(inputs, profile = CheckProfiles::EXPLICIT)
    analysis = prepare_combined_analysis(inputs)
    error = analysis.error
    return report_combined_input_error(error) if error != ""
    disabled_paths = analysis.disabled_paths
    return report_disabled_check(disabled_paths, analysis.configuration) unless disabled_paths.empty? || !profile.run.include?("reek:ClassVariable")
    print_combined_header(profile)
    run_combined_sections(analysis, profile)
  end

  def self.print_combined_header(profile = CheckProfiles::EXPLICIT)
    print_report_identity
    profile.report_lines.each { |line| puts line }
    puts "Scope limits: supported Flay and Reek syntax subsets; analyzer-specific exclusions; separate scores."
  end

  # :reek:TooManyStatements
  def self.prepare_combined_analysis(inputs)
    flay_inputs = without_option_pair(inputs, "--reek-config")
    reek_inputs = without_option_pair(inputs, "--mass")
    flay_error = structural_duplication_input_error(flay_inputs)
    configuration, reek_sources, config_error = combined_reek_configuration(reek_inputs)
    return CombinedAnalysis.new(flay_inputs, reek_inputs, nil, config_error, []) unless config_error.empty?
    ignore_error = load_flay_ignore_patterns[1]
    return CombinedAnalysis.new(flay_inputs, reek_inputs, nil, ignore_error, []) unless ignore_error.empty?
    input_error = combined_source_error(flay_error, reek_sources)
    return CombinedAnalysis.new(flay_inputs, reek_inputs, nil, input_error, []) unless input_error == ""
    disabled_paths = disabled_combined_sources(reek_sources, configuration)
    CombinedAnalysis.new(flay_inputs, reek_inputs, configuration, "", disabled_paths)
  end

  def self.combined_reek_configuration(inputs)
    parse_reek_configuration(inputs)
  end

  def self.parse_reek_configuration(inputs)
    config_path, sources, error = extract_reek_configuration(inputs)
    return [nil, [], error] if error.length.positive?
    configuration = ReekConfiguration.load(config_path)
    [configuration, sources, configuration.error]
  end

  def self.combined_source_error(flay_error, reek_sources)
    return "--stdin cannot be combined with flay:StructuralDuplication; provide Ruby source paths." if reek_sources[0] == "--stdin"
    return flay_error unless flay_error.empty?
    return "reek:ClassVariable requires at least one Ruby source path." if reek_sources.empty?
    ""
  end

  def self.disabled_combined_sources(sources, configuration)
    files, = discover_sources(sources, configuration)
    disabled_input?(files, configuration) ? files : []
  end

  # :reek:TooManyStatements
  def self.run_combined_sections(analysis, profile = CheckProfiles::EXPLICIT)
    puts "Duplication section:"
    duplication_status = run_profile_check(profile, "flay:StructuralDuplication", analysis.flay_inputs)
    puts "Smell section:"
    smell_statuses = run_profile_smells(profile, analysis)
    smell_status = class_variable_input_status(smell_statuses)
    finish_combined_analysis(duplication_status, smell_status, profile)
  end

  def self.run_profile_smells(profile, analysis)
    profile.run.select { |check| check.start_with?("reek:") }.map do |check|
      run_profile_check(profile, check, analysis.reek_inputs)
    end
  end

  def self.run_profile_check(profile, check, inputs)
    return 0 unless profile.run.include?(check)
    return run_structural_duplication(inputs, true) if check == "flay:StructuralDuplication"
    return run_class_variable(inputs, true) if check == "reek:ClassVariable"
    detector = check.delete_prefix("reek:")
    return run_reek_detector(inputs, detector, :combined) if REEK_DETECTORS.key?(detector)
  end

  def self.finish_combined_analysis(duplication_status, smell_status, profile = CheckProfiles::EXPLICIT)
    combined_status = combined_analysis_status(CheckResults.new(duplication_status, smell_status))
    combined_status = profile.final_status(combined_status)
    puts "Overall status: #{report_state(combined_status)}"
    combined_status
  end

  def self.without_option_pair(inputs, option)
    index = inputs.index(option)
    index ? inputs.take(index) + inputs.drop(index + 2) : inputs
  end

  def self.report_combined_input_error(message)
    warn "ERROR: #{message}"
    warn "Use long options: --checks, --mass, and --reek-config."
    1
  end

  def self.combined_analysis_status(results)
    duplication_status = results.duplication
    smell_status = results.smell
    return 1 if duplication_status == 1 || smell_status == 1
    return 2 if duplication_status == 2 || smell_status == 2
    0
  end

  def self.run_class_variable_with_stdin(inputs, configuration)
    input_count = inputs.length
    origin = inputs[1]
    return report_missing_stdin_origin if input_count < 2 || origin.empty?

    run_named_stdin(origin, inputs[2, input_count - 2], configuration)
  end

  def self.run_named_stdin(origin, paths, configuration)
    files, errors = discover_additional_sources(paths, configuration)
    return report_disabled_check(files + [origin] + errors, configuration) if configuration.disabled_for?(origin) || disabled_input?(files, configuration)

    print_text_report_header(files, configuration, origin, errors)
    report_input_errors(errors)
    summarize_class_variable_inputs_with_stdin(files, errors, origin, configuration)
  end

  # :reek:LongParameterList
  # :reek:BooleanParameter
  # :reek:ControlParameter
  # :reek:RepeatedConditional
  # :reek:TooManyStatements
  def self.print_text_report_header(files, configuration, origin = "", errors = [], smell_header_mode = false, excluded_paths = [])
    unless smell_header_mode
      print_report_identity
      print_selected_check(files, configuration, origin)
      print_report_scope
    end
    listing = SourceListing.new(report_sources(files, origin), configuration, errors, excluded_paths)
    print_report_sources(listing)
    puts smell_header_mode ? "Smells:" : "Findings:"
  end

  def self.print_selected_check(files, configuration, origin)
    puts "Checks selected: reek:ClassVariable"
    check_runs = report_sources(files, origin).any? { |path| !configuration.excluded_path?(path) }
    puts "Checks run: #{check_runs ? 'reek:ClassVariable' : 'none'}"
  end

  def self.report_sources(files, origin)
    origin.empty? ? files : [origin] + files
  end

  def self.print_report_identity
    puts "Fleek report v1"
    puts "References: Flay #{FLAY_REFERENCE}; Reek #{REEK_REFERENCE}; Spinel #{SPINEL_RELEASE}"
  end

  def self.print_report_scope
    puts "Scope limits: Ruby .rb inputs; only reek:ClassVariable is implemented."
  end

  def self.print_report_sources(listing)
    failed_sources = listing.failed_sources.select { |error| error.kind == :source }
    puts "Sources:"
    print_source_rows(SourceListing.new(listing.files, listing.configuration, failed_sources, listing.excluded_paths))
  end

  # :reek:TooManyStatements
  def self.print_source_rows(listing)
    files = listing.files
    failed_sources = listing.failed_sources
    excluded_paths = listing.excluded_paths
    if empty_source_listing?(files, failed_sources, excluded_paths)
      print_no_sources
      nil
    else
      print_included_source_rows(files, listing.configuration)
      print_failed_sources(failed_sources)
      print_excluded_source_rows(excluded_paths, files)
      nil
    end
  end

  def self.empty_source_listing?(files, failed_sources, excluded_paths)
    files.empty? && failed_sources.empty? && excluded_paths.empty?
  end

  def self.print_no_sources
    puts "  none"
  end

  def self.print_included_source_rows(files, configuration)
    files.each { |path| print_report_source(path, configuration) }
  end

  def self.print_excluded_source_rows(excluded_paths, files)
    excluded_paths.reject { |path| files.include?(path) }.each { |path| puts "  Source: #{quote_text(path)} scope=excluded" }
  end

  def self.print_failed_sources(errors)
    errors.each { |error| puts "  Source: #{quote_text(error.path)} scope=failed" }
  end

  def self.print_report_source(path, configuration)
    excluded = configuration.excluded_path?(path)
    puts "  Source: #{quote_text(path)} scope=#{excluded ? 'excluded' : 'included'}"
  end

  # :reek:TooManyStatements
  def self.quote_text(value)
    escaped = ""
    index = 0
    while index < value.length
      character = value[index]
      escaped += if character == "\\"
                   "\\\\"
                 elsif character == "\""
                   "\\\""
                 elsif character == "\t"
                   "\\t"
                 elsif character == "\n"
                   "\\n"
                 elsif character == "\r"
                   "\\r"
                 else
                   character
                 end
      index += 1
    end
    "\"#{escaped}\""
  end

  def self.analyze_stdin_source(origin, configuration)
    analyze_class_variable_source(origin, $stdin.read, configuration)
  rescue SystemCallError
    warn "ERROR: Cannot read standard input: #{quote_text(origin)}"
    1
  end

  def self.report_missing_stdin_origin
    warn "ERROR: --stdin requires a source filename."
    1
  end

  def self.discover_sources(paths, configuration)
    files, errors = collect_sources(paths, configuration)
    add_empty_scan_error(files, errors)
    [files, errors]
  end

  def self.discover_additional_sources(paths, configuration)
    collect_sources(paths, configuration)
  end

  def self.collect_sources(paths, configuration)
    files = []
    errors = []
    collect_requested_sources(paths, files, errors, configuration)
    [files, errors]
  end

  # :reek:LongParameterList
  def self.collect_requested_sources(paths, files, errors, configuration)
    paths.each { |path| discover_requested_path(path, files, errors, configuration) }
  end

  def self.add_empty_scan_error(files, errors)
    errors << SourceFailure.new("", "ERROR: No Ruby source files discovered from the requested inputs.", :request) if files.empty? && errors.empty?
  end

  def self.report_input_errors(errors)
    errors.each { |error| report_input_error(error) }
  end

  def self.report_input_error(error)
    path = error.path
    message = error.message
    warn path.empty? ? message : "#{message}: #{quote_text(path)}"
  end

  # :reek:LongParameterList
  def self.discover_requested_path(path, files, errors, configuration)
    symlink = File.symlink?(path)
    directory = File.directory?(path)
    if symlink && directory
      errors << SourceFailure.new(path, "ERROR: Directory symlinks are not followed", :request)
    elsif directory
      discover_directory(path, files, errors, configuration)
    else
      add_explicit_source(path, files, errors)
    end
  end

  # :reek:LongParameterList
  def self.discover_directory(path, files, errors, configuration)
    directory_entries(path, errors).each { |entry| discover_directory_entry("#{path}/#{entry}", files, errors, configuration) }
  end

  def self.directory_entries(path, errors)
    Dir.children(path).sort
  rescue SystemCallError
    errors << SourceFailure.new(path, "ERROR: Cannot scan directory", :request)
    []
  end

  # :reek:LongParameterList
  def self.discover_directory_entry(path, files, errors, configuration)
    return if skipped_directory_entry?(path)
    if File.directory?(path)
      discover_directory(path, files, errors, configuration)
    elsif ruby_source_path?(path)
      add_discovered_source(path, files, errors, configuration)
    end
  end

  # :reek:LongParameterList
  def self.add_discovered_source(path, files, errors, configuration)
    return if configuration.excluded_path?(path)

    add_explicit_source(path, files, errors)
  end

  def self.skipped_directory_entry?(path)
    directory = File.directory?(path)
    return true if File.symlink?(path) && directory
    directory && File.basename(path).start_with?(".")
  end

  def self.add_explicit_source(path, files, errors)
    return add_source_error(path, errors, "Cannot read source file") unless readable_file?(path)
    return add_source_error(path, errors, "Expected Ruby source (.rb)") unless ruby_source_path?(path)

    files << path
  end

  def self.add_source_error(path, errors, message)
    errors << SourceFailure.new(path, "ERROR: #{message}", :source)
  end

  def self.readable_file?(path)
    File.file?(path) && File.readable?(path)
  end

  def self.ruby_source_path?(path)
    path.end_with?(".rb")
  end

  # :reek:RepeatedConditional
  # :reek:TooManyStatements
  def self.summarize_class_variable_inputs(summary)
    files = summary.files
    configuration = summary.configuration
    combined_report = summary.combined_report
    excluded_results = excluded_input_count(files, configuration)
    excluded = combined_report ? summary.excluded_paths.length : excluded_results
    results = class_variable_input_results(files, summary.errors, configuration)
    summarize_class_variable_results(ClassVariableResults.new(results, files.length - excluded_results, excluded, combined_report, excluded_results))
  end

  # :reek:LongParameterList
  def self.summarize_class_variable_inputs_with_stdin(files, errors, origin, configuration)
    results = class_variable_input_results(files, errors, configuration).unshift(stdin_input_result(origin, configuration))
    excluded = excluded_input_count(files, configuration) + (configuration.excluded_path?(origin) ? 1 : 0)
    summary = ClassVariableResults.new(results, files.length + 1 - excluded, excluded, false, excluded)
    summarize_class_variable_results(summary)
  end

  def self.stdin_input_result(origin, configuration)
    configuration.excluded_path?(origin) ? 0 : analyze_stdin_source(origin, configuration)
  end

  def self.disabled_input?(files, configuration)
    files.any? { |path| configuration.disabled_for?(path) }
  end

  def self.report_disabled_check(inputs, configuration)
    path = inputs.find { |input| configuration.disabled_for?(input) }
    warn "ERROR: Reek ClassVariable is disabled for #{quote_text(path)}; no analysis ran."
    1
  end

  def self.excluded_input_count(files, configuration)
    files.count { |path| configuration.excluded_path?(path) }
  end

  # :reek:TooManyStatements
  # :reek:ControlParameter
  # :reek:RepeatedConditional
  def self.summarize_class_variable_results(summary)
    results = summary.results
    excluded = summary.excluded
    status = class_variable_input_status(results)
    if status == 0 && summary.analyzed == 0 && excluded > 0
      warn "ERROR: Reek exclusions removed every selected source; no analysis ran."
      status = 1
    end
    failures = results.count(1)
    analyzed = results.count(0) + results.count(2) - summary.excluded_results
    selected = analyzed + failures + excluded
    state = report_state(status)
    if summary.combined_report
      report_section_coverage("Smell", Coverage.new(selected, analyzed, failures, excluded, state))
      return status
    end
    report_input_summary(selected, analyzed, failures, excluded, state)
    status
  end

  # :reek:ControlParameter
  def self.report_state(status)
    return "incomplete" if status == 1
    status == 2 ? "findings" : "complete"
  end

  def self.class_variable_input_results(files, errors, configuration)
    source_errors, scan_errors = errors.partition { |error| error.kind == :source }
    files.map do |path|
      configuration.excluded_path?(path) ? 0 : analyze_class_variable_file(path, configuration)
    end + Array.new(source_errors.length, 1) + Array.new(scan_errors.length, :scan_failure)
  end

  def self.class_variable_input_status(results)
    return 1 if results.include?(:scan_failure)

    combined = results.inject(0) { |current, result| current | result }
    combined == 3 ? 1 : combined
  end

  # :reek:LongParameterList
  def self.report_input_summary(selected, analyzed, failures, excluded, state)
    puts "Coverage: #{selected} selected; #{analyzed} analyzed; #{failures} failed; #{excluded} excluded"
    puts "Status: #{state}"
  end

  def self.report_section_coverage(section, coverage)
    puts "#{section} coverage: #{coverage.selected} selected; #{coverage.analyzed} analyzed; #{coverage.failed} failed; #{coverage.excluded} excluded"
  end

  def self.analyze_class_variable_file(path, configuration)
    source = File.binread(path)
    analyze_class_variable_source(path, source, configuration)
  rescue SystemCallError
      warn "ERROR: Cannot read source file: #{quote_text(path)}"
      1
  end

  def self.analyze_class_variable_source(path, source, configuration)
    result = NativePrism.fleek_class_variable(source, source.bytesize)
    return report_unsupported_class(path) if result == -4
    return report_unsupported_suppression(path) if result == -5
    return report_invalid_class_source(path, source) if result < 0
    print_class_variable_result_for_source(path, configuration)
  end

  def self.report_unsupported_class(path)
    warn "ERROR: #{quote_text(path)}: ClassVariable supports one simple class or module (optionally within one simple module namespace); other scope shapes are unsupported."
    1
  end

  def self.report_unsupported_suppression(path)
    warn "ERROR: #{quote_text(path)}: unsupported Reek ClassVariable suppression settings."
    1
  end

  def self.report_invalid_class_source(path, source)
    offset = NativePrism.fleek_parse_ruby4(source, source.bytesize)
    report_parse_failure(path, source, offset)
  end

  def self.print_class_variable_result_for_source(path, configuration)
    findings = NativePrism.fleek_class_variable_finding.split("\n")
    findings.reject! do |finding|
      _lines, context, _variable = finding.split("\t")
      configuration.excluded_context?(path, context)
    end
    print_class_variable_result(path, findings)
  end

  def self.print_class_variable_result(path, findings)
    return 0 if findings.empty?

    print_class_variable_findings(path, findings)
    2
  end

  def self.print_class_variable_findings(path, findings)
    findings.each { |finding| print_class_variable_finding_line(path, finding) }
  end

  def self.print_class_variable_finding_line(path, finding)
    lines, context, variable = finding.split("\t")
    message = "[#{lines}]:ClassVariable: #{context} declares the class variable '#{variable}' [https://github.com/troessner/reek/blob/v6.6.0/docs/Class-Variable.md]"
    puts "  Finding: check=\"reek:ClassVariable\" source=#{quote_text(path)} lines=#{quote_text(lines)} context=#{quote_text(context)} name=#{quote_text(variable)} message=#{quote_text(message)}"
  end

  def self.parse_ruby4_file(path)
    unless readable_file?(path)
      warn "ERROR: Cannot read source file: #{quote_text(path)}"
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
      warn "#{quote_text(path)}: embedded NUL byte is unsupported"
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
    warn "#{quote_text(path)}:#{line}:#{column}: #{diagnostic} (byte #{offset})"
  end

  def self.run(arguments)
    return report_unsupported_format if unsupported_format_requested?(arguments)
    run_without_unsupported_format(arguments)
  end

  # :reek:TooManyStatements
  def self.run_without_unsupported_format(arguments)
    first_argument = arguments[0]
    return parse_ruby4_file(arguments[1]) if parse_ruby4_requested?(arguments)
    return run_selected_checks(arguments) if selected_checks_requested?(arguments, first_argument)
    return 0 if print_help_if_requested(arguments)
    return 0 if print_version_if_requested(arguments)
    return run_default_checks(arguments) unless first_argument == "--checks"

    print_usage_error(input_error(arguments))
  end

  def self.selected_checks_requested?(arguments, first_argument)
    arguments.length >= 3 && first_argument == "--checks"
  end

  def self.run_default_checks(arguments)
    inputs = arguments.empty? ? [Dir.pwd] : arguments
    profile, error = default_analysis_profile(inputs)
    return report_configuration_error(error) if error != ""
    run_combined_checks(inputs, profile)
  end

  def self.default_analysis_profile(inputs)
    config_path, source_inputs, option_error = extract_reek_configuration(inputs)
    return [nil, option_error] if option_error.length.positive?
    configured_default_profile(config_path, source_inputs)
  end

  def self.configured_default_profile(config_path, source_inputs)
    configuration = ReekConfiguration.load(config_path)
    configuration_error = configuration.error
    return [nil, configuration_error] unless configuration_error.empty?
    source_paths, = discover_sources(source_inputs, ReekConfiguration.new)
    [CheckProfiles.default(configuration, source_paths), ""]
  end

  # :reek:TooManyStatements
  def self.run_selected_checks(arguments)
    inputs = arguments[2..]
    check = arguments[1]
    detector = check.delete_prefix("reek:")
    return run_unsupported_opt_in(inputs, "UnusedPrivateMethod") if check == "reek:UnusedPrivateMethod"
    return run_class_variable(inputs) if check == "reek:ClassVariable"
    return run_attribute(inputs) if check == "reek:Attribute"
    return run_instance_variable_assumption(inputs) if check == "reek:InstanceVariableAssumption"
    return run_irresponsible_module(inputs) if check == "reek:IrresponsibleModule"
    return run_long_parameter_list(inputs) if check == "reek:LongParameterList"
    return run_boolean_parameter(inputs) if check == "reek:BooleanParameter"
    return run_long_yield_list(inputs) if check == "reek:LongYieldList"
    return run_control_parameter(inputs) if check == "reek:ControlParameter"
    return run_unused_parameters(inputs) if check == "reek:UnusedParameters"
    return run_utility_function(inputs) if check == "reek:UtilityFunction"
    return run_reek_detector(inputs, detector, :single) if check.start_with?("reek:") && REEK_DETECTORS.key?(detector)
    return run_module_initialize(inputs) if check == "reek:ModuleInitialize"
    return run_subclassed_from_core_class(inputs) if check == "reek:SubclassedFromCoreClass"
    return run_structural_duplication(inputs) if check == "flay:StructuralDuplication"
    return run_combined_checks(inputs) if check == "flay:StructuralDuplication,reek:ClassVariable" || check == "reek:ClassVariable,flay:StructuralDuplication"
    print_usage_error(input_error(arguments))
  end

  def self.run_unsupported_opt_in(inputs, detector)
    profile, error = unsupported_opt_in_profile(inputs, detector)
    return report_configuration_error(error) unless error.empty?
    run_combined_checks(inputs, profile)
  end

  # :reek:TooManyStatements
  def self.unsupported_opt_in_profile(inputs, detector)
    configuration, sources, error = parse_reek_configuration(inputs)
    return [nil, error] unless error.empty?
    files, = discover_sources(sources, ReekConfiguration.new)
    enabled_by_config = configuration.detector_enabled_anywhere?(detector, files)
    check = "reek:#{detector}"
    configured = inputs.include?("--reek-config") || !ReekConfiguration.discovered_path.empty?
    disabled = configured && !enabled_by_config ? [check] : []
    unsupported = disabled.empty? ? [check] : []
    [AnalysisProfile.new([check], [], disabled, unsupported, true), ""]
  end
end

exit Fleek.run(ARGV)
