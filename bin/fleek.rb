require_relative "reek_engine"

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
  DuplicationReport = Struct.new(:paths, :errors, :source_map, :mass_threshold, :excluded_paths, :source, :result, :only_node, :liberal, :fuzzy, :legacy)
  # Carries one Flay group through stable report formatting.
  DuplicationGroup = Struct.new(:node, :kind, :mass, :score, :locations, :fuzzy_locations)
  # Carries validated analyzer inputs through combined execution.
  CombinedAnalysis = Struct.new(:flay_inputs, :reek_inputs, :configuration, :error, :disabled_paths)
  FLAY_CHECK = "flay:StructuralDuplication"
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
    RUNNABLE_OPT_IN_CHECKS = %w[reek:UnusedPrivateMethod].freeze
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
      run = (RUNNABLE_DEFAULT_CHECKS + RUNNABLE_OPT_IN_CHECKS) & selected
      AnalysisProfile.new(selected, run, disabled, selected - run, true)
    end
  end
  FLAY_REFERENCE = "2.14.4"
  REEK_REFERENCE = "6.6.0"
  SPINEL_RELEASE = "2026.09.12"

  # Provides the native Prism parser adapter.
  module NativePrism
    DUPLICATION_UNSUPPORTED_SOURCE = -4
    DUPLICATION_LEGACY_PARSE_ERROR = -5
    FLAY_DEFAULT_MASS = 16
    ffi_source <<~C
    #include "prism.h"
#include <stddef.h>
    #include <stdint.h>
    #include <stdio.h>
    #include <ctype.h>
    #include <limits.h>
    #include <stdlib.h>
    #include <regex.h>
    #include <string.h>

    static char fleek_parse_message_buffer[512];
    static char fleek_finding_buffer[4096];
    static char *fleek_duplication_buffer;
    static size_t fleek_duplication_buffer_capacity;
    static size_t fleek_duplication_buffer_used;
    static int fleek_duplication_total_score;
    static char fleek_attribute_buffer[4096];
    static size_t fleek_attribute_buffer_used;
    static int fleek_attribute_unsupported;
    static int fleek_attribute_public;
    static char fleek_instance_variable_assumption_buffer[4096];
    static char fleek_subclassed_from_core_class_buffer[1024];
    static char fleek_module_initialize_buffer[1024];
    static char fleek_long_parameter_list_buffer[8192];
    static size_t fleek_long_parameter_list_used;
    static char fleek_boolean_parameter_buffer[8192];
    static size_t fleek_boolean_parameter_used;
    static char fleek_long_yield_list_buffer[8192];
    static size_t fleek_long_yield_list_used;
    static char fleek_unused_parameters_buffer[8192];
    static size_t fleek_unused_parameters_used;
    static char fleek_unused_private_method_buffer[8192];
    static size_t fleek_unused_private_method_used;
    static char fleek_manual_dispatch_buffer[4096];
    static size_t fleek_manual_dispatch_used;
    static char fleek_missing_safe_method_buffer[4096];
    static size_t fleek_missing_safe_method_used;
    static char fleek_repeated_conditional_buffer[8192];
    static size_t fleek_repeated_conditional_used;
    static char fleek_data_clump_buffer[8192];
    static char fleek_too_many_constants_buffer[4096];
    static char fleek_too_many_instance_variables_buffer[4096];
    static char fleek_too_many_methods_buffer[4096];
    static char fleek_uncommunicative_method_name_buffer[8192];
    static size_t fleek_uncommunicative_method_name_used;
    static char fleek_uncommunicative_module_name_buffer[8192];
    static size_t fleek_uncommunicative_module_name_used;
    static char fleek_uncommunicative_parameter_name_buffer[8192];
    static size_t fleek_uncommunicative_parameter_name_used;
    static char fleek_uncommunicative_variable_name_buffer[8192];
    static size_t fleek_uncommunicative_variable_name_used;
    static size_t fleek_data_clump_used;
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
    static int fleek_class_count;
    static int fleek_module_count;
    static int fleek_finding_count;
    static int fleek_unsupported;
    static int fleek_suppressed;
    static int fleek_bad_suppression;
    static const pm_node_t *fleek_only_scope;
    static const pm_node_t *fleek_namespace_scope;
    static const pm_node_t *fleek_inner_namespace_scope;
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

    static int fleek_comment_suppression(const pm_comment_t *comment, const char *detector) {
      char needle[128];
      int needle_written = snprintf(needle, sizeof(needle), ":reek:%s", detector);
      if (needle_written < 0 || (size_t) needle_written >= sizeof(needle)) return -1;
      size_t needle_length = (size_t) needle_written;
      const uint8_t *directive = NULL;
      for (const uint8_t *cursor = comment->location.start; cursor + needle_length <= comment->location.end; cursor++) {
        if (memcmp(cursor, needle, needle_length) == 0 &&
            (cursor + needle_length == comment->location.end || (!isalnum(cursor[needle_length]) && cursor[needle_length] != '_'))) {
          directive = cursor + needle_length;
        }
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

    static int fleek_context_suppression(pm_parser_t *parser, const uint8_t *keyword, const char *detector) {
      int setting = 0;
      for (pm_list_node_t *item = parser->comment_list.head; item != NULL; item = item->next) {
        pm_comment_t *comment = (pm_comment_t *) item;
        if (comment->location.end > keyword || !fleek_only_comments_between(comment->location.end, keyword)) continue;
        int current = fleek_comment_suppression(comment, detector);
        if (current < 0) return current;
        if (current != 0) setting = current;
      }
      return setting;
    }

    static int fleek_method_suppressed(pm_parser_t *parser, const pm_node_t *scope, const pm_def_node_t *method, const char *detector) {
      const uint8_t *scope_keyword = NULL;
      if (scope != NULL && PM_NODE_TYPE_P(scope, PM_CLASS_NODE))
        scope_keyword = ((const pm_class_node_t *) scope)->class_keyword_loc.start;
      else if (scope != NULL && PM_NODE_TYPE_P(scope, PM_MODULE_NODE))
        scope_keyword = ((const pm_module_node_t *) scope)->module_keyword_loc.start;
      int scope_setting = scope_keyword == NULL ? 0 : fleek_context_suppression(parser, scope_keyword, detector);
      if (scope_setting < 0) return scope_setting;
      int method_setting = fleek_context_suppression(parser, method->def_keyword_loc.start, detector);
      if (method_setting < 0) return method_setting;
      return (method_setting != 0 ? method_setting : scope_setting) == 1;
    }

    typedef struct {
      const uint8_t *name;
      size_t name_length;
      int lines[128];
      size_t line_count;
    } fleek_group_t;

    static fleek_group_t fleek_groups[64];
    static size_t fleek_group_count;
    enum { FLEEK_DUPLICATION_PARSE_ERROR = -1, FLEEK_DUPLICATION_NUL_SOURCE = -2, FLEEK_DUPLICATION_UNSUPPORTED_SOURCE = -4, FLEEK_DUPLICATION_LEGACY_PARSE_ERROR = -5 };
    static bool fleek_constants_equal(pm_parser_t *parser, pm_constant_id_t left, pm_constant_id_t right);

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
        if (fleek_module_count == 2) fleek_inner_namespace_scope = node;
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

    static bool fleek_core_subclass(pm_parser_t *parser, pm_constant_id_t id) {
      return fleek_name_is(parser, id, "Array") || fleek_name_is(parser, id, "Hash") || fleek_name_is(parser, id, "String");
    }

    static int fleek_source_line(const uint8_t *source, const uint8_t *position) {
      int line = 1;
      for (const uint8_t *cursor = source; cursor < position; cursor++) if (*cursor == '\\n') line++;
      return line;
    }

    typedef struct {
      size_t class_count;
      size_t module_count;
      const pm_node_t *scope;
      const pm_node_t *outer_class;
      const pm_node_t *nested_class;
    } fleek_attribute_scopes_t;

    static bool fleek_collect_attribute_scopes(const pm_node_t *node, void *data) {
      fleek_attribute_scopes_t *scopes = (fleek_attribute_scopes_t *) data;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE)) {
        scopes->class_count++;
        if (scopes->class_count == 1) scopes->outer_class = node;
        if (scopes->class_count == 2) scopes->nested_class = node;
        if (scopes->scope == NULL) scopes->scope = node;
      }
      if (PM_NODE_TYPE_P(node, PM_MODULE_NODE)) {
        scopes->module_count++;
        if (scopes->scope == NULL) scopes->scope = node;
      }
      return true;
    }

    static bool fleek_class_has_direct_child(const pm_node_t *class_scope, const pm_node_t *child) {
      const pm_node_t *body = ((const pm_class_node_t *) class_scope)->body;
      if (!PM_NODE_TYPE_P(body, PM_STATEMENTS_NODE)) return false;
      const pm_node_list_t *statements = &((const pm_statements_node_t *) body)->body;
      for (size_t index = 0; index < statements->size; index++) {
        if (statements->nodes[index] == child) return true;
      }
      return false;
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
      fleek_attribute_scopes_t scopes = {0, 0, NULL, NULL, NULL};
      pm_visit_node(root, fleek_collect_attribute_scopes, &scopes);
      bool simple_scope = scopes.class_count + scopes.module_count == 1 && scopes.scope != NULL;
      bool nested_class_scope = scopes.class_count == 2 && scopes.module_count == 0 &&
        fleek_class_has_direct_child(scopes.outer_class, scopes.nested_class);
      if (!simple_scope && !nested_class_scope) {
        fleek_attribute_search_t search = { &parser, false };
        pm_visit_node(root, fleek_has_attribute_writer, &search);
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
        return search.found ? -4 : 0;
      }
      const pm_node_t *constant_path;
      const pm_node_t *body;
      const pm_node_t *scope_node = nested_class_scope ? scopes.outer_class : scopes.scope;
      if (PM_NODE_TYPE_P(scope_node, PM_CLASS_NODE)) {
        const pm_class_node_t *class_node = (const pm_class_node_t *) scope_node;
        constant_path = class_node->constant_path;
        body = class_node->body;
      } else {
        const pm_module_node_t *module_node = (const pm_module_node_t *) scope_node;
        constant_path = module_node->constant_path;
        body = module_node->body;
      }
      if (!PM_NODE_TYPE_P(constant_path, PM_CONSTANT_READ_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) constant_path)->name);
      char nested_class_name[512];
      size_t nested_class_name_length = class_name->length;
      const char *scope_name = (const char *) class_name->start;
      if (nested_class_scope) {
        const pm_class_node_t *nested = (const pm_class_node_t *) scopes.nested_class;
        if (!PM_NODE_TYPE_P(nested->constant_path, PM_CONSTANT_READ_NODE)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        pm_constant_t *nested_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) nested->constant_path)->name);
        int written = snprintf(nested_class_name, sizeof(nested_class_name), "%.*s::%.*s", (int) class_name->length, class_name->start, (int) nested_name->length, nested_name->start);
        if (written < 0 || (size_t) written >= sizeof(nested_class_name)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        scope_name = nested_class_name;
        nested_class_name_length = (size_t) written;
      }
      fleek_class_t scope = { &parser, (const char *) class_name->start, class_name->length, 0 };
      if (body != NULL) pm_visit_node(body, fleek_attribute_calls, &scope);
      if (nested_class_scope) {
        const pm_class_node_t *nested = (const pm_class_node_t *) scopes.nested_class;
        fleek_class_t nested_scope = { &parser, scope_name, nested_class_name_length, 0 };
        fleek_attribute_public = true;
        if (nested->body != NULL) pm_visit_node(nested->body, fleek_attribute_calls, &nested_scope);
      }
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

    typedef struct {
      size_t class_count;
      size_t module_count;
      const pm_node_t *outer_class;
      const pm_node_t *nested_class;
    } fleek_instance_variable_scopes_t;

    static bool fleek_collect_instance_variable_scopes(const pm_node_t *node, void *data) {
      fleek_instance_variable_scopes_t *scopes = (fleek_instance_variable_scopes_t *) data;
      if (PM_NODE_TYPE_P(node, PM_CLASS_NODE)) {
        scopes->class_count++;
        if (scopes->class_count == 1) scopes->outer_class = node;
        if (scopes->class_count == 2) scopes->nested_class = node;
      }
      if (PM_NODE_TYPE_P(node, PM_MODULE_NODE)) scopes->module_count++;
      return true;
    }

    static bool fleek_instance_variable_nested_class_scope(const fleek_instance_variable_scopes_t *scopes) {
      return scopes->class_count == 2 && scopes->module_count == 0 &&
        fleek_class_has_direct_child(scopes->outer_class, scopes->nested_class);
    }

    static int fleek_instance_variable_assumptions_for_class(pm_parser_t *parser, const uint8_t *source_start, const pm_node_t *node, const char *class_name, size_t class_name_length, char *output_buffer, size_t output_capacity, size_t *used) {
      const pm_class_node_t *class_node = (const pm_class_node_t *) node;
      fleek_instance_variables_t variables = { parser, {0}, 0, {0}, 0, 0, 0 };
      if (class_node->body != NULL) pm_visit_node(class_node->body, fleek_instance_methods, &variables);
      int line = fleek_source_line(source_start, class_node->class_keyword_loc.start);
      for (size_t index = 0; index < variables.assumption_count; index++) {
        pm_constant_id_t name = variables.assumptions[index];
        if (fleek_id_in_list(variables.initialized, variables.initialized_count, name)) continue;
        pm_constant_t *variable = pm_constant_pool_id_to_constant(&parser->constant_pool, name);
        if (*used >= output_capacity) { variables.unsupported = 1; break; }
        int written = snprintf(output_buffer + *used, output_capacity - *used, "%d\\t%.*s\\t%.*s\\n", line, (int) class_name_length, class_name, (int) variable->length, variable->start);
        if (written < 0 || (size_t) written >= output_capacity - *used) { variables.unsupported = 1; break; }
        *used += (size_t) written;
      }
      return variables.unsupported ? -4 : 0;
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
      fleek_instance_variable_scopes_t scopes = {0, 0, NULL, NULL};
      pm_visit_node(root, fleek_collect_instance_variable_scopes, &scopes);
      if (scopes.class_count == 0) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
      }
      bool simple_scope = scopes.class_count == 1 && scopes.module_count == 0;
      bool nested_class_scope = fleek_instance_variable_nested_class_scope(&scopes);
      if (!simple_scope && !nested_class_scope) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      const pm_node_t *outer_node = scopes.outer_class;
      const pm_class_node_t *class_node = (const pm_class_node_t *) outer_node;
      if (!PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) class_node->constant_path)->name);
      size_t used = 0;
      if (fleek_instance_variable_assumptions_for_class(&parser, (const uint8_t *) source, outer_node, (const char *) class_name->start, class_name->length, fleek_instance_variable_assumption_buffer, sizeof(fleek_instance_variable_assumption_buffer), &used) != 0) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      if (nested_class_scope) {
        const pm_class_node_t *nested = (const pm_class_node_t *) scopes.nested_class;
        if (!PM_NODE_TYPE_P(nested->constant_path, PM_CONSTANT_READ_NODE)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        pm_constant_t *nested_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) nested->constant_path)->name);
        char nested_class_name[512];
        int written = snprintf(nested_class_name, sizeof(nested_class_name), "%.*s::%.*s", (int) class_name->length, class_name->start, (int) nested_name->length, nested_name->start);
        if (written < 0 || (size_t) written >= sizeof(nested_class_name) ||
            fleek_instance_variable_assumptions_for_class(&parser, (const uint8_t *) source, scopes.nested_class, nested_class_name, (size_t) written, fleek_instance_variable_assumption_buffer, sizeof(fleek_instance_variable_assumption_buffer), &used) != 0) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
      }
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return used > 0 ? 1 : 0;
    }

    const char *fleek_instance_variable_assumption_finding(void) { return fleek_instance_variable_assumption_buffer; }

    typedef struct { pm_parser_t *parser; const pm_node_t *assignment; const pm_call_node_t *call; bool unsupported; } fleek_class_new_search_t;

    static const pm_call_node_t *fleek_class_new_expression(pm_parser_t *parser, const pm_node_t *node) {
      if (!PM_NODE_TYPE_P(node, PM_CALL_NODE)) return NULL;
      const pm_call_node_t *call = (const pm_call_node_t *) node;
      if (call->receiver == NULL || !PM_NODE_TYPE_P(call->receiver, PM_CONSTANT_READ_NODE) || !fleek_name_is(parser, call->name, "new") || !fleek_name_is(parser, ((const pm_constant_read_node_t *) call->receiver)->name, "Class")) return NULL;
      return call;
    }

    static bool fleek_class_new_assignment_visit(const pm_node_t *node, void *data) {
      fleek_class_new_search_t *search = (fleek_class_new_search_t *) data;
      const pm_node_t *value = NULL;
      if (PM_NODE_TYPE_P(node, PM_CONSTANT_WRITE_NODE)) value = ((const pm_constant_write_node_t *) node)->value;
      else if (PM_NODE_TYPE_P(node, PM_CONSTANT_PATH_WRITE_NODE)) value = ((const pm_constant_path_write_node_t *) node)->value;
      else if (PM_NODE_TYPE_P(node, PM_CONSTANT_AND_WRITE_NODE)) value = ((const pm_constant_and_write_node_t *) node)->value;
      else if (PM_NODE_TYPE_P(node, PM_CONSTANT_OR_WRITE_NODE)) value = ((const pm_constant_or_write_node_t *) node)->value;
      else if (PM_NODE_TYPE_P(node, PM_CONSTANT_OPERATOR_WRITE_NODE)) value = ((const pm_constant_operator_write_node_t *) node)->value;
      const pm_call_node_t *call = value == NULL ? NULL : fleek_class_new_expression(search->parser, value);
      if (call != NULL) {
        if (search->call != NULL || !PM_NODE_TYPE_P(node, PM_CONSTANT_WRITE_NODE)) { search->unsupported = true; return false; }
        search->assignment = node;
        search->call = call;
        return true;
      }
      return true;
    }

    static fleek_class_new_search_t fleek_find_class_new_assignment(pm_parser_t *parser, pm_node_t *root) {
      fleek_class_new_search_t search = { parser, NULL, NULL, false };
      pm_visit_node(root, fleek_class_new_assignment_visit, &search);
      return search;
    }

    static bool fleek_has_class_new(pm_parser_t *parser, pm_node_t *root) {
      fleek_class_new_search_t search = fleek_find_class_new_assignment(parser, root);
      return search.call != NULL || search.unsupported;
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
      pm_visit_node(root, fleek_collect_classes, NULL);
      fleek_class_new_search_t class_new = fleek_find_class_new_assignment(&parser, root);
      if (class_new.call != NULL || class_new.unsupported) {
        if (class_new.unsupported || class_new.assignment == NULL || class_new.call->block != NULL || class_new.call->arguments == NULL || class_new.call->arguments->arguments.size != 1) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        const pm_node_t *argument = class_new.call->arguments->arguments.nodes[0];
        if (!PM_NODE_TYPE_P(argument, PM_CONSTANT_READ_NODE) || fleek_class_count != 0 || fleek_module_count != 0) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        pm_constant_id_t superclass_id = ((const pm_constant_read_node_t *) argument)->name;
        if (fleek_core_subclass(&parser, superclass_id)) {
          const pm_constant_write_node_t *assignment = (const pm_constant_write_node_t *) class_new.assignment;
          pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser.constant_pool, assignment->name);
          pm_constant_t *superclass_name = pm_constant_pool_id_to_constant(&parser.constant_pool, superclass_id);
          int line = fleek_source_line((const uint8_t *) source, assignment->name_loc.start);
          int written = snprintf(fleek_subclassed_from_core_class_buffer, sizeof(fleek_subclassed_from_core_class_buffer), "%d\\t%.*s\\t%.*s\\n", line, (int) class_name->length, class_name->start, (int) superclass_name->length, superclass_name->start);
          if (written < 0 || (size_t) written >= sizeof(fleek_subclassed_from_core_class_buffer)) {
            pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
          }
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 1;
        }
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
      }
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
      pm_constant_id_t superclass_id = ((const pm_constant_read_node_t *) class_node->superclass)->name;
      pm_constant_t *superclass_name = pm_constant_pool_id_to_constant(&parser.constant_pool, superclass_id);
      bool core = fleek_core_subclass(&parser, superclass_id);
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
      fleek_inner_namespace_scope = NULL;
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
      bool simple_module = fleek_module_count == 1 && fleek_class_count == 0 && PM_NODE_TYPE_P(fleek_only_scope, PM_MODULE_NODE);
      bool nested_module = fleek_module_count == 2 && fleek_class_count == 0 &&
        PM_NODE_TYPE_P(fleek_namespace_scope, PM_MODULE_NODE) && PM_NODE_TYPE_P(fleek_only_scope, PM_MODULE_NODE) &&
        fleek_scope_contains(fleek_namespace_scope, fleek_only_scope) && fleek_module_has_direct_child(fleek_namespace_scope, fleek_only_scope);
      if ((!simple_module && !nested_module) || !PM_NODE_TYPE_P(fleek_only_scope, PM_MODULE_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      const pm_module_node_t *module_node = (const pm_module_node_t *) fleek_only_scope;
      if (!PM_NODE_TYPE_P(module_node->constant_path, PM_CONSTANT_READ_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      pm_constant_t *module_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) module_node->constant_path)->name);
      char qualified_module_name[512];
      const char *context = (const char *) module_name->start;
      size_t context_length = module_name->length;
      if (nested_module) {
        const pm_module_node_t *outer_module = (const pm_module_node_t *) fleek_namespace_scope;
        if (!PM_NODE_TYPE_P(outer_module->constant_path, PM_CONSTANT_READ_NODE)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        pm_constant_t *outer_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) outer_module->constant_path)->name);
        int written = snprintf(qualified_module_name, sizeof(qualified_module_name), "%.*s::%.*s", (int) outer_name->length, outer_name->start, (int) module_name->length, module_name->start);
        if (written < 0 || (size_t) written >= sizeof(qualified_module_name)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        context = qualified_module_name;
        context_length = (size_t) written;
      }
      fleek_module_initialize_t state = { &parser, false };
      if (module_node->body != NULL) pm_visit_node(module_node->body, fleek_module_defines_initialize, &state);
      int result = 0;
      if (state.found) {
        int line = fleek_source_line((const uint8_t *) source, module_node->module_keyword_loc.start);
        int written = snprintf(fleek_module_initialize_buffer, sizeof(fleek_module_initialize_buffer), "%d\\t%.*s\\tinitialize\\n", line, (int) context_length, context);
        result = written < 0 || (size_t) written >= sizeof(fleek_module_initialize_buffer) ? -4 : 1;
      }
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return result;
    }

    const char *fleek_module_initialize_finding(void) { return fleek_module_initialize_buffer; }


    static size_t fleek_parameter_count(const pm_parameters_node_t *parameters) {
      if (parameters == NULL) return 0;
      return parameters->requireds.size + parameters->optionals.size + parameters->posts.size +
        parameters->keywords.size + (parameters->rest != NULL) + (parameters->keyword_rest != NULL) +
        (parameters->block != NULL);
    }

    typedef int (*fleek_method_analyzer_t)(pm_parser_t *, const uint8_t *, const char *, size_t, const pm_node_t *, void *);
    typedef struct { size_t maximum; size_t initialize_maximum; const pm_node_t *scope; } fleek_long_parameter_state_t;
    static int fleek_long_parameter_list_method(pm_parser_t *, const uint8_t *, const char *, size_t, const pm_node_t *, void *);
    typedef struct { bool found; } fleek_nested_method_state_t;
    static bool fleek_find_nested_method(const pm_node_t *node, void *data) {
      fleek_nested_method_state_t *state = (fleek_nested_method_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) { state->found = true; return false; }
      return !PM_NODE_TYPE_P(node, PM_CLASS_NODE) && !PM_NODE_TYPE_P(node, PM_MODULE_NODE);
    }
    static int fleek_missing_safe_method_method(pm_parser_t *, const uint8_t *, const char *, size_t, const pm_node_t *, void *);
    static int fleek_uncommunicative_method_name_method(pm_parser_t *, const uint8_t *, const char *, size_t, const pm_node_t *, void *);

    static int fleek_scan_method_scope(const char *source, size_t length, fleek_method_analyzer_t analyze, void *state,
        const pm_node_t **scope_output) {
      if (scope_output != NULL) *scope_output = NULL;
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
      if (analyze == fleek_uncommunicative_method_name_method && fleek_class_count == 2 && fleek_module_count == 0) {
        const pm_statements_node_t *top = NULL;
        if (PM_NODE_TYPE_P(root, PM_PROGRAM_NODE)) top = (const pm_statements_node_t *) ((const pm_program_node_t *) root)->statements;
        const pm_node_t *outer_node = top != NULL && top->body.size == 1 ? top->body.nodes[0] : NULL;
        const pm_class_node_t *outer = PM_NODE_TYPE_P(outer_node, PM_CLASS_NODE) ? (const pm_class_node_t *) outer_node : NULL;
        const pm_statements_node_t *outer_body = outer != NULL && PM_NODE_TYPE_P(outer->body, PM_STATEMENTS_NODE) ? (const pm_statements_node_t *) outer->body : NULL;
        const pm_node_t *nested_node = NULL;
        if (outer_body != NULL) for (size_t index = 0; index < outer_body->body.size; index++) {
          const pm_node_t *statement = outer_body->body.nodes[index];
          if (!PM_NODE_TYPE_P(statement, PM_CLASS_NODE)) continue;
          if (nested_node != NULL) { nested_node = NULL; break; }
          nested_node = statement;
        }
        const pm_class_node_t *nested = PM_NODE_TYPE_P(nested_node, PM_CLASS_NODE) ? (const pm_class_node_t *) nested_node : NULL;
        if (outer == NULL || nested == NULL || !fleek_class_has_direct_child(outer_node, nested_node) ||
            !PM_NODE_TYPE_P(outer->constant_path, PM_CONSTANT_READ_NODE) || !PM_NODE_TYPE_P(nested->constant_path, PM_CONSTANT_READ_NODE) ||
            (nested->body != NULL && !PM_NODE_TYPE_P(nested->body, PM_STATEMENTS_NODE))) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        pm_constant_t *outer_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) outer->constant_path)->name);
        pm_constant_t *nested_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) nested->constant_path)->name);
        char qualified_name[512];
        int qualified_length = snprintf(qualified_name, sizeof(qualified_name), "%.*s::%.*s", (int) outer_name->length, outer_name->start,
          (int) nested_name->length, nested_name->start);
        if (qualified_length < 0 || (size_t) qualified_length >= sizeof(qualified_name)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        const pm_statements_node_t *nested_body = nested->body == NULL ? NULL : (const pm_statements_node_t *) nested->body;
        int findings = 0; bool unsupported = false;
        if (nested_body != NULL) for (size_t index = 0; index < nested_body->body.size; index++) {
          const pm_node_t *statement = nested_body->body.nodes[index];
          if (PM_NODE_TYPE_P(statement, PM_DEF_NODE)) {
            int result = analyze(&parser, (const uint8_t *) source, qualified_name, (size_t) qualified_length, statement, state);
            if (result < 0) unsupported = true;
            else findings += result;
          } else {
            fleek_nested_method_state_t nested_method = { false }; pm_visit_node(statement, fleek_find_nested_method, &nested_method);
            if (nested_method.found) unsupported = true;
          }
        }
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
        return unsupported ? -4 : findings;
      }
      if (fleek_class_count + fleek_module_count > 1 || (fleek_class_count + fleek_module_count == 1 && fleek_only_scope == NULL)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      if (scope_output != NULL) *scope_output = fleek_only_scope;
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
          const pm_node_t *statement = statements->body.nodes[index];
          if (analyze == fleek_missing_safe_method_method && PM_NODE_TYPE_P(statement, PM_SINGLETON_CLASS_NODE)) {
            const pm_node_t *singleton_body = ((const pm_singleton_class_node_t *) statement)->body;
            if (!PM_NODE_TYPE_P(singleton_body, PM_STATEMENTS_NODE)) { findings = -1; break; }
            const pm_statements_node_t *singleton_statements = (const pm_statements_node_t *) singleton_body;
            for (size_t method_index = 0; method_index < singleton_statements->body.size; method_index++) {
              const pm_node_t *singleton_method = singleton_statements->body.nodes[method_index];
              if (!PM_NODE_TYPE_P(singleton_method, PM_DEF_NODE)) continue;
              int result = analyze(&parser, (const uint8_t *) source, class_name_text,
                class_name_length, singleton_method, (void *) statement);
              if (result < 0) findings = -1;
              else findings += result;
            }
            continue;
          }
          if (!PM_NODE_TYPE_P(statement, PM_DEF_NODE)) continue;
          int result = analyze(&parser, (const uint8_t *) source, class_name_text,
            class_name_length, statement, state);
          if (result < 0) findings = -1;
          else findings += result;
        }
      }
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return findings < 0 ? -4 : findings;
    }

    typedef struct {
      const pm_def_node_t *methods[128];
      bool private_methods[128];
      bool used[128];
      size_t count;
      bool unsupported;
    } fleek_unused_private_state_t;
    typedef struct {
      pm_parser_t *parser;
      fleek_unused_private_state_t *state;
      size_t current_method;
    } fleek_unused_private_call_state_t;
    static bool fleek_unused_private_call(const pm_node_t *node, void *data) {
      fleek_unused_private_call_state_t *call_state = (fleek_unused_private_call_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE) || PM_NODE_TYPE_P(node, PM_BLOCK_NODE)) {
        call_state->state->unsupported = true; return false;
      }
      if (!PM_NODE_TYPE_P(node, PM_CALL_NODE)) return true;
      const pm_call_node_t *call = (const pm_call_node_t *) node;
      if (fleek_name_is(call_state->parser, call->name, "send") || fleek_name_is(call_state->parser, call->name, "public_send") ||
          fleek_name_is(call_state->parser, call->name, "__send__") || fleek_name_is(call_state->parser, call->name, "method") ||
          fleek_name_is(call_state->parser, call->name, "eval") || fleek_name_is(call_state->parser, call->name, "class_eval") ||
          fleek_name_is(call_state->parser, call->name, "instance_eval") || fleek_name_is(call_state->parser, call->name, "define_method")) {
        call_state->state->unsupported = true; return false;
      }
      if (call->receiver != NULL && !PM_NODE_TYPE_P(call->receiver, PM_SELF_NODE)) return true;
      for (size_t index = 0; index < call_state->state->count; index++) {
        if (index == call_state->current_method || !call_state->state->private_methods[index]) continue;
        if (fleek_constants_equal(call_state->parser, call->name, call_state->state->methods[index]->name)) call_state->state->used[index] = true;
      }
      return true;
    }
    static bool fleek_unused_private_collect_methods(pm_parser_t *parser, const pm_class_node_t *class_node,
      fleek_unused_private_state_t *state) {
      if (!PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE)) return false;
      if (class_node->body == NULL) return true;
      if (!PM_NODE_TYPE_P(class_node->body, PM_STATEMENTS_NODE)) return false;
      const pm_statements_node_t *statements = (const pm_statements_node_t *) class_node->body;
      bool private_visibility = false;
      if (statements->body.size > 128) return false;
      for (size_t index = 0; index < statements->body.size; index++) {
        const pm_node_t *item = statements->body.nodes[index];
        if (PM_NODE_TYPE_P(item, PM_CALL_NODE)) {
          const pm_call_node_t *call = (const pm_call_node_t *) item;
          bool visibility_call = fleek_name_is(parser, call->name, "private") || fleek_name_is(parser, call->name, "public") || fleek_name_is(parser, call->name, "protected");
          if (call->receiver == NULL && visibility_call && call->arguments != NULL &&
              PM_NODE_TYPE_P((const pm_node_t *) call->arguments, PM_ARGUMENTS_NODE) &&
              call->arguments->arguments.size == 1 && PM_NODE_TYPE_P(call->arguments->arguments.nodes[0], PM_SYMBOL_NODE)) {
            const pm_symbol_node_t *symbol = (const pm_symbol_node_t *) call->arguments->arguments.nodes[0];
            const uint8_t *name = pm_string_source(&symbol->unescaped);
            size_t length = pm_string_length(&symbol->unescaped);
            for (size_t method_index = 0; method_index < state->count; method_index++) {
              pm_constant_t *method_name = pm_constant_pool_id_to_constant(&parser->constant_pool, state->methods[method_index]->name);
              if (method_name->length == length && memcmp(method_name->start, name, length) == 0) {
                state->private_methods[method_index] = fleek_name_is(parser, call->name, "private");
              }
            }
            continue;
          }
          if (call->receiver == NULL && call->arguments == NULL && visibility_call) {
            private_visibility = fleek_name_is(parser, call->name, "private");
            continue;
          }
          return false;
        }
        if (!PM_NODE_TYPE_P(item, PM_DEF_NODE) || state->count == 128) return false;
        const pm_def_node_t *method = (const pm_def_node_t *) item;
        if (method->receiver != NULL) return false;
        state->methods[state->count] = method;
        state->private_methods[state->count] = private_visibility;
        state->used[state->count] = false;
        state->count++;
      }
      return true;
    }
    static void fleek_unused_private_collect_calls(pm_parser_t *parser, fleek_unused_private_state_t *state) {
      for (size_t index = 0; !state->unsupported && index < state->count; index++) {
        const pm_def_node_t *method = state->methods[index];
        if (method->body == NULL) continue;
        fleek_unused_private_call_state_t call_state = { parser, state, index };
        pm_visit_node(method->body, fleek_unused_private_call, &call_state);
      }
    }
    static int fleek_unused_private_render_findings(pm_parser_t *parser, const char *source,
      const pm_class_node_t *class_node, fleek_unused_private_state_t *state) {
      pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser->constant_pool,
        ((const pm_constant_read_node_t *) class_node->constant_path)->name);
      int findings = 0;
      for (size_t index = 0; !state->unsupported && index < state->count; index++) {
        if (!state->private_methods[index] || state->used[index]) continue;
        const pm_def_node_t *method = state->methods[index];
        pm_constant_t *name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
        int written = snprintf(fleek_unused_private_method_buffer + fleek_unused_private_method_used,
          sizeof(fleek_unused_private_method_buffer) - fleek_unused_private_method_used, "%d\\t%.*s\\t%.*s\\n",
          fleek_source_line((const uint8_t *) source, method->def_keyword_loc.start), (int) class_name->length,
          class_name->start, (int) name->length, name->start);
        if (written < 0 || (size_t) written >= sizeof(fleek_unused_private_method_buffer) - fleek_unused_private_method_used) {
          state->unsupported = true;
          break;
        }
        fleek_unused_private_method_used += (size_t) written;
        findings++;
      }
      return findings;
    }
    int fleek_unused_private_method(const char *source, size_t length) {
      fleek_unused_private_method_buffer[0] = 0; fleek_unused_private_method_used = 0;
      fleek_class_count = fleek_module_count = 0; fleek_only_scope = NULL;
      if (memchr(source, 0, length) != NULL) return -2;
      fleek_source_start = (const uint8_t *) source;
      pm_options_t options = {0}; options.line = 1; options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser; pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -1; }
      pm_visit_node(root, fleek_collect_classes, NULL);
      if (fleek_class_count != 1 || fleek_module_count != 0 || !PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      const pm_class_node_t *class_node = (const pm_class_node_t *) fleek_only_scope;
      fleek_unused_private_state_t state = { .count = 0, .unsupported = false };
      bool supported = fleek_unused_private_collect_methods(&parser, class_node, &state);
      if (supported) fleek_unused_private_collect_calls(&parser, &state);
      int findings = supported ? fleek_unused_private_render_findings(&parser, source, class_node, &state) : 0;
      if (!supported) state.unsupported = true;
      pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
      return state.unsupported ? -4 : findings;
    }
    const char *fleek_unused_private_method_finding(void) { return fleek_unused_private_method_buffer; }

    typedef struct { size_t count; } fleek_scope_count_state_t;
    typedef struct { pm_constant_id_t names[128]; size_t count; } fleek_parameter_names_t;
    typedef struct { size_t max_copies; size_t min_clump; pm_constant_id_t names[128][64]; size_t counts[128]; size_t lines[128]; size_t methods; bool unsupported; bool singleton_methods; } fleek_data_clump_state_t;
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

    static int fleek_long_parameter_list_method(pm_parser_t *parser, const uint8_t *source,
        const char *class_name, size_t class_name_length, const pm_node_t *node, void *data) {
      if (!PM_NODE_TYPE_P(node, PM_DEF_NODE)) return 0;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      const fleek_long_parameter_state_t *state = (const fleek_long_parameter_state_t *) data;
      int suppressed = fleek_method_suppressed(parser, state->scope, method, "LongParameterList");
      if (suppressed < 0) return -1;
      if (suppressed) return 0;
      bool class_method = method->receiver != NULL;
      if ((class_method && !PM_NODE_TYPE_P(method->receiver, PM_SELF_NODE)) || (method->parameters != NULL && !PM_NODE_TYPE_P((const pm_node_t *) method->parameters, PM_PARAMETERS_NODE))) return -1;
      size_t count = fleek_parameter_count((const pm_parameters_node_t *) method->parameters);
      size_t method_maximum = fleek_name_is(parser, method->name, "initialize") ? state->initialize_maximum : state->maximum;
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

    int fleek_long_parameter_list(const char *source, size_t length, size_t maximum, size_t initialize_maximum) {
      fleek_long_parameter_list_buffer[0] = 0;
      fleek_long_parameter_list_used = 0;
      fleek_long_parameter_state_t state = { maximum, initialize_maximum, NULL };
      return fleek_scan_method_scope(source, length, fleek_long_parameter_list_method, &state, &state.scope);
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
      return fleek_scan_method_scope(source, length, fleek_boolean_parameter_method, NULL, NULL);
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
      return fleek_scan_method_scope(source, length, fleek_long_yield_list_method, &maximum, NULL);
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
    static bool fleek_find_body_name_in_blocks(const pm_node_t *node, void *data) {
      fleek_name_search_t *search = (fleek_name_search_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      pm_constant_id_t name = 0;
      if (PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_READ_NODE)) name = ((const pm_local_variable_read_node_t *) node)->name;
      if (PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_WRITE_NODE)) name = ((const pm_local_variable_write_node_t *) node)->name;
      if (name != 0 && fleek_constants_equal(search->parser, search->name, name)) { search->found = true; return false; }
      return true;
    }
    static bool fleek_body_uses_name_in_blocks(pm_parser_t *parser, const pm_node_t *body, pm_constant_id_t name) {
      if (body == NULL) return false;
      fleek_name_search_t search = { parser, name, false };
      pm_visit_node(body, fleek_find_body_name_in_blocks, &search);
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
          PM_NODE_TYPE_P(node, PM_INTERPOLATED_STRING_NODE) || PM_NODE_TYPE_P(node, PM_EMBEDDED_VARIABLE_NODE) || PM_NODE_TYPE_P(node, PM_EMBEDDED_STATEMENTS_NODE) ||
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
    typedef struct { bool supported; size_t blocks; } fleek_single_block_body_state_t;
    static bool fleek_single_block_body_node_supported(const pm_node_t *node, void *data) {
      fleek_single_block_body_state_t *state = (fleek_single_block_body_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_BLOCK_NODE)) {
        state->blocks++;
        if (state->blocks > 1) { state->supported = false; return false; }
        return true;
      }
      if (PM_NODE_TYPE_P(node, PM_BLOCK_PARAMETERS_NODE) ||
          PM_NODE_TYPE_P(node, PM_PARAMETERS_NODE) || PM_NODE_TYPE_P(node, PM_REQUIRED_PARAMETER_NODE) ||
          PM_NODE_TYPE_P(node, PM_OPTIONAL_PARAMETER_NODE) || PM_NODE_TYPE_P(node, PM_REQUIRED_KEYWORD_PARAMETER_NODE) ||
          PM_NODE_TYPE_P(node, PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) return true;
      return fleek_method_body_node_supported(node, &state->supported);
    }
    static bool fleek_single_block_body_supported(const pm_node_t *body) {
      if (body == NULL) return true;
      fleek_single_block_body_state_t state = { true, 0 };
      pm_visit_node(body, fleek_single_block_body_node_supported, &state);
      return state.supported;
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
    static int fleek_method_api_method(pm_parser_t *parser, const uint8_t *source, const char *class_name,
        size_t class_name_length, const pm_node_t *node, void *data) {
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      if (method->receiver != NULL) return -1;
      if (data != NULL ? !fleek_single_block_body_supported(method->body) : !fleek_method_body_supported(method->body)) return -1;
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
          bool include_block_locals = data != NULL && *((int *) data) == 2;
          bool unused = !(include_block_locals ? fleek_body_uses_name_in_blocks(parser, method->body, name_id) : fleek_body_uses_name(parser, method->body, name_id));
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
      return findings;
    }
    int fleek_unused_parameters(const char *source, size_t length) {
      fleek_unused_parameters_buffer[0] = 0; fleek_unused_parameters_used = 0;
      int unused_parameter_mode = 2;
      return fleek_scan_method_scope(source, length, fleek_method_api_method, &unused_parameter_mode, NULL);
    }
    const char *fleek_unused_parameters_finding(void) { return fleek_unused_parameters_buffer; }
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
      return fleek_scan_method_scope(source, length, fleek_manual_dispatch_method, NULL, NULL);
    }
    const char *fleek_manual_dispatch_finding(void) { return fleek_manual_dispatch_buffer; }
    static bool fleek_missing_safe_version_exists(pm_parser_t *parser, const pm_def_node_t *method,
        const pm_constant_t *name, const pm_node_t *singleton_scope) {
      if (fleek_only_scope == NULL || name->length < 2 || name->start[name->length - 1] != '!') return false;
      const pm_node_t *body = singleton_scope != NULL ? ((const pm_singleton_class_node_t *) singleton_scope)->body :
        (PM_NODE_TYPE_P(fleek_only_scope, PM_CLASS_NODE) ?
          ((const pm_class_node_t *) fleek_only_scope)->body : ((const pm_module_node_t *) fleek_only_scope)->body);
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
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      const pm_node_t *singleton_scope = data;
      if ((method->receiver != NULL && singleton_scope == NULL) || fleek_only_scope == NULL) return 0;
      pm_constant_t *name = pm_constant_pool_id_to_constant(&parser->constant_pool, method->name);
      if (!fleek_missing_safe_version_exists(parser, method, name, singleton_scope)) {
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
      return fleek_scan_method_scope(source, length, fleek_missing_safe_method_method, NULL, NULL);
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
      if (memchr(source, 0, length) != NULL) return -2;
      fleek_class_count = fleek_module_count = 0;
      fleek_only_scope = NULL;
      fleek_source_start = (const uint8_t *) source;
      pm_options_t options = {0};
      options.line = 1;
      options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser;
      pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -1; }
      pm_visit_node(root, fleek_collect_classes, NULL);
      if (fleek_class_count <= 1) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
        return fleek_scan_method_scope(source, length, fleek_repeated_conditional_method, &state, NULL);
      }
      if (fleek_module_count != 0 || !PM_NODE_TYPE_P(root, PM_PROGRAM_NODE) ||
          ((const pm_program_node_t *) root)->statements == NULL) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      size_t total_classes = fleek_class_count;
      const pm_statements_node_t *program = (const pm_statements_node_t *) ((const pm_program_node_t *) root)->statements;
      size_t direct_classes = 0;
      size_t analyzed = 0;
      int findings = 0;
      for (size_t index = 0; index < program->body.size; index++) {
        const pm_node_t *statement = program->body.nodes[index];
        if (!PM_NODE_TYPE_P(statement, PM_CLASS_NODE)) continue;
        direct_classes++;
        const pm_class_node_t *class_node = (const pm_class_node_t *) statement;
        if (!PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE) ||
            !PM_NODE_TYPE_P(class_node->body, PM_STATEMENTS_NODE)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser.constant_pool,
          ((const pm_constant_read_node_t *) class_node->constant_path)->name);
        fleek_only_scope = statement;
        fleek_class_count = 1;
        fleek_module_count = 0;
        state.count = 0;
        state.unsupported = false;
        state.class_name = (const char *) class_name->start;
        state.class_name_length = class_name->length;
        const pm_statements_node_t *class_body = (const pm_statements_node_t *) class_node->body;
        for (size_t method_index = 0; method_index < class_body->body.size; method_index++) {
          const pm_node_t *method = class_body->body.nodes[method_index];
          if (!PM_NODE_TYPE_P(method, PM_DEF_NODE)) continue;
          int result = fleek_repeated_conditional_method(&parser, (const uint8_t *) source,
            state.class_name, state.class_name_length, method, &state);
          if (result < 0) findings = -1;
          else findings += result;
        }
        analyzed++;
      }
      if (direct_classes != total_classes || analyzed != total_classes) findings = -1;
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return findings < 0 ? -4 : findings;
    }
    const char *fleek_repeated_conditional_finding(void) { return fleek_repeated_conditional_buffer; }

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
    static int fleek_count_scope(const char *source, size_t length, const char *detector, size_t threshold) {
      if (memchr(source, 0, length) != NULL) return -2;
      fleek_class_count = fleek_module_count = 0; fleek_only_scope = NULL;
      pm_options_t options = {0}; options.line = 1; options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser; pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      if (parser.error_list.head != NULL) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -1; }
      pm_visit_node(root, fleek_collect_classes, NULL);
      if (strcmp(detector, "TooManyMethods") == 0 && fleek_class_count == 2 && fleek_module_count == 0) {
        const pm_statements_node_t *top = NULL;
        if (PM_NODE_TYPE_P(root, PM_PROGRAM_NODE)) top = (const pm_statements_node_t *) ((const pm_program_node_t *) root)->statements;
        const pm_node_t *outer_node = NULL; bool unsupported = false;
        if (top != NULL) for (size_t index = 0; index < top->body.size; index++) {
          const pm_node_t *statement = top->body.nodes[index];
          if (PM_NODE_TYPE_P(statement, PM_CLASS_NODE) && outer_node == NULL) outer_node = statement;
          else if (PM_NODE_TYPE_P(statement, PM_CLASS_NODE)) { outer_node = NULL; break; }
          else unsupported = true;
        }
        const pm_class_node_t *outer = PM_NODE_TYPE_P(outer_node, PM_CLASS_NODE) ? (const pm_class_node_t *) outer_node : NULL;
        const pm_statements_node_t *outer_body = outer != NULL && PM_NODE_TYPE_P(outer->body, PM_STATEMENTS_NODE) ? (const pm_statements_node_t *) outer->body : NULL;
        const pm_node_t *nested_node = NULL;
        if (outer_body != NULL) for (size_t index = 0; index < outer_body->body.size; index++) {
          const pm_node_t *statement = outer_body->body.nodes[index];
          if (!PM_NODE_TYPE_P(statement, PM_CLASS_NODE)) continue;
          if (nested_node != NULL) { nested_node = NULL; break; }
          nested_node = statement;
        }
        const pm_class_node_t *nested = PM_NODE_TYPE_P(nested_node, PM_CLASS_NODE) ? (const pm_class_node_t *) nested_node : NULL;
        if (outer == NULL || nested == NULL || !fleek_class_has_direct_child(outer_node, nested_node) ||
            !PM_NODE_TYPE_P(outer->constant_path, PM_CONSTANT_READ_NODE) || !PM_NODE_TYPE_P(nested->constant_path, PM_CONSTANT_READ_NODE) ||
            (nested->body != NULL && !PM_NODE_TYPE_P(nested->body, PM_STATEMENTS_NODE))) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        pm_constant_t *outer_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) outer->constant_path)->name);
        pm_constant_t *nested_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) nested->constant_path)->name);
        const pm_class_node_t *scopes[2] = { outer, nested };
        size_t used = 0; int findings = 0;
        for (size_t scope_index = 0; scope_index < 2; scope_index++) {
          const pm_class_node_t *scope = scopes[scope_index];
          const pm_statements_node_t *body = scope->body == NULL ? NULL : (const pm_statements_node_t *) scope->body;
          size_t count = 0;
          if (body != NULL) for (size_t index = 0; index < body->body.size; index++) {
            const pm_node_t *statement = body->body.nodes[index];
            if (PM_NODE_TYPE_P(statement, PM_DEF_NODE)) {
              if (((const pm_def_node_t *) statement)->receiver == NULL) count++;
            } else {
              fleek_nested_method_state_t state = { false }; pm_visit_node(statement, fleek_find_nested_method, &state);
              if (state.found) unsupported = true;
            }
          }
          if (count <= threshold) continue;
          int written = snprintf(fleek_too_many_methods_buffer + used, sizeof(fleek_too_many_methods_buffer) - used,
            "%zu\\t%.*s%s%.*s\\t%zu\\t\\n", fleek_source_line((const uint8_t *) source, scope->class_keyword_loc.start),
            (int) outer_name->length, outer_name->start, scope_index == 1 ? "::" : "",
            scope_index == 1 ? (int) nested_name->length : 0,
            scope_index == 1 ? (const char *) nested_name->start : "", count);
          if (written < 0 || (size_t) written >= sizeof(fleek_too_many_methods_buffer) - used) { unsupported = true; break; }
          used += (size_t) written; findings++;
        }
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
        return unsupported ? (findings > 0 ? -5 : -4) : findings;
      }
      if (strcmp(detector, "TooManyInstanceVariables") == 0 && fleek_class_count == 3 && fleek_module_count == 0) {
        const pm_statements_node_t *top = NULL;
        if (PM_NODE_TYPE_P(root, PM_PROGRAM_NODE)) {
          top = (const pm_statements_node_t *) ((const pm_program_node_t *) root)->statements;
        }
        const pm_node_t *outer_node = top != NULL && top->body.size == 1 ? top->body.nodes[0] : NULL;
        const pm_class_node_t *outer = PM_NODE_TYPE_P(outer_node, PM_CLASS_NODE) ? (const pm_class_node_t *) outer_node : NULL;
        const pm_statements_node_t *children = outer != NULL && PM_NODE_TYPE_P(outer->body, PM_STATEMENTS_NODE) ? (const pm_statements_node_t *) outer->body : NULL;
        if (outer == NULL || children == NULL || children->body.size != 2 ||
            !PM_NODE_TYPE_P(children->body.nodes[0], PM_CLASS_NODE) || !PM_NODE_TYPE_P(children->body.nodes[1], PM_CLASS_NODE) ||
            !PM_NODE_TYPE_P(outer->constant_path, PM_CONSTANT_READ_NODE)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        const pm_class_node_t *nested[2] = { (const pm_class_node_t *) children->body.nodes[0], (const pm_class_node_t *) children->body.nodes[1] };
        pm_constant_t *outer_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) outer->constant_path)->name);
        size_t used = 0; int findings = 0; bool failed = false;
        for (size_t index = 0; index < 2; index++) {
          const pm_class_node_t *scope = nested[index];
          if (!fleek_scope_contains(outer_node, (const pm_node_t *) scope) || !fleek_class_has_direct_child(outer_node, (const pm_node_t *) scope) ||
              !PM_NODE_TYPE_P(scope->constant_path, PM_CONSTANT_READ_NODE) || (scope->body != NULL && !PM_NODE_TYPE_P(scope->body, PM_STATEMENTS_NODE))) {
            failed = true; break;
          }
          pm_constant_t *nested_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) scope->constant_path)->name);
          fleek_parameter_names_t variables = { { 0 }, 0 };
          if (scope->body != NULL) pm_visit_node(scope->body, fleek_ivar_count_visit, &variables);
          if (variables.count == 128) { failed = true; break; }
          if (variables.count <= threshold) continue;
          int written = snprintf(fleek_too_many_instance_variables_buffer + used,
            sizeof(fleek_too_many_instance_variables_buffer) - used, "%zu\\t%.*s::%.*s\\t%zu\\t\\n",
            fleek_source_line((const uint8_t *) source, scope->class_keyword_loc.start), (int) outer_name->length, outer_name->start,
            (int) nested_name->length, nested_name->start, variables.count);
          if (written < 0 || (size_t) written >= sizeof(fleek_too_many_instance_variables_buffer) - used) { failed = true; break; }
          used += (size_t) written; findings++;
        }
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
        return failed ? -4 : findings;
      }
      if (strcmp(detector, "TooManyConstants") == 0 && fleek_class_count == 0 && fleek_module_count == 2) {
        const pm_module_node_t *outer = (const pm_module_node_t *) fleek_namespace_scope;
        const pm_module_node_t *inner = (const pm_module_node_t *) fleek_only_scope;
        bool direct_pair = PM_NODE_TYPE_P(fleek_namespace_scope, PM_MODULE_NODE) && PM_NODE_TYPE_P(fleek_only_scope, PM_MODULE_NODE) &&
          fleek_scope_contains(fleek_namespace_scope, fleek_only_scope) && fleek_module_has_direct_child(fleek_namespace_scope, fleek_only_scope) &&
          PM_NODE_TYPE_P(root, PM_PROGRAM_NODE) && ((const pm_program_node_t *) root)->statements != NULL &&
          ((const pm_statements_node_t *) ((const pm_program_node_t *) root)->statements)->body.size == 1 &&
          ((const pm_statements_node_t *) ((const pm_program_node_t *) root)->statements)->body.nodes[0] == fleek_namespace_scope;
        if (!direct_pair || !PM_NODE_TYPE_P(outer->constant_path, PM_CONSTANT_READ_NODE) ||
            !PM_NODE_TYPE_P(inner->constant_path, PM_CONSTANT_READ_NODE) ||
            (outer->body != NULL && !PM_NODE_TYPE_P(outer->body, PM_STATEMENTS_NODE)) ||
            (inner->body != NULL && !PM_NODE_TYPE_P(inner->body, PM_STATEMENTS_NODE))) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        pm_constant_t *outer_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) outer->constant_path)->name);
        pm_constant_t *inner_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((const pm_constant_read_node_t *) inner->constant_path)->name);
        char qualified_name[512];
        int qualified_length = snprintf(qualified_name, sizeof(qualified_name), "%.*s::%.*s", (int) outer_name->length, outer_name->start,
          (int) inner_name->length, inner_name->start);
        if (qualified_length < 0 || (size_t) qualified_length >= sizeof(qualified_name)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        fleek_scope_count_state_t outer_state = { 0 }, inner_state = { 0 };
        if (outer->body != NULL) pm_visit_node(outer->body, fleek_class_count_visit, &outer_state);
        if (inner->body != NULL) pm_visit_node(inner->body, fleek_class_count_visit, &inner_state);
        size_t used = 0; int findings = 0; bool failed = false;
        if (outer_state.count > threshold) {
          int written = snprintf(fleek_too_many_constants_buffer + used, sizeof(fleek_too_many_constants_buffer) - used,
            "%zu\\t%.*s\\t%zu\\t\\n", fleek_source_line((const uint8_t *) source, outer->module_keyword_loc.start),
            (int) outer_name->length, outer_name->start, outer_state.count);
          if (written < 0 || (size_t) written >= sizeof(fleek_too_many_constants_buffer) - used) failed = true;
          else { used += (size_t) written; findings++; }
        }
        if (!failed && inner_state.count > threshold) {
          int written = snprintf(fleek_too_many_constants_buffer + used, sizeof(fleek_too_many_constants_buffer) - used,
            "%zu\\t%.*s\\t%zu\\t\\n", fleek_source_line((const uint8_t *) source, inner->module_keyword_loc.start),
            qualified_length, qualified_name, inner_state.count);
          if (written < 0 || (size_t) written >= sizeof(fleek_too_many_constants_buffer) - used) failed = true;
          else findings++;
        }
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
        return failed ? -4 : findings;
      }
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
      int result = fleek_scan_method_scope(source, length, fleek_uncommunicative_method_name_method, &patterns, NULL);
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
      pm_constant_t *name = NULL;
      const char *context = NULL;
      size_t context_length = 0;
      char qualified_name[512];
      if (PM_NODE_TYPE_P(path, PM_CONSTANT_READ_NODE)) {
        name = pm_constant_pool_id_to_constant(&state->parser->constant_pool, ((const pm_constant_read_node_t *) path)->name);
        context = (const char *) name->start;
        context_length = name->length;
      } else if (PM_NODE_TYPE_P(path, PM_CONSTANT_PATH_NODE)) {
        const pm_constant_path_node_t *qualified = (const pm_constant_path_node_t *) path;
        if (!PM_NODE_TYPE_P(qualified->parent, PM_CONSTANT_READ_NODE)) { state->unsupported = true; return true; }
        pm_constant_t *parent = pm_constant_pool_id_to_constant(&state->parser->constant_pool, ((const pm_constant_read_node_t *) qualified->parent)->name);
        name = pm_constant_pool_id_to_constant(&state->parser->constant_pool, qualified->name);
        int written = snprintf(qualified_name, sizeof(qualified_name), "%.*s::%.*s", (int) parent->length, parent->start,
          (int) name->length, name->start);
        if (written < 0 || (size_t) written >= sizeof(qualified_name)) { state->unsupported = true; return true; }
        context = qualified_name;
        context_length = (size_t) (written);
      } else { state->unsupported = true; return true; }
      if (fleek_matches_any_pattern((const uint8_t *) name->start, name->length, state->patterns->accept)) return true;
      if (!fleek_matches_any_pattern((const uint8_t *) name->start, name->length, state->patterns->reject)) return true;
      int written = snprintf(fleek_uncommunicative_module_name_buffer + fleek_uncommunicative_module_name_used, sizeof(fleek_uncommunicative_module_name_buffer) - fleek_uncommunicative_module_name_used, "%d\\t%.*s\\t%.*s\\n", fleek_source_line(state->source, keyword), (int) context_length, context, (int) name->length, name->start);
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
      int result = fleek_scan_method_scope(source, length, fleek_uncommunicative_parameter_name_method, &patterns, NULL);
      return result == -4 && fleek_uncommunicative_parameter_name_used > 0 ? -5 : result;
    }
    const char *fleek_uncommunicative_parameter_name_finding(void) { return fleek_uncommunicative_parameter_name_buffer; }
    typedef struct { pm_parser_t *parser; const uint8_t *source; const char *context; size_t used; fleek_name_patterns_t *patterns; bool unsupported; } fleek_variable_name_state_t;
    static bool fleek_uncommunicative_variable_name_node(const pm_node_t *node, void *data) {
      fleek_variable_name_state_t *state = (fleek_variable_name_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE) || PM_NODE_TYPE_P(node, PM_CLASS_NODE) || PM_NODE_TYPE_P(node, PM_MODULE_NODE)) return false;
      if (PM_NODE_TYPE_P(node, PM_BLOCK_PARAMETERS_NODE)) {
        const pm_block_parameters_node_t *block = (const pm_block_parameters_node_t *) node;
        const pm_parameters_node_t *parameters = block->parameters;
        if (parameters == NULL) { if (block->locals.size > 0) state->unsupported = true; return true; }
        if (parameters->optionals.size > 0 || parameters->posts.size > 0 || parameters->keywords.size > 0 ||
            parameters->rest != NULL || parameters->keyword_rest != NULL || parameters->block != NULL || block->locals.size > 0) {
          state->unsupported = true; return true;
        }
        for (size_t index = 0; index < parameters->requireds.size; index++) {
          pm_constant_id_t name_id = fleek_parameter_name(parameters->requireds.nodes[index]);
          if (name_id == 0) { state->unsupported = true; return true; }
          pm_constant_t *name = pm_constant_pool_id_to_constant(&state->parser->constant_pool, name_id);
          if (fleek_matches_any_pattern((const uint8_t *) name->start, name->length, state->patterns->accept) ||
              !fleek_matches_any_pattern((const uint8_t *) name->start, name->length, state->patterns->reject)) continue;
          int written = snprintf(fleek_uncommunicative_variable_name_buffer + fleek_uncommunicative_variable_name_used,
            sizeof(fleek_uncommunicative_variable_name_buffer) - fleek_uncommunicative_variable_name_used, "%d\\t%s\\t%.*s\\n",
            fleek_source_line(state->source, block->base.location.start), state->context, (int) name->length, name->start);
          if (written < 0 || (size_t) written >= sizeof(fleek_uncommunicative_variable_name_buffer) - fleek_uncommunicative_variable_name_used) {
            state->unsupported = true; return true;
          }
          fleek_uncommunicative_variable_name_used += (size_t) written;
          state->used++;
        }
        return true;
      }
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
      int result = fleek_scan_method_scope(source, length, fleek_uncommunicative_variable_name_method, &state, NULL);
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
    static int fleek_data_clump_singleton_findings(pm_parser_t *parser, const pm_constant_t *class_name,
        fleek_data_clump_state_t *state, size_t max_copies, size_t min_clump_size) {
      pm_constant_id_t clumps[128][64]; size_t clump_sizes[128] = { 0 }; size_t clump_total = 0;
      for (size_t method = 0; method < state->methods; method++) for (size_t parameter = 0; parameter < state->counts[method]; parameter++) {
        pm_constant_id_t name = state->names[method][parameter];
        bool seen = false;
        for (size_t earlier_method = 0; earlier_method < method; earlier_method++)
          if (fleek_data_clump_method_has(state, earlier_method, name)) seen = true;
        for (size_t earlier_parameter = 0; earlier_parameter < parameter; earlier_parameter++)
          if (state->names[method][earlier_parameter] == name) seen = true;
        if (seen) continue;
        size_t matching[128]; size_t matching_count = 0;
        for (size_t candidate = 0; candidate < state->methods; candidate++)
          if (fleek_data_clump_method_has(state, candidate, name)) matching[matching_count++] = candidate;
        if (matching_count <= max_copies) continue;
        pm_constant_id_t common_names[64]; size_t common_count = 0;
        for (size_t candidate_parameter = 0; candidate_parameter < state->counts[matching[0]]; candidate_parameter++) {
          pm_constant_id_t common = state->names[matching[0]][candidate_parameter];
          bool shared = true;
          for (size_t member = 1; member < matching_count; member++)
            if (!fleek_data_clump_method_has(state, matching[member], common)) shared = false;
          if (shared) common_names[common_count++] = common;
        }
        if (common_count < min_clump_size) continue;
        for (size_t left = 0; left < common_count; left++) for (size_t right = left + 1; right < common_count; right++) {
          pm_constant_t *left_name = pm_constant_pool_id_to_constant(&parser->constant_pool, common_names[left]);
          pm_constant_t *right_name = pm_constant_pool_id_to_constant(&parser->constant_pool, common_names[right]);
          size_t common_length = left_name->length < right_name->length ? left_name->length : right_name->length;
          int order = memcmp(left_name->start, right_name->start, common_length);
          if (order == 0) order = left_name->length < right_name->length ? -1 : left_name->length > right_name->length;
          if (order > 0) { pm_constant_id_t temporary = common_names[left]; common_names[left] = common_names[right]; common_names[right] = temporary; }
        }
        bool duplicate = false;
        for (size_t previous = 0; previous < clump_total; previous++) {
          if (clump_sizes[previous] != common_count) continue;
          bool same = true;
          for (size_t index = 0; index < common_count; index++) if (clumps[previous][index] != common_names[index]) same = false;
          if (same) duplicate = true;
        }
        if (duplicate) continue;
        if (clump_total == 128) return -1;
        for (size_t index = 0; index < common_count; index++) clumps[clump_total][index] = common_names[index];
        clump_sizes[clump_total++] = common_count;
      }
      size_t findings = 0;
      for (size_t clump_index = 0; clump_index < clump_total; clump_index++) {
        size_t matching[128]; size_t matching_count = 0;
        for (size_t candidate = 0; candidate < state->methods; candidate++) {
          bool shares_clump = true;
          for (size_t parameter = 0; parameter < clump_sizes[clump_index]; parameter++)
            if (!fleek_data_clump_method_has(state, candidate, clumps[clump_index][parameter])) shares_clump = false;
          if (shares_clump) matching[matching_count++] = candidate;
        }
        if (matching_count <= max_copies) continue;
        char clump[512] = { 0 }; size_t clump_used = 0;
        for (size_t name_index = 0; name_index < clump_sizes[clump_index]; name_index++) {
          pm_constant_t *param_name = pm_constant_pool_id_to_constant(&parser->constant_pool, clumps[clump_index][name_index]);
          int added = snprintf(clump + clump_used, sizeof(clump) - clump_used, "%s'%.*s'", name_index == 0 ? "" : ", ", (int) param_name->length, param_name->start);
          if (added < 0 || (size_t) added >= sizeof(clump) - clump_used) return -1;
          clump_used += (size_t) added;
        }
        char lines[512] = { 0 }; size_t lines_used = 0;
        for (size_t copy = 0; copy < matching_count; copy++) {
          size_t line = state->lines[matching[copy]];
          bool line_seen = false;
          for (size_t old = 0; old < copy; old++) if (state->lines[matching[old]] == line) line_seen = true;
          if (line_seen) continue;
          int line_written = snprintf(lines + lines_used, sizeof(lines) - lines_used, "%s%zu", lines_used == 0 ? "" : ", ", line);
          if (line_written < 0 || (size_t) line_written >= sizeof(lines) - lines_used) return -1;
          lines_used += (size_t) line_written;
        }
        int written = snprintf(fleek_data_clump_buffer + fleek_data_clump_used, sizeof(fleek_data_clump_buffer) - fleek_data_clump_used,
          "%s\\t%.*s\\t[%s]\\t%zu\\n", lines, (int) class_name->length, class_name->start, clump, matching_count);
        if (written < 0 || (size_t) written >= sizeof(fleek_data_clump_buffer) - fleek_data_clump_used) return -1;
        fleek_data_clump_used += (size_t) written; findings++;
      }
      return (int) findings;
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
      fleek_data_clump_state_t state = { max_copies, min_clump_size, { { 0 } }, { 0 }, { 0 }, 0, false, false };
      if (body != NULL) {
        const pm_statements_node_t *statements = (const pm_statements_node_t *) body;
        if (statements->body.size > 128) state.methods = 128;
        for (size_t index = 0; index < statements->body.size && state.methods < 128; index++) {
          const pm_node_t *child = statements->body.nodes[index];
          if (PM_NODE_TYPE_P(child, PM_DEF_NODE)) {
            if (!fleek_data_clump_method(child, (const uint8_t *) source, &state)) break;
          } else if (PM_NODE_TYPE_P(child, PM_SINGLETON_CLASS_NODE)) {
            const pm_singleton_class_node_t *singleton = (const pm_singleton_class_node_t *) child;
            if (!PM_NODE_TYPE_P(singleton->expression, PM_SELF_NODE) || !PM_NODE_TYPE_P(singleton->body, PM_STATEMENTS_NODE)) {
              state.unsupported = true;
              continue;
            }
            state.singleton_methods = true;
            const pm_statements_node_t *singleton_statements = (const pm_statements_node_t *) singleton->body;
            for (size_t method_index = 0; method_index < singleton_statements->body.size; method_index++) {
              if (state.methods >= 128) { state.unsupported = true; break; }
              const pm_node_t *method = singleton_statements->body.nodes[method_index];
              if (PM_NODE_TYPE_P(method, PM_DEF_NODE)) {
                if (!fleek_data_clump_method(method, (const uint8_t *) source, &state)) break;
              } else {
                fleek_nested_method_state_t nested = { false }; pm_visit_node(method, fleek_find_nested_method, &nested);
                if (nested.found) state.unsupported = true;
              }
            }
          } else {
            fleek_nested_method_state_t nested = { false }; pm_visit_node(child, fleek_find_nested_method, &nested);
            if (nested.found) state.unsupported = true;
          }
        }
      }
      if (state.methods == 128 && body != NULL && ((const pm_statements_node_t *) body)->body.size > 128) state.unsupported = true;
      if (state.singleton_methods) {
        int singleton_findings = fleek_data_clump_singleton_findings(&parser, class_name, &state, max_copies, min_clump_size);
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
        if (singleton_findings < 0) return -4;
        return state.unsupported ? (singleton_findings > 0 ? -5 : -4) : singleton_findings;
      }
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
      fleek_inner_namespace_scope = NULL;
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
      bool one_level_namespace = fleek_scope_contains(fleek_namespace_scope, fleek_only_scope) &&
        fleek_module_has_direct_child(fleek_namespace_scope, fleek_only_scope) &&
        ((fleek_class_count == 1 && fleek_module_count == 1) || (fleek_class_count == 0 && fleek_module_count == 2));
      bool nested_class_namespace = fleek_class_count == 1 && fleek_module_count == 2 &&
        fleek_scope_contains(fleek_namespace_scope, fleek_inner_namespace_scope) &&
        fleek_scope_contains(fleek_inner_namespace_scope, fleek_only_scope) &&
        fleek_module_has_direct_child(fleek_namespace_scope, fleek_inner_namespace_scope) &&
        fleek_module_has_direct_child(fleek_inner_namespace_scope, fleek_only_scope);
      bool namespaced_scope = one_level_namespace || nested_class_namespace;
      if ((!simple_class && !simple_module && !namespaced_scope) || fleek_unsupported) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      if (namespaced_scope) {
        const pm_node_t *namespace_body = PM_NODE_TYPE_P(fleek_namespace_scope, PM_MODULE_NODE) ? ((const pm_module_node_t *) fleek_namespace_scope)->body : NULL;
        bool namespace_has_occurrences = false;
        if (namespace_body != NULL) pm_visit_node(namespace_body, fleek_namespace_has_class_variables, &namespace_has_occurrences);
        if (nested_class_namespace) {
          const pm_node_t *inner_body = ((const pm_module_node_t *) fleek_inner_namespace_scope)->body;
          if (inner_body != NULL) pm_visit_node(inner_body, fleek_namespace_has_class_variables, &namespace_has_occurrences);
        }
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
        int written;
        if (nested_class_namespace) {
          const pm_node_t *inner_path = ((const pm_module_node_t *) fleek_inner_namespace_scope)->constant_path;
          if (!PM_NODE_TYPE_P(inner_path, PM_CONSTANT_READ_NODE)) {
            pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
          }
          pm_constant_t *inner_name = pm_constant_pool_id_to_constant(&parser.constant_pool, ((pm_constant_read_node_t *) inner_path)->name);
          written = snprintf(fleek_scope_name, sizeof(fleek_scope_name), "%.*s::%.*s::%.*s", (int) namespace_name->length, namespace_name->start, (int) inner_name->length, inner_name->start, (int) class_name->length, class_name->start);
        } else {
          written = snprintf(fleek_scope_name, sizeof(fleek_scope_name), "%.*s::%.*s", (int) namespace_name->length, namespace_name->start, (int) class_name->length, class_name->start);
        }
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
        int suppression = fleek_comment_suppression(comment, "ClassVariable");
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

    static bool fleek_duplication_reserve_buffer(size_t required) {
      if (required <= fleek_duplication_buffer_capacity) return true;
      size_t next = fleek_duplication_buffer_capacity == 0 ? 256 : fleek_duplication_buffer_capacity;
      while (next < required) {
        if (next > SIZE_MAX / 2) return false;
        next *= 2;
      }
      char *resized = realloc(fleek_duplication_buffer, next);
      if (resized == NULL) return false;
      fleek_duplication_buffer = resized;
      fleek_duplication_buffer_capacity = next;
      return true;
    }
    static bool fleek_duplication_append_text(const char *text, size_t length) {
      if (length == SIZE_MAX || fleek_duplication_buffer_used > SIZE_MAX - length - 1) return false;
      size_t required = fleek_duplication_buffer_used + length + 1;
      if (!fleek_duplication_reserve_buffer(required)) return false;
      memcpy(fleek_duplication_buffer + fleek_duplication_buffer_used, text, length);
      fleek_duplication_buffer_used += length;
      fleek_duplication_buffer[fleek_duplication_buffer_used] = 0;
      return true;
    }
    typedef enum { FLEEK_DUPLICATION_GROUP_METHOD, FLEEK_DUPLICATION_GROUP_ITER } fleek_duplication_group_weight_t;
    static bool fleek_duplication_append_group(const char *node, bool identical, size_t node_mass, const int *lines, size_t count,
        fleek_duplication_group_weight_t weight, const int *fuzzy_lines) {
      size_t group_mass;
      size_t multiplier;
      if (weight == FLEEK_DUPLICATION_GROUP_ITER) {
        if (node_mass != 0 && count > SIZE_MAX / node_mass) return false;
        group_mass = node_mass * count;
        multiplier = identical ? count : 1;
      } else {
        if (node_mass != 0 && count > SIZE_MAX / node_mass) return false;
        group_mass = node_mass * count;
        multiplier = identical ? count : 1;
      }
      if (group_mass != 0 && multiplier > SIZE_MAX / group_mass) return false;
      size_t group_score = group_mass * multiplier;
      if (group_score > (size_t) (INT_MAX - fleek_duplication_total_score)) return false;
      char fragment[128];
      int written = snprintf(fragment, sizeof(fragment), "%s%s\\t%s\\t%zu\\t%zu",
        fleek_duplication_buffer_used == 0 ? "" : "\\n", node, identical ? "identical" : "similar", group_mass, group_score);
      if (written < 0 || (size_t) written >= sizeof(fragment) ||
          !fleek_duplication_append_text(fragment, (size_t) written)) return false;
      for (size_t index = 0; index < count; index++) {
        written = snprintf(fragment, sizeof(fragment), "%s%d", index == 0 ? "\\t" : ",", lines[index]);
        if (written < 0 || (size_t) written >= sizeof(fragment) ||
            !fleek_duplication_append_text(fragment, (size_t) written)) return false;
      }
      if (fuzzy_lines != NULL) {
        if (!fleek_duplication_append_text("\\t", 1)) return false;
        bool first_fuzzy = true;
        for (size_t index = 0; index < count; index++) {
          if (fuzzy_lines[index] == 0) continue;
          written = snprintf(fragment, sizeof(fragment), "%s%d", first_fuzzy ? "" : ",", fuzzy_lines[index]);
          if (written < 0 || (size_t) written >= sizeof(fragment) ||
              !fleek_duplication_append_text(fragment, (size_t) written)) return false;
          first_fuzzy = false;
        }
      }
      fleek_duplication_total_score += (int) group_score;
      return true;
    }
    static bool fleek_constants_equal(pm_parser_t *parser, pm_constant_id_t left, pm_constant_id_t right) {
      pm_constant_t *left_constant = pm_constant_pool_id_to_constant(&parser->constant_pool, left);
      pm_constant_t *right_constant = pm_constant_pool_id_to_constant(&parser->constant_pool, right);
      return left_constant->length == right_constant->length && memcmp(left_constant->start, right_constant->start, left_constant->length) == 0;
    }

    typedef struct { bool unsupported; } fleek_legacy_parser_state_t;
    static bool fleek_legacy_parser_syntax_supported(const pm_node_t *node, void *data) {
      const pm_node_t *left = NULL;
      const uint8_t *operator_start = NULL;
      const uint8_t *operator_end = NULL;
      if (PM_NODE_TYPE_P(node, PM_AND_NODE)) {
        const pm_and_node_t *logical = (const pm_and_node_t *) node;
        left = logical->left;
        operator_start = logical->operator_loc.start;
        operator_end = logical->operator_loc.end;
      } else if (PM_NODE_TYPE_P(node, PM_OR_NODE)) {
        const pm_or_node_t *logical = (const pm_or_node_t *) node;
        left = logical->left;
        operator_start = logical->operator_loc.start;
        operator_end = logical->operator_loc.end;
      } else {
        return true;
      }
      size_t operator_length = (size_t) (operator_end - operator_start);
      size_t between_length = (size_t) (operator_start - left->location.end);
      bool legacy_operator = (operator_length == 2 &&
        (memcmp(operator_start, "&&", 2) == 0 || memcmp(operator_start, "||", 2) == 0 ||
        memcmp(operator_start, "or", 2) == 0)) ||
        (operator_length == 3 && memcmp(operator_start, "and", 3) == 0);
      if (legacy_operator && memchr(left->location.end, '\\n', between_length) != NULL) {
        ((fleek_legacy_parser_state_t *) data)->unsupported = true;
        return false;
      }
      return true;
    }


    /* Generic Flay engine (ADR 0256): a port of Prism 1.9.0's Translation::RubyParser
       (Flay 2.14.4's default parser) followed by Flay's grouping, pruning and scoring. */
    #define FLEEK_FLAY_UNTRANSLATED (-100)
    #define FLEEK_FLAY_NIL (-2)
    #define FLEEK_FLAY_FAIL (-1)
    #define FLEEK_FLAY_ATOM(id) (-3 - (int64_t) (id))
    #define FLEEK_FLAY_IS_ATOM(value) ((value) <= -3)
    #define FLEEK_FLAY_ATOM_ID(value) ((uint32_t) (-3 - (value)))

    typedef struct { uint32_t atom; uint32_t ref; } fleek_flay_item_t;
    typedef struct {
      uint32_t type; int32_t line, line_max; fleek_flay_item_t *items; uint32_t count, capacity;
      uint32_t shape, value, mass; bool has_sexp, modified;
    } fleek_flay_sexp_t;
    typedef struct { uint32_t *pool; size_t pool_used, pool_capacity; uint32_t *slots; size_t slot_capacity, count; uint32_t *offsets; size_t offsets_capacity; } fleek_flay_intern_t;
    typedef struct {
      pm_parser_t *parser; bool failed; bool in_def; bool in_pattern; int32_t file_start_line; const char *file_path; size_t file_path_length;
      fleek_flay_sexp_t *nodes; size_t count, capacity;
    } fleek_flay_ctx_t;

    static fleek_flay_intern_t fleek_flay_atoms, fleek_flay_shapes, fleek_flay_values;
    static const char *fleek_flay_type_names[128];
    static size_t fleek_flay_type_count;

    static uint64_t fleek_flay_hash_words(const uint32_t *words, size_t length) {
      uint64_t hash = 1469598103934665603ULL;
      for (size_t index = 0; index < length; index++) { hash ^= words[index]; hash *= 1099511628211ULL; }
      return hash ^ (uint64_t) length;
    }
    static void fleek_flay_intern_free(fleek_flay_intern_t *table) {
      free(table->pool); free(table->slots); free(table->offsets);
      memset(table, 0, sizeof(*table));
    }
    static bool fleek_flay_intern_grow(fleek_flay_intern_t *table) {
      size_t capacity = table->slot_capacity == 0 ? 1024 : table->slot_capacity * 2;
      uint32_t *slots = calloc(capacity, sizeof(uint32_t));
      if (slots == NULL) return false;
      for (size_t id = 0; id < table->count; id++) {
        size_t offset = table->offsets[id];
        size_t slot = (size_t) fleek_flay_hash_words(&table->pool[offset + 1], table->pool[offset]) & (capacity - 1);
        while (slots[slot] != 0) slot = (slot + 1) & (capacity - 1);
        slots[slot] = (uint32_t) id + 1;
      }
      free(table->slots);
      table->slots = slots; table->slot_capacity = capacity;
      return true;
    }
    /* Interns a word sequence; returns its dense id, or UINT32_MAX on allocation failure. */
    static uint32_t fleek_flay_intern(fleek_flay_intern_t *table, const uint32_t *words, size_t length) {
      if ((table->count + 1) * 2 > table->slot_capacity && !fleek_flay_intern_grow(table)) return UINT32_MAX;
      size_t mask = table->slot_capacity - 1;
      size_t slot = (size_t) fleek_flay_hash_words(words, length) & mask;
      while (table->slots[slot] != 0) {
        uint32_t id = table->slots[slot] - 1;
        size_t offset = table->offsets[id];
        if (table->pool[offset] == length && memcmp(&table->pool[offset + 1], words, length * sizeof(uint32_t)) == 0) return id;
        slot = (slot + 1) & mask;
      }
      if (table->pool_used + length + 1 > table->pool_capacity) {
        size_t capacity = table->pool_capacity == 0 ? 4096 : table->pool_capacity;
        while (table->pool_used + length + 1 > capacity) capacity *= 2;
        uint32_t *pool = realloc(table->pool, capacity * sizeof(uint32_t));
        if (pool == NULL) return UINT32_MAX;
        table->pool = pool; table->pool_capacity = capacity;
      }
      if (table->count + 1 > table->offsets_capacity) {
        size_t capacity = table->offsets_capacity == 0 ? 1024 : table->offsets_capacity * 2;
        uint32_t *offsets = realloc(table->offsets, capacity * sizeof(uint32_t));
        if (offsets == NULL) return UINT32_MAX;
        table->offsets = offsets; table->offsets_capacity = capacity;
      }
      uint32_t id = (uint32_t) table->count++;
      table->offsets[id] = (uint32_t) table->pool_used;
      table->pool[table->pool_used++] = (uint32_t) length;
      if (length != 0) memcpy(&table->pool[table->pool_used], words, length * sizeof(uint32_t));
      table->pool_used += length;
      table->slots[slot] = id + 1;
      return id;
    }

    /* Atoms are tagged byte strings. Tags: s symbol, t string, i integer (also integral floats and
       unit rationals, matching Ruby ==), f float, q rational, c imaginary, r regexp, R range, n nil, T true, F false. */
    static uint32_t fleek_flay_atom_id(char tag, const uint8_t *bytes, size_t length) {
      size_t words = (length + 1 + 3) / 4 + 1;
      uint32_t stack[64];
      uint32_t *packed = words <= 64 ? stack : calloc(words, sizeof(uint32_t));
      if (packed == NULL) return UINT32_MAX;
      memset(packed, 0, words * sizeof(uint32_t));
      packed[0] = (uint32_t) length;
      uint8_t *target = (uint8_t *) &packed[1];
      target[0] = (uint8_t) tag;
      if (length != 0) memcpy(target + 1, bytes, length);
      uint32_t id = fleek_flay_intern(&fleek_flay_atoms, packed, words);
      if (packed != stack) free(packed);
      return id;
    }
    static char fleek_flay_atom_tag(uint32_t id) {
      return (char) ((const uint8_t *) &fleek_flay_atoms.pool[fleek_flay_atoms.offsets[id] + 2])[0];
    }
    static const uint8_t *fleek_flay_atom_bytes(uint32_t id, size_t *length) {
      size_t offset = fleek_flay_atoms.offsets[id];
      *length = fleek_flay_atoms.pool[offset + 1];
      return ((const uint8_t *) &fleek_flay_atoms.pool[offset + 2]) + 1;
    }
    static int64_t fleek_flay_atom(fleek_flay_ctx_t *ctx, char tag, const uint8_t *bytes, size_t length) {
      uint32_t id = fleek_flay_atom_id(tag, bytes, length);
      if (id == UINT32_MAX) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
      return FLEEK_FLAY_ATOM(id);
    }
    static int64_t fleek_flay_text_atom(fleek_flay_ctx_t *ctx, char tag, const char *text) {
      return fleek_flay_atom(ctx, tag, (const uint8_t *) text, strlen(text));
    }
    static int64_t fleek_flay_name(fleek_flay_ctx_t *ctx, const char *prefix, pm_constant_id_t name) {
      uint8_t buffer[512];
      size_t length = strlen(prefix);
      memcpy(buffer, prefix, length);
      if (name != 0) {
        pm_constant_t *constant = pm_constant_pool_id_to_constant(&ctx->parser->constant_pool, name);
        if (constant->length > sizeof(buffer) - length) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
        memcpy(buffer + length, constant->start, constant->length);
        length += constant->length;
      }
      return fleek_flay_atom(ctx, 's', buffer, length);
    }
    static int64_t fleek_flay_symbol(fleek_flay_ctx_t *ctx, pm_constant_id_t name) { return fleek_flay_name(ctx, "", name); }
    static int64_t fleek_flay_integer(fleek_flay_ctx_t *ctx, const pm_integer_t *integer) {
      pm_buffer_t buffer = {0};
      pm_buffer_init(&buffer);
      pm_integer_string(&buffer, integer);
      int64_t atom = fleek_flay_atom(ctx, 'i', (const uint8_t *) pm_buffer_value(&buffer), pm_buffer_length(&buffer));
      pm_buffer_free(&buffer);
      return atom;
    }
    static int64_t fleek_flay_number(fleek_flay_ctx_t *ctx, long long value) {
      char text[32];
      snprintf(text, sizeof(text), "%lld", value);
      return fleek_flay_text_atom(ctx, 'i', text);
    }
    static int64_t fleek_flay_float(fleek_flay_ctx_t *ctx, double value) {
      char text[64];
      if (value == value && value > -9007199254740992.0 && value < 9007199254740992.0 && value == (double) (long long) value)
        snprintf(text, sizeof(text), "%lld", (long long) value);
      else
        snprintf(text, sizeof(text), "f%.17g", value);
      return fleek_flay_text_atom(ctx, text[0] == 'f' ? 'f' : 'i', text[0] == 'f' ? text + 1 : text);
    }

    static uint32_t fleek_flay_type(const char *name) {
      for (size_t index = 0; index < fleek_flay_type_count; index++) if (strcmp(fleek_flay_type_names[index], name) == 0) return (uint32_t) index;
      if (fleek_flay_type_count == 128) return UINT32_MAX;
      fleek_flay_type_names[fleek_flay_type_count] = name;
      return (uint32_t) fleek_flay_type_count++;
    }
    static int32_t fleek_flay_line(fleek_flay_ctx_t *ctx, const uint8_t *cursor) {
      return pm_newline_list_line(&ctx->parser->newline_list, cursor, ctx->parser->start_line);
    }
    static int64_t fleek_flay_sexp_at(fleek_flay_ctx_t *ctx, const char *type, int32_t line, int32_t line_max) {
      if (ctx->failed) return FLEEK_FLAY_FAIL;
      if (ctx->count == ctx->capacity) {
        size_t capacity = ctx->capacity == 0 ? 1024 : ctx->capacity * 2;
        fleek_flay_sexp_t *nodes = realloc(ctx->nodes, capacity * sizeof(fleek_flay_sexp_t));
        if (nodes == NULL) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
        ctx->nodes = nodes; ctx->capacity = capacity;
      }
      uint32_t type_id = fleek_flay_type(type);
      if (type_id == UINT32_MAX) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
      fleek_flay_sexp_t *node = &ctx->nodes[ctx->count];
      memset(node, 0, sizeof(*node));
      node->type = type_id;
      node->line = line;
      node->line_max = line_max;
      return (int64_t) ctx->count++;
    }
    /* s(node, type): line and line_max come from the Prism node's location. */
    static int64_t fleek_flay_s(fleek_flay_ctx_t *ctx, const pm_node_t *at, const char *type) {
      if (at == NULL) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
      return fleek_flay_sexp_at(ctx, type, fleek_flay_line(ctx, at->location.start),
        fleek_flay_line(ctx, at->location.end));
    }
    static bool fleek_flay_is(fleek_flay_ctx_t *ctx, int64_t value, const char *type) {
      return value >= 0 && strcmp(fleek_flay_type_names[ctx->nodes[value].type], type) == 0;
    }
    /* Appends a visited value: a sexp, an atom, or nil. */
    static int64_t fleek_flay_add(fleek_flay_ctx_t *ctx, int64_t parent, int64_t child) {
      if (ctx->failed || parent < 0 || child == FLEEK_FLAY_FAIL) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
      fleek_flay_item_t item;
      if (child == FLEEK_FLAY_NIL) {
        uint32_t id = fleek_flay_atom_id('n', NULL, 0);
        if (id == UINT32_MAX) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
        item.atom = 1; item.ref = id;
      } else if (FLEEK_FLAY_IS_ATOM(child)) {
        item.atom = 1; item.ref = FLEEK_FLAY_ATOM_ID(child);
      } else {
        item.atom = 0; item.ref = (uint32_t) child;
      }
      fleek_flay_sexp_t *node = &ctx->nodes[parent];
      if (node->count == node->capacity) {
        uint32_t capacity = node->capacity == 0 ? 4 : node->capacity * 2;
        fleek_flay_item_t *items = realloc(node->items, capacity * sizeof(fleek_flay_item_t));
        if (items == NULL) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
        node->items = items; node->capacity = capacity;
      }
      node->items[node->count++] = item;
      return parent;
    }

    static int64_t fleek_flay_visit(fleek_flay_ctx_t *ctx, const pm_node_t *node);
    static int64_t fleek_flay_visit_mode(fleek_flay_ctx_t *ctx, const pm_node_t *node, int in_def, int in_pattern) {
      bool saved_def = ctx->in_def, saved_pattern = ctx->in_pattern;
      if (in_def >= 0) ctx->in_def = in_def != 0;
      if (in_pattern >= 0) ctx->in_pattern = in_pattern != 0;
      int64_t result = fleek_flay_visit(ctx, node);
      ctx->in_def = saved_def; ctx->in_pattern = saved_pattern;
      return result;
    }
    static int64_t fleek_flay_add_visit(fleek_flay_ctx_t *ctx, int64_t parent, const pm_node_t *node) {
      return fleek_flay_add(ctx, parent, fleek_flay_visit(ctx, node));
    }
    static int64_t fleek_flay_add_all(fleek_flay_ctx_t *ctx, int64_t parent, const pm_node_list_t *list) {
      for (size_t index = 0; index < list->size; index++) fleek_flay_add_visit(ctx, parent, list->nodes[index]);
      return parent;
    }
    static const pm_node_list_t *fleek_flay_arguments(const pm_arguments_node_t *arguments) {
      static const pm_node_list_t empty = { 0, 0, NULL };
      return arguments == NULL ? &empty : &arguments->arguments;
    }
    /* Prism::Translation::RubyParser#visit_write_value */
    static int64_t fleek_flay_write_value(fleek_flay_ctx_t *ctx, const pm_node_t *node) {
      if (node != NULL && PM_NODE_TYPE_P(node, PM_ARRAY_NODE) && ((const pm_array_node_t *) node)->opening_loc.start == NULL) {
        const pm_array_node_t *array = (const pm_array_node_t *) node;
        int64_t svalue = fleek_flay_s(ctx, node, "svalue");
        if (array->elements.size == 1 && PM_NODE_TYPE_P(array->elements.nodes[0], PM_SPLAT_NODE))
          return fleek_flay_add_visit(ctx, svalue, array->elements.nodes[0]);
        return fleek_flay_add_visit(ctx, svalue, node);
      }
      return fleek_flay_visit(ctx, node);
    }
    /* Prism::Translation::RubyParser#visit_block */
    static int64_t fleek_flay_block(fleek_flay_ctx_t *ctx, const pm_node_t *at, int64_t sexp, const pm_node_t *block_node) {
      if (block_node == NULL) return sexp;
      const pm_block_node_t *block = (const pm_block_node_t *) block_node;
      int64_t iter = fleek_flay_add(ctx, fleek_flay_s(ctx, at, "iter"), sexp);
      const pm_node_t *parameters = block->parameters;
      if (parameters == NULL || PM_NODE_TYPE_P(parameters, PM_IT_PARAMETERS_NODE) || PM_NODE_TYPE_P(parameters, PM_NUMBERED_PARAMETERS_NODE))
        fleek_flay_add(ctx, iter, fleek_flay_number(ctx, 0));
      else
        fleek_flay_add_visit(ctx, iter, parameters);
      if (block->body != NULL) fleek_flay_add_visit(ctx, iter, block->body);
      return iter;
    }
    /* a && b && c: Prism nests left, ruby_parser nests right; the new inner node takes the outer location. */
    static int64_t fleek_flay_logical(fleek_flay_ctx_t *ctx, const pm_node_t *node, const char *type, const pm_node_t *left, const pm_node_t *right) {
      int64_t visited = fleek_flay_visit(ctx, left);
      if (!fleek_flay_is(ctx, visited, type)) {
        int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, type), visited);
        return fleek_flay_add_visit(ctx, result, right);
      }
      int64_t nest = visited;
      while (ctx->nodes[nest].count >= 2 && !ctx->nodes[nest].items[1].atom && fleek_flay_is(ctx, ctx->nodes[nest].items[1].ref, type))
        nest = ctx->nodes[nest].items[1].ref;
      if (ctx->nodes[nest].count < 2) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
      fleek_flay_item_t old = ctx->nodes[nest].items[1];
      int64_t inner = fleek_flay_s(ctx, node, type);
      if (inner < 0) return FLEEK_FLAY_FAIL;
      ctx->nodes[inner].items = malloc(4 * sizeof(fleek_flay_item_t));
      if (ctx->nodes[inner].items == NULL) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
      ctx->nodes[inner].capacity = 4;
      ctx->nodes[inner].items[0] = old;
      ctx->nodes[inner].count = 1;
      fleek_flay_add_visit(ctx, inner, right);
      if (ctx->failed) return FLEEK_FLAY_FAIL;
      ctx->nodes[nest].items[1].atom = 0;
      ctx->nodes[nest].items[1].ref = (uint32_t) inner;
      return visited;
    }
    static int64_t fleek_flay_statements(fleek_flay_ctx_t *ctx, const pm_node_t *at, const pm_node_list_t *body) {
      if (body->size == 0) return FLEEK_FLAY_NIL;
      if (body->size == 1) return fleek_flay_visit(ctx, body->nodes[0]);
      return fleek_flay_add_all(ctx, fleek_flay_s(ctx, at, "block"), body);
    }
    /* Class, module and def bodies concatenate their statements; other bodies become one child. */
    static int64_t fleek_flay_scope_body(fleek_flay_ctx_t *ctx, int64_t result, const pm_node_t *body, bool in_def) {
      if (body == NULL) return result;
      if (PM_NODE_TYPE_P(body, PM_STATEMENTS_NODE)) {
        const pm_node_list_t *list = &((const pm_statements_node_t *) body)->body;
        for (size_t index = 0; index < list->size; index++) fleek_flay_add(ctx, result, fleek_flay_visit_mode(ctx, list->nodes[index], in_def, -1));
        return result;
      }
      return fleek_flay_add(ctx, result, fleek_flay_visit_mode(ctx, body, in_def, -1));
    }
    static int64_t fleek_flay_scope_name(fleek_flay_ctx_t *ctx, int64_t result, const pm_node_t *path, pm_constant_id_t name) {
      if (PM_NODE_TYPE_P(path, PM_CONSTANT_READ_NODE)) return fleek_flay_add(ctx, result, fleek_flay_symbol(ctx, name));
      return fleek_flay_add_visit(ctx, result, path);
    }
    static int64_t fleek_flay_jump(fleek_flay_ctx_t *ctx, const pm_node_t *node, const char *type, const pm_arguments_node_t *arguments, bool splat_svalue) {
      int64_t result = fleek_flay_s(ctx, node, type);
      if (arguments == NULL) return result;
      const pm_node_list_t *list = &arguments->arguments;
      if (list->size == 1) {
        if (splat_svalue && PM_NODE_TYPE_P(list->nodes[0], PM_SPLAT_NODE))
          return fleek_flay_add(ctx, result, fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "svalue"), list->nodes[0]));
        return fleek_flay_add_visit(ctx, result, list->nodes[0]);
      }
      const pm_node_t *array_at = splat_svalue ? node : (const pm_node_t *) arguments;
      return fleek_flay_add(ctx, result, fleek_flay_add_all(ctx, fleek_flay_s(ctx, array_at, "array"), list));
    }
    /* Variable writes: value, operator, &&= and ||= forms. kind: 0 plain, 1 operator, 2 and, 3 or. */
    static int64_t fleek_flay_variable(fleek_flay_ctx_t *ctx, const pm_node_t *node, const char *read, const char *write,
        pm_constant_id_t name, pm_constant_id_t operator, int kind, const pm_node_t *value, bool write_value) {
      if (kind == 1) {
        int64_t call = fleek_flay_s(ctx, node, "call");
        fleek_flay_add(ctx, call, fleek_flay_add(ctx, fleek_flay_s(ctx, node, read), fleek_flay_symbol(ctx, name)));
        fleek_flay_add(ctx, call, fleek_flay_symbol(ctx, operator));
        fleek_flay_add(ctx, call, write_value ? fleek_flay_write_value(ctx, value) : fleek_flay_visit(ctx, value));
        int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, write), fleek_flay_symbol(ctx, name));
        return fleek_flay_add(ctx, result, call);
      }
      int64_t assignment = fleek_flay_add(ctx, fleek_flay_s(ctx, node, write), fleek_flay_symbol(ctx, name));
      fleek_flay_add(ctx, assignment, write_value ? fleek_flay_write_value(ctx, value) : fleek_flay_visit(ctx, value));
      if (kind == 0) return assignment;
      int64_t result = fleek_flay_s(ctx, node, kind == 2 ? "op_asgn_and" : "op_asgn_or");
      fleek_flay_add(ctx, result, fleek_flay_add(ctx, fleek_flay_s(ctx, node, read), fleek_flay_symbol(ctx, name)));
      return fleek_flay_add(ctx, result, assignment);
    }
    #define FLEEK_FLAY_VARIABLE_FAMILY(PREFIX, STRUCT, READ, WRITE, OPERATOR_VALUE, LOGICAL_VALUE) \\
      case PM_##PREFIX##_WRITE_NODE: { const pm_##STRUCT##_write_node_t *write = (const void *) node; \\
        return fleek_flay_variable(ctx, node, READ, WRITE, write->name, 0, 0, write->value, true); } \\
      case PM_##PREFIX##_OPERATOR_WRITE_NODE: { const pm_##STRUCT##_operator_write_node_t *write = (const void *) node; \\
        return fleek_flay_variable(ctx, node, READ, WRITE, write->name, write->binary_operator, 1, write->value, OPERATOR_VALUE); } \\
      case PM_##PREFIX##_AND_WRITE_NODE: { const pm_##STRUCT##_and_write_node_t *write = (const void *) node; \\
        return fleek_flay_variable(ctx, node, READ, WRITE, write->name, 0, 2, write->value, LOGICAL_VALUE); } \\
      case PM_##PREFIX##_OR_WRITE_NODE: { const pm_##STRUCT##_or_write_node_t *write = (const void *) node; \\
        return fleek_flay_variable(ctx, node, READ, WRITE, write->name, 0, 3, write->value, LOGICAL_VALUE); } \\
      case PM_##PREFIX##_TARGET_NODE: \\
        return fleek_flay_add(ctx, fleek_flay_s(ctx, node, WRITE), fleek_flay_symbol(ctx, ((const pm_##STRUCT##_target_node_t *) node)->name));

    /* visit_interpolated_parts: entries are str/evstr sexps, string atoms, or the :space marker. */
    #define FLEEK_FLAY_SPACE INT64_MIN
    typedef struct { int64_t *values; size_t count, capacity; } fleek_flay_values_t;
    static void fleek_flay_values_push(fleek_flay_ctx_t *ctx, fleek_flay_values_t *list, int64_t value) {
      if (list->count == list->capacity) {
        size_t capacity = list->capacity == 0 ? 16 : list->capacity * 2;
        int64_t *values = realloc(list->values, capacity * sizeof(int64_t));
        if (values == NULL) { ctx->failed = true; return; }
        list->values = values; list->capacity = capacity;
      }
      list->values[list->count++] = value;
    }
    static void fleek_flay_values_items(fleek_flay_ctx_t *ctx, fleek_flay_values_t *list, int64_t node, uint32_t from) {
      for (uint32_t index = from; index < ctx->nodes[node].count; index++) {
        fleek_flay_item_t item = ctx->nodes[node].items[index];
        fleek_flay_values_push(ctx, list, item.atom ? FLEEK_FLAY_ATOM(item.ref) : (int64_t) item.ref);
      }
    }
    static bool fleek_flay_string_value(fleek_flay_ctx_t *ctx, int64_t value, const uint8_t **bytes, size_t *length) {
      if (FLEEK_FLAY_IS_ATOM(value)) { *bytes = fleek_flay_atom_bytes(FLEEK_FLAY_ATOM_ID(value), length); return true; }
      if (fleek_flay_is(ctx, value, "str") && ctx->nodes[value].count == 1 && ctx->nodes[value].items[0].atom) {
        *bytes = fleek_flay_atom_bytes(ctx->nodes[value].items[0].ref, length);
        return true;
      }
      return false;
    }
    static int64_t fleek_flay_concat_atom(fleek_flay_ctx_t *ctx, const uint8_t *left, size_t left_length, const uint8_t *right, size_t right_length) {
      uint8_t *joined = malloc(left_length + right_length + 1);
      if (joined == NULL) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
      if (left_length) memcpy(joined, left, left_length);
      if (right_length) memcpy(joined + left_length, right, right_length);
      int64_t atom = fleek_flay_atom(ctx, 't', joined, left_length + right_length);
      free(joined);
      return atom;
    }
    static void fleek_flay_interpolated_parts(fleek_flay_ctx_t *ctx, const pm_node_list_t *parts, fleek_flay_values_t *results) {
      fleek_flay_values_t visited = {0};
      for (size_t index = 0; index < parts->size && !ctx->failed; index++) {
        const pm_node_t *part = parts->nodes[index];
        int64_t result = fleek_flay_visit(ctx, part);
        if (fleek_flay_is(ctx, result, "evstr") && ctx->nodes[result].count >= 1 && !ctx->nodes[result].items[0].atom) {
          int64_t inner = ctx->nodes[result].items[0].ref;
          if (fleek_flay_is(ctx, inner, "str")) fleek_flay_values_push(ctx, &visited, inner);
          else if (fleek_flay_is(ctx, inner, "dstr")) fleek_flay_values_items(ctx, &visited, inner, 0);
          else fleek_flay_values_push(ctx, &visited, result);
          fleek_flay_values_push(ctx, &visited, FLEEK_FLAY_SPACE);
        } else if (fleek_flay_is(ctx, result, "dstr")) {
          const pm_node_list_t *inner_parts = &((const pm_interpolated_string_node_t *) part)->parts;
          if (visited.count != 0 && inner_parts->size != 0 && PM_NODE_TYPE_P(inner_parts->nodes[0], PM_STRING_NODE)) {
            int64_t first = fleek_flay_visit(ctx, inner_parts->nodes[0]);
            if (first < 0 || ctx->nodes[result].count == 0) { ctx->failed = true; break; }
            ctx->nodes[result].items[0].atom = 0;
            ctx->nodes[result].items[0].ref = (uint32_t) first;
          }
          fleek_flay_values_items(ctx, &visited, result, 0);
        } else if (result == FLEEK_FLAY_FAIL) {
          ctx->failed = true;
        } else {
          fleek_flay_values_push(ctx, &visited, result);
        }
      }
      int state = 0; /* 0 beginning, 1 string content, 2 interpolated content */
      for (size_t index = 0; index < visited.count && !ctx->failed; index++) {
        int64_t result = visited.values[index];
        const uint8_t *bytes; size_t length;
        if (state == 0) {
          if (result != FLEEK_FLAY_SPACE && fleek_flay_string_value(ctx, result, &bytes, &length)) {
            fleek_flay_values_push(ctx, results, fleek_flay_atom(ctx, 't', bytes, length));
            state = 1;
          } else {
            fleek_flay_values_push(ctx, results, fleek_flay_atom(ctx, 't', NULL, 0));
            fleek_flay_values_push(ctx, results, result);
            state = 2;
          }
        } else if (state == 1) {
          if (result == FLEEK_FLAY_SPACE) continue;
          if (fleek_flay_string_value(ctx, result, &bytes, &length)) {
            const uint8_t *first; size_t first_length;
            fleek_flay_string_value(ctx, results->values[0], &first, &first_length);
            results->values[0] = fleek_flay_concat_atom(ctx, first, first_length, bytes, length);
          } else {
            fleek_flay_values_push(ctx, results, result);
            state = 2;
          }
        } else {
          if (result == FLEEK_FLAY_SPACE) continue;
          int64_t last = results->values[results->count - 1];
          if (visited.values[index - 1] != FLEEK_FLAY_SPACE && fleek_flay_is(ctx, result, "str") && fleek_flay_is(ctx, last, "str") &&
              ctx->nodes[last].line_max == ctx->nodes[result].line) {
            const uint8_t *left, *right; size_t left_length, right_length;
            fleek_flay_string_value(ctx, last, &left, &left_length);
            fleek_flay_string_value(ctx, result, &right, &right_length);
            int64_t joined = fleek_flay_concat_atom(ctx, left, left_length, right, right_length);
            if (joined == FLEEK_FLAY_FAIL) break;
            ctx->nodes[last].items[0].ref = FLEEK_FLAY_ATOM_ID(joined);
            ctx->nodes[last].line_max = ctx->nodes[result].line_max;
          } else {
            fleek_flay_values_push(ctx, results, result);
          }
        }
      }
      free(visited.values);
    }
    static int regexp_options(const pm_node_t *node) {
      int options = 0;
      if (PM_NODE_FLAG_P(node, PM_REGULAR_EXPRESSION_FLAGS_IGNORE_CASE)) options |= 1;
      if (PM_NODE_FLAG_P(node, PM_REGULAR_EXPRESSION_FLAGS_EXTENDED)) options |= 2;
      if (PM_NODE_FLAG_P(node, PM_REGULAR_EXPRESSION_FLAGS_MULTI_LINE)) options |= 4;
      if (PM_NODE_FLAG_P(node, PM_REGULAR_EXPRESSION_FLAGS_EUC_JP | PM_REGULAR_EXPRESSION_FLAGS_WINDOWS_31J | PM_REGULAR_EXPRESSION_FLAGS_UTF_8)) options |= 16;
      if (PM_NODE_FLAG_P(node, PM_REGULAR_EXPRESSION_FLAGS_ASCII_8BIT)) options |= 32;
      return options;
    }
    static int64_t fleek_flay_regexp_atom(fleek_flay_ctx_t *ctx, const uint8_t *source, size_t length, int options) {
      uint8_t *text = malloc(length + 16);
      if (text == NULL) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
      int prefix = snprintf((char *) text, 16, "%d/", options);
      if (length) memcpy(text + prefix, source, length);
      int64_t atom = fleek_flay_atom(ctx, 'r', text, (size_t) prefix + length);
      free(text);
      return atom;
    }
    /* Interpolated string-like nodes: plain when one part remains. kind: 0 str, 1 sym, 2 xstr, 3 regexp. */
    static int64_t fleek_flay_interpolated(fleek_flay_ctx_t *ctx, const pm_node_t *at, const pm_node_list_t *parts, int kind, int options) {
      fleek_flay_values_t results = {0};
      fleek_flay_interpolated_parts(ctx, parts, &results);
      int64_t result = FLEEK_FLAY_FAIL;
      if (!ctx->failed && results.count == 1) {
        const uint8_t *bytes; size_t length;
        fleek_flay_string_value(ctx, results.values[0], &bytes, &length);
        static const char *plain[] = { "str", "lit", "xstr", "lit" };
        result = fleek_flay_s(ctx, at, plain[kind]);
        int64_t atom = kind == 1 ? fleek_flay_atom(ctx, 's', bytes, length) : kind == 3 ? fleek_flay_regexp_atom(ctx, bytes, length, options) : fleek_flay_atom(ctx, 't', bytes, length);
        fleek_flay_add(ctx, result, atom);
      } else if (!ctx->failed) {
        static const char *dynamic[] = { "dstr", "dsym", "dxstr", "dregx" };
        result = fleek_flay_s(ctx, at, dynamic[kind]);
        for (size_t index = 0; index < results.count; index++) fleek_flay_add(ctx, result, results.values[index]);
        if (kind == 3 && options != 0) fleek_flay_add(ctx, result, fleek_flay_number(ctx, options));
      }
      free(results.values);
      return ctx->failed ? FLEEK_FLAY_FAIL : result;
    }
    static const pm_node_t *fleek_flay_else_statements(const pm_node_t *clause) {
      return clause == NULL ? NULL : (const pm_node_t *) ((const pm_else_node_t *) clause)->statements;
    }
    static int64_t fleek_flay_parameter(fleek_flay_ctx_t *ctx, const pm_node_t *node);
    static int64_t fleek_flay_destructured(fleek_flay_ctx_t *ctx, const pm_multi_target_node_t *target) {
      int64_t result = fleek_flay_s(ctx, (const pm_node_t *) target, "masgn");
      const pm_node_list_t *lists[2] = { &target->lefts, &target->rights };
      for (int list = 0; list < 2; list++) {
        if (list == 1 && target->rest != NULL) {
          const pm_node_t *rest = target->rest;
          if (!PM_NODE_TYPE_P(rest, PM_SPLAT_NODE)) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
          const pm_node_t *expression = ((const pm_splat_node_t *) rest)->expression;
          pm_constant_id_t name = expression != NULL && PM_NODE_TYPE_P(expression, PM_REQUIRED_PARAMETER_NODE) ? ((const pm_required_parameter_node_t *) expression)->name : 0;
          fleek_flay_add(ctx, result, fleek_flay_name(ctx, "*", name));
        }
        for (size_t index = 0; index < lists[list]->size; index++) {
          const pm_node_t *child = lists[list]->nodes[index];
          if (PM_NODE_TYPE_P(child, PM_REQUIRED_PARAMETER_NODE)) fleek_flay_add(ctx, result, fleek_flay_symbol(ctx, ((const pm_required_parameter_node_t *) child)->name));
          else if (PM_NODE_TYPE_P(child, PM_MULTI_TARGET_NODE)) fleek_flay_add(ctx, result, fleek_flay_destructured(ctx, (const pm_multi_target_node_t *) child));
          else { ctx->failed = true; return FLEEK_FLAY_FAIL; }
        }
      }
      return result;
    }
    static int64_t fleek_flay_parameters(fleek_flay_ctx_t *ctx, const pm_parameters_node_t *parameters) {
      int64_t result = fleek_flay_s(ctx, (const pm_node_t *) parameters, "args");
      for (size_t index = 0; index < parameters->requireds.size; index++) fleek_flay_add(ctx, result, fleek_flay_parameter(ctx, parameters->requireds.nodes[index]));
      for (size_t index = 0; index < parameters->optionals.size; index++) fleek_flay_add(ctx, result, fleek_flay_parameter(ctx, parameters->optionals.nodes[index]));
      if (parameters->rest != NULL) fleek_flay_add(ctx, result, fleek_flay_parameter(ctx, parameters->rest));
      for (size_t index = 0; index < parameters->posts.size; index++) fleek_flay_add(ctx, result, fleek_flay_parameter(ctx, parameters->posts.nodes[index]));
      for (size_t index = 0; index < parameters->keywords.size; index++) fleek_flay_add(ctx, result, fleek_flay_parameter(ctx, parameters->keywords.nodes[index]));
      if (parameters->keyword_rest != NULL) fleek_flay_add(ctx, result, fleek_flay_parameter(ctx, parameters->keyword_rest));
      if (parameters->block != NULL) fleek_flay_add(ctx, result, fleek_flay_parameter(ctx, (const pm_node_t *) parameters->block));
      return result;
    }
    static int64_t fleek_flay_parameter(fleek_flay_ctx_t *ctx, const pm_node_t *node) {
      switch (PM_NODE_TYPE(node)) {
        case PM_REQUIRED_PARAMETER_NODE: return fleek_flay_symbol(ctx, ((const pm_required_parameter_node_t *) node)->name);
        case PM_MULTI_TARGET_NODE: return fleek_flay_destructured(ctx, (const pm_multi_target_node_t *) node);
        case PM_OPTIONAL_PARAMETER_NODE: {
          const pm_optional_parameter_node_t *optional = (const pm_optional_parameter_node_t *) node;
          int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "lasgn"), fleek_flay_symbol(ctx, optional->name));
          return fleek_flay_add_visit(ctx, result, optional->value);
        }
        case PM_REST_PARAMETER_NODE: return fleek_flay_name(ctx, "*", ((const pm_rest_parameter_node_t *) node)->name);
        case PM_IMPLICIT_REST_NODE: return FLEEK_FLAY_NIL;
        case PM_REQUIRED_KEYWORD_PARAMETER_NODE:
          return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "kwarg"), fleek_flay_symbol(ctx, ((const pm_required_keyword_parameter_node_t *) node)->name));
        case PM_OPTIONAL_KEYWORD_PARAMETER_NODE: {
          const pm_optional_keyword_parameter_node_t *optional = (const pm_optional_keyword_parameter_node_t *) node;
          int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "kwarg"), fleek_flay_symbol(ctx, optional->name));
          return fleek_flay_add_visit(ctx, result, optional->value);
        }
        case PM_KEYWORD_REST_PARAMETER_NODE: return fleek_flay_name(ctx, "**", ((const pm_keyword_rest_parameter_node_t *) node)->name);
        case PM_NO_KEYWORDS_PARAMETER_NODE: return fleek_flay_text_atom(ctx, 's', "**nil");
        case PM_FORWARDING_PARAMETER_NODE: return fleek_flay_s(ctx, node, "forward_args");
        case PM_BLOCK_PARAMETER_NODE: return fleek_flay_name(ctx, "&", ((const pm_block_parameter_node_t *) node)->name);
        default: ctx->failed = true; return FLEEK_FLAY_FAIL;
      }
    }
    static int64_t fleek_flay_block_parameters(fleek_flay_ctx_t *ctx, const pm_block_parameters_node_t *node) {
      bool shadow_location = true;
      int64_t result;
      if (node->parameters == NULL) result = fleek_flay_s(ctx, (const pm_node_t *) node, "args");
      else { shadow_location = false; result = fleek_flay_parameters(ctx, node->parameters); }
      if (result < 0) return FLEEK_FLAY_FAIL;
      if (node->opening_loc.start != NULL && *node->opening_loc.start == '(') {
        ctx->nodes[result].line = fleek_flay_line(ctx, node->opening_loc.start);
        ctx->nodes[result].line_max = fleek_flay_line(ctx, node->closing_loc.end);
        shadow_location = false;
      }
      if (node->locals.size != 0) {
        const pm_node_t *first = node->locals.nodes[0], *last = node->locals.nodes[node->locals.size - 1];
        int64_t shadow = fleek_flay_s(ctx, (const pm_node_t *) node, "shadow");
        for (size_t index = 0; index < node->locals.size; index++)
          fleek_flay_add(ctx, shadow, fleek_flay_symbol(ctx, ((const pm_block_local_variable_node_t *) node->locals.nodes[index])->name));
        if (shadow < 0) return FLEEK_FLAY_FAIL;
        ctx->nodes[shadow].line = fleek_flay_line(ctx, first->location.start);
        ctx->nodes[shadow].line_max = fleek_flay_line(ctx, last->location.end);
        fleek_flay_add(ctx, result, shadow);
        if (shadow_location) { ctx->nodes[result].line = ctx->nodes[shadow].line; ctx->nodes[result].line_max = ctx->nodes[shadow].line_max; }
      }
      return result;
    }
    static bool fleek_flay_regexp_node(const pm_node_t *node) {
      return node != NULL && (PM_NODE_TYPE_P(node, PM_REGULAR_EXPRESSION_NODE) || PM_NODE_TYPE_P(node, PM_INTERPOLATED_REGULAR_EXPRESSION_NODE));
    }
    static int64_t fleek_flay_call(fleek_flay_ctx_t *ctx, const pm_call_node_t *call, bool match_name) {
      const pm_node_t *node = (const pm_node_t *) call;
      pm_constant_t *constant = pm_constant_pool_id_to_constant(&ctx->parser->constant_pool, call->name);
      bool named_not_match = !match_name && constant->length == 2 && memcmp(constant->start, "!~", 2) == 0;
      if (named_not_match) return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "not"), fleek_flay_call(ctx, call, true));
      bool named_match = match_name || (constant->length == 2 && memcmp(constant->start, "=~", 2) == 0);
      const pm_node_list_t *arguments = fleek_flay_arguments(call->arguments);
      if (named_match && arguments->size == 1 && call->block == NULL) {
        const pm_node_t *argument = arguments->nodes[0];
        if (call->receiver != NULL && PM_NODE_TYPE_P(call->receiver, PM_STRING_NODE)) {
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "match3"), argument);
          return fleek_flay_add_visit(ctx, result, call->receiver);
        }
        if (fleek_flay_regexp_node(call->receiver)) {
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "match2"), call->receiver);
          return fleek_flay_add_visit(ctx, result, argument);
        }
        if (fleek_flay_regexp_node(argument)) {
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "match3"), argument);
          return fleek_flay_add_visit(ctx, result, call->receiver);
        }
      }
      bool attribute = PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_ATTRIBUTE_WRITE);
      bool safe = PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION);
      const char *type = attribute ? (safe ? "safe_attrasgn" : "attrasgn") : (safe ? "safe_call" : "call");
      int64_t result = fleek_flay_s(ctx, node, type);
      fleek_flay_add(ctx, result, call->receiver == NULL ? FLEEK_FLAY_NIL : fleek_flay_visit(ctx, call->receiver));
      fleek_flay_add(ctx, result, match_name ? fleek_flay_text_atom(ctx, 's', "=~") : fleek_flay_symbol(ctx, call->name));
      size_t count = arguments->size;
      if (attribute && count != 0) count--;
      for (size_t index = 0; index < count; index++) fleek_flay_add_visit(ctx, result, arguments->nodes[index]);
      const pm_node_t *block = call->block;
      if (block != NULL && PM_NODE_TYPE_P(block, PM_BLOCK_ARGUMENT_NODE)) { fleek_flay_add_visit(ctx, result, block); block = NULL; }
      if (attribute && arguments->size != 0) fleek_flay_add(ctx, result, fleek_flay_write_value(ctx, arguments->nodes[arguments->size - 1]));
      return fleek_flay_block(ctx, node, result, block);
    }
    /* foo.bar op= baz: op_asgn when the call operator is :: or the value is an unparenthesized call with arguments. */
    static int64_t fleek_flay_call_write(fleek_flay_ctx_t *ctx, const pm_node_t *node, const pm_node_t *receiver, pm_location_t call_operator,
        pm_constant_id_t read_name, pm_constant_id_t write_name, int64_t operator, const pm_node_t *value) {
      bool safe = PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION);
      bool colon = call_operator.start != NULL && call_operator.end - call_operator.start == 2 && call_operator.start[0] == ':';
      bool op_asgn = colon || (value != NULL && PM_NODE_TYPE_P(value, PM_CALL_NODE) && ((const pm_call_node_t *) value)->opening_loc.start == NULL &&
        ((const pm_call_node_t *) value)->arguments != NULL);
      int64_t result = fleek_flay_s(ctx, node, op_asgn ? (safe ? "safe_op_asgn" : "op_asgn") : (safe ? "safe_op_asgn2" : "op_asgn2"));
      fleek_flay_add_visit(ctx, result, receiver);
      if (op_asgn) {
        fleek_flay_add(ctx, result, fleek_flay_write_value(ctx, value));
        fleek_flay_add(ctx, result, fleek_flay_symbol(ctx, read_name));
        return fleek_flay_add(ctx, result, operator);
      }
      fleek_flay_add(ctx, result, fleek_flay_symbol(ctx, write_name));
      fleek_flay_add(ctx, result, operator);
      return fleek_flay_add(ctx, result, fleek_flay_write_value(ctx, value));
    }
    static int64_t fleek_flay_index_write(fleek_flay_ctx_t *ctx, const pm_node_t *node, const pm_node_t *receiver,
        const pm_arguments_node_t *arguments, const pm_node_t *block, int64_t operator, const pm_node_t *value) {
      int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "op_asgn1"), receiver);
      if (arguments != NULL || block != NULL) {
        int64_t arglist = fleek_flay_add_all(ctx, fleek_flay_s(ctx, node, "arglist"), fleek_flay_arguments(arguments));
        if (block != NULL) fleek_flay_add_visit(ctx, arglist, block);
        fleek_flay_add(ctx, result, arglist);
      } else {
        fleek_flay_add(ctx, result, FLEEK_FLAY_NIL);
      }
      fleek_flay_add(ctx, result, operator);
      return fleek_flay_add(ctx, result, fleek_flay_write_value(ctx, value));
    }
    static int64_t fleek_flay_pattern_constant(fleek_flay_ctx_t *ctx, const pm_node_t *constant) {
      if (constant == NULL) return FLEEK_FLAY_NIL;
      if (PM_NODE_TYPE_P(constant, PM_CONSTANT_READ_NODE)) return fleek_flay_visit(ctx, constant);
      return fleek_flay_add_visit(ctx, fleek_flay_s(ctx, constant, "const"), constant);
    }
    static pm_constant_id_t fleek_flay_target_name(const pm_node_t *node) {
      if (node == NULL) return 0;
      if (PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_TARGET_NODE)) return ((const pm_local_variable_target_node_t *) node)->name;
      if (PM_NODE_TYPE_P(node, PM_REQUIRED_PARAMETER_NODE)) return ((const pm_required_parameter_node_t *) node)->name;
      return 0;
    }
    static int64_t fleek_flay_targets(fleek_flay_ctx_t *ctx, const pm_node_t *at, const pm_node_list_t *lefts, const pm_node_t *rest, const pm_node_list_t *rights) {
      int64_t array = fleek_flay_add_all(ctx, fleek_flay_s(ctx, at, "array"), lefts);
      if (rest != NULL && !PM_NODE_TYPE_P(rest, PM_IMPLICIT_REST_NODE)) fleek_flay_add_visit(ctx, array, rest);
      return fleek_flay_add_all(ctx, array, rights);
    }
    static int64_t fleek_flay_range_bound(fleek_flay_ctx_t *ctx, const pm_node_t *node) {
      if (node != NULL && PM_NODE_TYPE_P(node, PM_PARENTHESES_NODE) && ((const pm_parentheses_node_t *) node)->body == NULL) return fleek_flay_s(ctx, node, "begin");
      return node == NULL ? FLEEK_FLAY_NIL : fleek_flay_visit(ctx, node);
    }
    static int64_t fleek_flay_string_node(fleek_flay_ctx_t *ctx, const pm_node_t *node, const char *type, const pm_string_t *value) {
      return fleek_flay_add(ctx, fleek_flay_s(ctx, node, type), fleek_flay_atom(ctx, 't', pm_string_source(value), pm_string_length(value)));
    }

    /* Range literals with integer or nil bounds become a Range atom, matching Ruby Range#==. */
    static int64_t fleek_flay_range_atom(fleek_flay_ctx_t *ctx, const pm_node_t *left, const pm_node_t *right, bool exclude) {
      pm_buffer_t buffer = {0};
      pm_buffer_init(&buffer);
      if (PM_NODE_TYPE_P(left, PM_INTEGER_NODE)) pm_integer_string(&buffer, &((const pm_integer_node_t *) left)->value);
      pm_buffer_append_string(&buffer, exclude ? "..." : "..", exclude ? 3 : 2);
      if (PM_NODE_TYPE_P(right, PM_INTEGER_NODE)) pm_integer_string(&buffer, &((const pm_integer_node_t *) right)->value);
      int64_t atom = fleek_flay_atom(ctx, 'R', (const uint8_t *) pm_buffer_value(&buffer), pm_buffer_length(&buffer));
      pm_buffer_free(&buffer);
      return atom;
    }
    static int64_t fleek_flay_visit(fleek_flay_ctx_t *ctx, const pm_node_t *node) {
      if (node == NULL) return FLEEK_FLAY_NIL;
      if (ctx->failed) return FLEEK_FLAY_FAIL;
      switch (PM_NODE_TYPE(node)) {
        case PM_ALIAS_METHOD_NODE: {
          const pm_alias_method_node_t *alias = (const pm_alias_method_node_t *) node;
          return fleek_flay_add_visit(ctx, fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "alias"), alias->new_name), alias->old_name);
        }
        case PM_ALIAS_GLOBAL_VARIABLE_NODE: {
          const pm_alias_global_variable_node_t *alias = (const pm_alias_global_variable_node_t *) node;
          int64_t result = fleek_flay_s(ctx, node, "valias");
          fleek_flay_add(ctx, result, fleek_flay_atom(ctx, 's', alias->new_name->location.start, (size_t) (alias->new_name->location.end - alias->new_name->location.start)));
          return fleek_flay_add(ctx, result, fleek_flay_atom(ctx, 's', alias->old_name->location.start, (size_t) (alias->old_name->location.end - alias->old_name->location.start)));
        }
        case PM_ALTERNATION_PATTERN_NODE: {
          const pm_alternation_pattern_node_t *pattern = (const pm_alternation_pattern_node_t *) node;
          return fleek_flay_add_visit(ctx, fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "or"), pattern->left), pattern->right);
        }
        case PM_AND_NODE: return fleek_flay_logical(ctx, node, "and", ((const pm_and_node_t *) node)->left, ((const pm_and_node_t *) node)->right);
        case PM_OR_NODE: return fleek_flay_logical(ctx, node, "or", ((const pm_or_node_t *) node)->left, ((const pm_or_node_t *) node)->right);
        case PM_ARRAY_NODE: {
          const pm_array_node_t *array = (const pm_array_node_t *) node;
          if (ctx->in_pattern) return fleek_flay_add_all(ctx, fleek_flay_add(ctx, fleek_flay_s(ctx, node, "array_pat"), FLEEK_FLAY_NIL), &array->elements);
          return fleek_flay_add_all(ctx, fleek_flay_s(ctx, node, "array"), &array->elements);
        }
        case PM_ARRAY_PATTERN_NODE: {
          const pm_array_pattern_node_t *pattern = (const pm_array_pattern_node_t *) node;
          if (pattern->constant == NULL && pattern->requireds.size == 0 && pattern->rest == NULL && pattern->posts.size == 0) return fleek_flay_s(ctx, node, "array_pat");
          int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "array_pat"), fleek_flay_pattern_constant(ctx, pattern->constant));
          fleek_flay_add_all(ctx, result, &pattern->requireds);
          if (pattern->rest != NULL && PM_NODE_TYPE_P(pattern->rest, PM_SPLAT_NODE)) {
            fleek_flay_add(ctx, result, fleek_flay_name(ctx, "*", fleek_flay_target_name(((const pm_splat_node_t *) pattern->rest)->expression)));
          } else if (pattern->rest != NULL && PM_NODE_TYPE_P(pattern->rest, PM_IMPLICIT_REST_NODE)) {
            fleek_flay_add(ctx, result, fleek_flay_text_atom(ctx, 's', "*"));
            if (result >= 0) ctx->nodes[result].line = 666;
          }
          return fleek_flay_add_all(ctx, result, &pattern->posts);
        }
        case PM_BACK_REFERENCE_READ_NODE: {
          pm_constant_t *name = pm_constant_pool_id_to_constant(&ctx->parser->constant_pool, ((const pm_back_reference_read_node_t *) node)->name);
          return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "back_ref"), fleek_flay_atom(ctx, 's', name->start + 1, name->length - 1));
        }
        case PM_BEGIN_NODE: {
          const pm_begin_node_t *begin = (const pm_begin_node_t *) node;
          int64_t result = begin->statements == NULL ? fleek_flay_s(ctx, node, "nil") : fleek_flay_visit(ctx, (const pm_node_t *) begin->statements);
          if (begin->rescue_clause != NULL) {
            if (begin->statements != NULL) {
              int64_t rescue = fleek_flay_add(ctx, fleek_flay_s(ctx, (const pm_node_t *) begin->statements, "rescue"), result);
              result = fleek_flay_add_visit(ctx, rescue, (const pm_node_t *) begin->rescue_clause);
            } else {
              result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, (const pm_node_t *) begin->rescue_clause, "rescue"), (const pm_node_t *) begin->rescue_clause);
            }
            for (const pm_rescue_node_t *current = begin->rescue_clause->subsequent; current != NULL; current = current->subsequent)
              fleek_flay_add_visit(ctx, result, (const pm_node_t *) current);
          }
          if (begin->else_clause != NULL && begin->else_clause->statements != NULL) fleek_flay_add_visit(ctx, result, (const pm_node_t *) begin->else_clause);
          if (begin->ensure_clause != NULL) {
            if (begin->statements != NULL || begin->rescue_clause != NULL || begin->else_clause != NULL) {
              const pm_node_t *at = begin->statements != NULL ? (const pm_node_t *) begin->statements : begin->rescue_clause != NULL ?
                (const pm_node_t *) begin->rescue_clause : begin->else_clause != NULL ? (const pm_node_t *) begin->else_clause : (const pm_node_t *) begin->ensure_clause;
              int64_t ensure = fleek_flay_add(ctx, fleek_flay_s(ctx, at, "ensure"), result);
              result = fleek_flay_add_visit(ctx, ensure, (const pm_node_t *) begin->ensure_clause);
            } else {
              result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, (const pm_node_t *) begin->ensure_clause, "ensure"), (const pm_node_t *) begin->ensure_clause);
            }
          }
          return result;
        }
        case PM_BLOCK_ARGUMENT_NODE: {
          int64_t result = fleek_flay_s(ctx, node, "block_pass");
          const pm_node_t *expression = ((const pm_block_argument_node_t *) node)->expression;
          return expression == NULL ? result : fleek_flay_add_visit(ctx, result, expression);
        }
        case PM_BLOCK_PARAMETERS_NODE: return fleek_flay_block_parameters(ctx, (const pm_block_parameters_node_t *) node);
        case PM_PARAMETERS_NODE: return fleek_flay_parameters(ctx, (const pm_parameters_node_t *) node);
        case PM_BREAK_NODE: return fleek_flay_jump(ctx, node, "break", ((const pm_break_node_t *) node)->arguments, false);
        case PM_NEXT_NODE: return fleek_flay_jump(ctx, node, "next", ((const pm_next_node_t *) node)->arguments, true);
        case PM_RETURN_NODE: return fleek_flay_jump(ctx, node, "return", ((const pm_return_node_t *) node)->arguments, true);
        case PM_CALL_NODE: return fleek_flay_call(ctx, (const pm_call_node_t *) node, false);
        case PM_CALL_OPERATOR_WRITE_NODE: {
          const pm_call_operator_write_node_t *write = (const pm_call_operator_write_node_t *) node;
          return fleek_flay_call_write(ctx, node, write->receiver, write->call_operator_loc, write->read_name, write->write_name, fleek_flay_symbol(ctx, write->binary_operator), write->value);
        }
        case PM_CALL_AND_WRITE_NODE: {
          const pm_call_and_write_node_t *write = (const pm_call_and_write_node_t *) node;
          return fleek_flay_call_write(ctx, node, write->receiver, write->call_operator_loc, write->read_name, write->write_name, fleek_flay_text_atom(ctx, 's', "&&"), write->value);
        }
        case PM_CALL_OR_WRITE_NODE: {
          const pm_call_or_write_node_t *write = (const pm_call_or_write_node_t *) node;
          return fleek_flay_call_write(ctx, node, write->receiver, write->call_operator_loc, write->read_name, write->write_name, fleek_flay_text_atom(ctx, 's', "||"), write->value);
        }
        case PM_CALL_TARGET_NODE: {
          const pm_call_target_node_t *target = (const pm_call_target_node_t *) node;
          return fleek_flay_add(ctx, fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "attrasgn"), target->receiver), fleek_flay_symbol(ctx, target->name));
        }
        case PM_CAPTURE_PATTERN_NODE: {
          const pm_capture_pattern_node_t *capture = (const pm_capture_pattern_node_t *) node;
          return fleek_flay_add_visit(ctx, fleek_flay_visit(ctx, (const pm_node_t *) capture->target), capture->value);
        }
        case PM_CASE_NODE: case PM_CASE_MATCH_NODE: {
          const pm_case_node_t *branch = (const pm_case_node_t *) node;
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "case"), branch->predicate);
          fleek_flay_add_all(ctx, result, &branch->conditions);
          return fleek_flay_add(ctx, result, branch->else_clause == NULL ? FLEEK_FLAY_NIL : fleek_flay_visit(ctx, (const pm_node_t *) branch->else_clause));
        }
        case PM_CLASS_NODE: {
          const pm_class_node_t *scope = (const pm_class_node_t *) node;
          int64_t result = fleek_flay_scope_name(ctx, fleek_flay_s(ctx, node, "class"), scope->constant_path, scope->name);
          fleek_flay_add_visit(ctx, result, scope->superclass);
          return fleek_flay_scope_body(ctx, result, scope->body, false);
        }
        case PM_MODULE_NODE: {
          const pm_module_node_t *scope = (const pm_module_node_t *) node;
          return fleek_flay_scope_body(ctx, fleek_flay_scope_name(ctx, fleek_flay_s(ctx, node, "module"), scope->constant_path, scope->name), scope->body, false);
        }
        case PM_SINGLETON_CLASS_NODE: {
          const pm_singleton_class_node_t *scope = (const pm_singleton_class_node_t *) node;
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "sclass"), scope->expression);
          return scope->body == NULL ? result : fleek_flay_add(ctx, result, fleek_flay_visit_mode(ctx, scope->body, 0, -1));
        }
        FLEEK_FLAY_VARIABLE_FAMILY(LOCAL_VARIABLE, local_variable, "lvar", "lasgn", true, true)
        FLEEK_FLAY_VARIABLE_FAMILY(INSTANCE_VARIABLE, instance_variable, "ivar", "iasgn", true, false)
        FLEEK_FLAY_VARIABLE_FAMILY(GLOBAL_VARIABLE, global_variable, "gvar", "gasgn", false, true)
        FLEEK_FLAY_VARIABLE_FAMILY(CONSTANT, constant, "const", "cdecl", true, false)
        case PM_CLASS_VARIABLE_WRITE_NODE: case PM_CLASS_VARIABLE_OPERATOR_WRITE_NODE: case PM_CLASS_VARIABLE_AND_WRITE_NODE:
        case PM_CLASS_VARIABLE_OR_WRITE_NODE: case PM_CLASS_VARIABLE_TARGET_NODE: {
          const char *class_variable_write = ctx->in_def ? "cvasgn" : "cvdecl";
          switch (PM_NODE_TYPE(node)) {
            FLEEK_FLAY_VARIABLE_FAMILY(CLASS_VARIABLE, class_variable, "cvar", class_variable_write, true, true)
            default: break;
          }
          return FLEEK_FLAY_FAIL;
        }
        case PM_LOCAL_VARIABLE_READ_NODE: {
          pm_constant_id_t name = ((const pm_local_variable_read_node_t *) node)->name;
          pm_constant_t *constant = pm_constant_pool_id_to_constant(&ctx->parser->constant_pool, name);
          if (constant->length == 2 && constant->start[0] == '_' && constant->start[1] >= '0' && constant->start[1] <= '9')
            return fleek_flay_add(ctx, fleek_flay_add(ctx, fleek_flay_s(ctx, node, "call"), FLEEK_FLAY_NIL), fleek_flay_symbol(ctx, name));
          return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "lvar"), fleek_flay_symbol(ctx, name));
        }
        case PM_IT_LOCAL_VARIABLE_READ_NODE:
          return fleek_flay_add(ctx, fleek_flay_add(ctx, fleek_flay_s(ctx, node, "call"), FLEEK_FLAY_NIL), fleek_flay_text_atom(ctx, 's', "it"));
        case PM_INSTANCE_VARIABLE_READ_NODE: return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "ivar"), fleek_flay_symbol(ctx, ((const pm_instance_variable_read_node_t *) node)->name));
        case PM_GLOBAL_VARIABLE_READ_NODE: return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "gvar"), fleek_flay_symbol(ctx, ((const pm_global_variable_read_node_t *) node)->name));
        case PM_CLASS_VARIABLE_READ_NODE: return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "cvar"), fleek_flay_symbol(ctx, ((const pm_class_variable_read_node_t *) node)->name));
        case PM_CONSTANT_READ_NODE: return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "const"), fleek_flay_symbol(ctx, ((const pm_constant_read_node_t *) node)->name));
        case PM_CONSTANT_PATH_NODE: case PM_CONSTANT_PATH_TARGET_NODE: {
          const pm_constant_path_node_t *path = (const pm_constant_path_node_t *) node;
          int64_t inner = path->parent == NULL ? fleek_flay_s(ctx, node, "colon3") : fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "colon2"), path->parent);
          fleek_flay_add(ctx, inner, fleek_flay_symbol(ctx, path->name));
          return PM_NODE_TYPE_P(node, PM_CONSTANT_PATH_TARGET_NODE) ? fleek_flay_add(ctx, fleek_flay_s(ctx, node, "const"), inner) : inner;
        }
        case PM_CONSTANT_PATH_WRITE_NODE: {
          const pm_constant_path_write_node_t *write = (const pm_constant_path_write_node_t *) node;
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "cdecl"), (const pm_node_t *) write->target);
          return fleek_flay_add(ctx, result, fleek_flay_write_value(ctx, write->value));
        }
        case PM_CONSTANT_PATH_OPERATOR_WRITE_NODE: {
          const pm_constant_path_operator_write_node_t *write = (const pm_constant_path_operator_write_node_t *) node;
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "op_asgn"), (const pm_node_t *) write->target);
          fleek_flay_add(ctx, result, fleek_flay_symbol(ctx, write->binary_operator));
          return fleek_flay_add(ctx, result, fleek_flay_write_value(ctx, write->value));
        }
        case PM_CONSTANT_PATH_AND_WRITE_NODE: case PM_CONSTANT_PATH_OR_WRITE_NODE: {
          const pm_constant_path_or_write_node_t *write = (const pm_constant_path_or_write_node_t *) node;
          int64_t result = fleek_flay_s(ctx, node, PM_NODE_TYPE_P(node, PM_CONSTANT_PATH_AND_WRITE_NODE) ? "op_asgn_and" : "op_asgn_or");
          fleek_flay_add_visit(ctx, result, (const pm_node_t *) write->target);
          return fleek_flay_add(ctx, result, fleek_flay_write_value(ctx, write->value));
        }
        case PM_DEF_NODE: {
          const pm_def_node_t *method = (const pm_def_node_t *) node;
          int64_t name = fleek_flay_atom(ctx, 's', method->name_loc.start, (size_t) (method->name_loc.end - method->name_loc.start));
          int64_t result = fleek_flay_s(ctx, node, method->receiver == NULL ? "defn" : "defs");
          if (method->receiver != NULL) fleek_flay_add_visit(ctx, result, method->receiver);
          fleek_flay_add(ctx, result, name);
          if (result < 0) return FLEEK_FLAY_FAIL;
          int32_t name_line = fleek_flay_line(ctx, method->name_loc.start);
          ctx->nodes[result].line = name_line;
          if (method->parameters == NULL) {
            int64_t args = fleek_flay_s(ctx, node, "args");
            if (args >= 0) ctx->nodes[args].line = name_line;
            fleek_flay_add(ctx, result, args);
          } else {
            fleek_flay_add(ctx, result, fleek_flay_parameters(ctx, method->parameters));
          }
          if (method->body == NULL) return fleek_flay_add(ctx, result, fleek_flay_s(ctx, node, "nil"));
          return fleek_flay_scope_body(ctx, result, method->body, true);
        }
        case PM_DEFINED_NODE: return fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "defined"), ((const pm_defined_node_t *) node)->value);
        case PM_ELSE_NODE: return fleek_flay_visit(ctx, (const pm_node_t *) ((const pm_else_node_t *) node)->statements);
        case PM_EMBEDDED_STATEMENTS_NODE: {
          const pm_statements_node_t *statements = ((const pm_embedded_statements_node_t *) node)->statements;
          int64_t result = fleek_flay_s(ctx, node, "evstr");
          return statements == NULL ? result : fleek_flay_add_visit(ctx, result, (const pm_node_t *) statements);
        }
        case PM_EMBEDDED_VARIABLE_NODE: return fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "evstr"), ((const pm_embedded_variable_node_t *) node)->variable);
        case PM_ENSURE_NODE: {
          const pm_statements_node_t *statements = ((const pm_ensure_node_t *) node)->statements;
          return statements == NULL ? fleek_flay_s(ctx, node, "nil") : fleek_flay_visit(ctx, (const pm_node_t *) statements);
        }
        case PM_FALSE_NODE: return fleek_flay_s(ctx, node, "false");
        case PM_TRUE_NODE: return fleek_flay_s(ctx, node, "true");
        case PM_NIL_NODE: return fleek_flay_s(ctx, node, "nil");
        case PM_SELF_NODE: return fleek_flay_s(ctx, node, "self");
        case PM_REDO_NODE: return fleek_flay_s(ctx, node, "redo");
        case PM_RETRY_NODE: return fleek_flay_s(ctx, node, "retry");
        case PM_FIND_PATTERN_NODE: {
          const pm_find_pattern_node_t *pattern = (const pm_find_pattern_node_t *) node;
          int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "find_pat"), fleek_flay_pattern_constant(ctx, pattern->constant));
          fleek_flay_add(ctx, result, fleek_flay_name(ctx, "*", fleek_flay_target_name(pattern->left->expression)));
          fleek_flay_add_all(ctx, result, &pattern->requireds);
          const pm_node_t *right = pattern->right;
          pm_constant_id_t name = right != NULL && PM_NODE_TYPE_P(right, PM_SPLAT_NODE) ? fleek_flay_target_name(((const pm_splat_node_t *) right)->expression) : 0;
          return fleek_flay_add(ctx, result, fleek_flay_name(ctx, "*", name));
        }
        case PM_FLIP_FLOP_NODE: {
          const pm_flip_flop_node_t *flip = (const pm_flip_flop_node_t *) node;
          bool exclude = PM_NODE_FLAG_P(node, PM_RANGE_FLAGS_EXCLUDE_END);
          if (flip->left != NULL && flip->right != NULL && PM_NODE_TYPE_P(flip->left, PM_INTEGER_NODE) && PM_NODE_TYPE_P(flip->right, PM_INTEGER_NODE))
            return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "lit"), fleek_flay_range_atom(ctx, flip->left, flip->right, exclude));
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, exclude ? "flip3" : "flip2"), flip->left);
          return fleek_flay_add_visit(ctx, result, flip->right);
        }
        case PM_FLOAT_NODE: return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "lit"), fleek_flay_float(ctx, ((const pm_float_node_t *) node)->value));
        case PM_INTEGER_NODE: return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "lit"), fleek_flay_integer(ctx, &((const pm_integer_node_t *) node)->value));
        case PM_RATIONAL_NODE: {
          const pm_rational_node_t *rational = (const pm_rational_node_t *) node;
          pm_buffer_t buffer = {0};
          pm_buffer_init(&buffer);
          pm_integer_string(&buffer, &rational->numerator);
          pm_buffer_t denominator = {0};
          pm_buffer_init(&denominator);
          pm_integer_string(&denominator, &rational->denominator);
          bool unit = pm_buffer_length(&denominator) == 1 && pm_buffer_value(&denominator)[0] == '1';
          if (!unit) { pm_buffer_append_byte(&buffer, '/'); pm_buffer_append_string(&buffer, pm_buffer_value(&denominator), pm_buffer_length(&denominator)); }
          int64_t atom = fleek_flay_atom(ctx, unit ? 'i' : 'q', (const uint8_t *) pm_buffer_value(&buffer), pm_buffer_length(&buffer));
          pm_buffer_free(&buffer); pm_buffer_free(&denominator);
          return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "lit"), atom);
        }
        case PM_IMAGINARY_NODE: {
          int64_t inner = fleek_flay_visit(ctx, ((const pm_imaginary_node_t *) node)->numeric);
          if (inner < 0 || ctx->nodes[inner].count != 1) return FLEEK_FLAY_FAIL;
          size_t length;
          uint32_t atom = ctx->nodes[inner].items[0].ref;
          const uint8_t *bytes = fleek_flay_atom_bytes(atom, &length);
          uint8_t buffer[256];
          if (length + 1 > sizeof(buffer)) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
          buffer[0] = (uint8_t) fleek_flay_atom_tag(atom);
          memcpy(buffer + 1, bytes, length);
          ctx->nodes[inner].items[0].ref = FLEEK_FLAY_ATOM_ID(fleek_flay_atom(ctx, 'c', buffer, length + 1));
          ctx->nodes[inner].line = fleek_flay_line(ctx, node->location.start);
          return inner;
        }
        case PM_FOR_NODE: {
          const pm_for_node_t *loop = (const pm_for_node_t *) node;
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "for"), loop->collection);
          fleek_flay_add_visit(ctx, result, loop->index);
          return fleek_flay_add_visit(ctx, result, (const pm_node_t *) loop->statements);
        }
        case PM_FORWARDING_ARGUMENTS_NODE: case PM_FORWARDING_PARAMETER_NODE: return fleek_flay_s(ctx, node, "forward_args");
        case PM_FORWARDING_SUPER_NODE: return fleek_flay_block(ctx, node, fleek_flay_s(ctx, node, "zsuper"), (const pm_node_t *) ((const pm_forwarding_super_node_t *) node)->block);
        case PM_SUPER_NODE: {
          const pm_super_node_t *call = (const pm_super_node_t *) node;
          int64_t result = fleek_flay_add_all(ctx, fleek_flay_s(ctx, node, "super"), fleek_flay_arguments(call->arguments));
          const pm_node_t *block = call->block;
          if (block != NULL && PM_NODE_TYPE_P(block, PM_BLOCK_ARGUMENT_NODE)) { fleek_flay_add_visit(ctx, result, block); block = NULL; }
          return fleek_flay_block(ctx, node, result, block);
        }
        case PM_YIELD_NODE: return fleek_flay_add_all(ctx, fleek_flay_s(ctx, node, "yield"), fleek_flay_arguments(((const pm_yield_node_t *) node)->arguments));
        case PM_HASH_NODE: case PM_KEYWORD_HASH_NODE: {
          const pm_node_list_t *elements = PM_NODE_TYPE_P(node, PM_HASH_NODE) ? &((const pm_hash_node_t *) node)->elements : &((const pm_keyword_hash_node_t *) node)->elements;
          int64_t result = fleek_flay_s(ctx, node, "hash");
          for (size_t index = 0; index < elements->size; index++) {
            const pm_node_t *element = elements->nodes[index];
            if (PM_NODE_TYPE_P(element, PM_ASSOC_NODE)) {
              fleek_flay_add_visit(ctx, result, ((const pm_assoc_node_t *) element)->key);
              fleek_flay_add_visit(ctx, result, ((const pm_assoc_node_t *) element)->value);
            } else {
              const pm_node_t *value = ((const pm_assoc_splat_node_t *) element)->value;
              int64_t splat = fleek_flay_s(ctx, element, "kwsplat");
              fleek_flay_add(ctx, result, value == NULL ? splat : fleek_flay_add_visit(ctx, splat, value));
            }
          }
          return result;
        }
        case PM_HASH_PATTERN_NODE: {
          const pm_hash_pattern_node_t *pattern = (const pm_hash_pattern_node_t *) node;
          int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "hash_pat"), fleek_flay_pattern_constant(ctx, pattern->constant));
          for (size_t index = 0; index < pattern->elements.size; index++) {
            const pm_node_t *element = pattern->elements.nodes[index];
            if (!PM_NODE_TYPE_P(element, PM_ASSOC_NODE)) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
            fleek_flay_add_visit(ctx, result, ((const pm_assoc_node_t *) element)->key);
            fleek_flay_add_visit(ctx, result, ((const pm_assoc_node_t *) element)->value);
          }
          if (pattern->rest != NULL && PM_NODE_TYPE_P(pattern->rest, PM_ASSOC_SPLAT_NODE)) {
            int64_t rest = fleek_flay_s(ctx, pattern->rest, "kwrest");
            fleek_flay_add(ctx, rest, fleek_flay_name(ctx, "**", fleek_flay_target_name(((const pm_assoc_splat_node_t *) pattern->rest)->value)));
            fleek_flay_add(ctx, result, rest);
          } else if (pattern->rest != NULL && PM_NODE_TYPE_P(pattern->rest, PM_NO_KEYWORDS_PARAMETER_NODE)) {
            fleek_flay_add_visit(ctx, result, pattern->rest);
          }
          return result;
        }
        case PM_NO_KEYWORDS_PARAMETER_NODE:
          if (ctx->in_pattern) return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "kwrest"), fleek_flay_text_atom(ctx, 's', "**nil"));
          return fleek_flay_text_atom(ctx, 's', "**nil");
        case PM_IF_NODE: {
          const pm_if_node_t *branch = (const pm_if_node_t *) node;
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "if"), branch->predicate);
          fleek_flay_add_visit(ctx, result, (const pm_node_t *) branch->statements);
          return fleek_flay_add_visit(ctx, result, branch->subsequent);
        }
        case PM_UNLESS_NODE: {
          const pm_unless_node_t *branch = (const pm_unless_node_t *) node;
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "if"), branch->predicate);
          fleek_flay_add_visit(ctx, result, (const pm_node_t *) branch->else_clause);
          return fleek_flay_add_visit(ctx, result, (const pm_node_t *) branch->statements);
        }
        case PM_IMPLICIT_NODE: case PM_IMPLICIT_REST_NODE: return FLEEK_FLAY_NIL;
        case PM_IN_NODE: {
          const pm_in_node_t *clause = (const pm_in_node_t *) node;
          int64_t pattern = PM_NODE_TYPE_P(clause->pattern, PM_CONSTANT_PATH_NODE) ?
            fleek_flay_add_visit(ctx, fleek_flay_s(ctx, clause->pattern, "const"), clause->pattern) : fleek_flay_visit_mode(ctx, clause->pattern, -1, 1);
          int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "in"), pattern);
          if (clause->statements == NULL) return fleek_flay_add(ctx, result, FLEEK_FLAY_NIL);
          return fleek_flay_add_all(ctx, result, &clause->statements->body);
        }
        case PM_WHEN_NODE: {
          const pm_when_node_t *clause = (const pm_when_node_t *) node;
          int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "when"), fleek_flay_add_all(ctx, fleek_flay_s(ctx, node, "array"), &clause->conditions));
          if (clause->statements == NULL) return fleek_flay_add(ctx, result, FLEEK_FLAY_NIL);
          return fleek_flay_add_all(ctx, result, &clause->statements->body);
        }
        case PM_INDEX_OPERATOR_WRITE_NODE: {
          const pm_index_operator_write_node_t *write = (const pm_index_operator_write_node_t *) node;
          return fleek_flay_index_write(ctx, node, write->receiver, write->arguments, (const pm_node_t *) write->block, fleek_flay_symbol(ctx, write->binary_operator), write->value);
        }
        case PM_INDEX_AND_WRITE_NODE: {
          const pm_index_and_write_node_t *write = (const pm_index_and_write_node_t *) node;
          return fleek_flay_index_write(ctx, node, write->receiver, write->arguments, (const pm_node_t *) write->block, fleek_flay_text_atom(ctx, 's', "&&"), write->value);
        }
        case PM_INDEX_OR_WRITE_NODE: {
          const pm_index_or_write_node_t *write = (const pm_index_or_write_node_t *) node;
          return fleek_flay_index_write(ctx, node, write->receiver, write->arguments, (const pm_node_t *) write->block, fleek_flay_text_atom(ctx, 's', "||"), write->value);
        }
        case PM_INDEX_TARGET_NODE: {
          const pm_index_target_node_t *target = (const pm_index_target_node_t *) node;
          int64_t result = fleek_flay_add(ctx, fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "attrasgn"), target->receiver), fleek_flay_text_atom(ctx, 's', "[]="));
          fleek_flay_add_all(ctx, result, fleek_flay_arguments(target->arguments));
          return target->block == NULL ? result : fleek_flay_add_visit(ctx, result, (const pm_node_t *) target->block);
        }
        case PM_INTERPOLATED_STRING_NODE: return fleek_flay_interpolated(ctx, node, &((const pm_interpolated_string_node_t *) node)->parts, 0, 0);
        case PM_INTERPOLATED_SYMBOL_NODE: return fleek_flay_interpolated(ctx, node, &((const pm_interpolated_symbol_node_t *) node)->parts, 1, 0);
        case PM_INTERPOLATED_X_STRING_NODE: {
          const pm_interpolated_x_string_node_t *xstring = (const pm_interpolated_x_string_node_t *) node;
          bool heredoc = xstring->opening_loc.start != NULL && xstring->opening_loc.start[0] == '<';
          return fleek_flay_interpolated(ctx, heredoc && xstring->parts.size != 0 ? xstring->parts.nodes[0] : node, &xstring->parts, 2, 0);
        }
        case PM_INTERPOLATED_REGULAR_EXPRESSION_NODE:
          return fleek_flay_interpolated(ctx, node, &((const pm_interpolated_regular_expression_node_t *) node)->parts, 3, regexp_options(node));
        case PM_INTERPOLATED_MATCH_LAST_LINE_NODE:
          return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "match"),
            fleek_flay_interpolated(ctx, node, &((const pm_interpolated_match_last_line_node_t *) node)->parts, 3, regexp_options(node)));
        case PM_REGULAR_EXPRESSION_NODE: case PM_MATCH_LAST_LINE_NODE: {
          const pm_string_t *value = PM_NODE_TYPE_P(node, PM_REGULAR_EXPRESSION_NODE) ? &((const pm_regular_expression_node_t *) node)->unescaped : &((const pm_match_last_line_node_t *) node)->unescaped;
          int64_t lit = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "lit"), fleek_flay_regexp_atom(ctx, pm_string_source(value), pm_string_length(value), regexp_options(node)));
          return PM_NODE_TYPE_P(node, PM_REGULAR_EXPRESSION_NODE) ? lit : fleek_flay_add(ctx, fleek_flay_s(ctx, node, "match"), lit);
        }
        case PM_STRING_NODE: return fleek_flay_string_node(ctx, node, "str", &((const pm_string_node_t *) node)->unescaped);
        case PM_X_STRING_NODE: {
          const pm_x_string_node_t *xstring = (const pm_x_string_node_t *) node;
          int64_t result = fleek_flay_string_node(ctx, node, "xstr", &xstring->unescaped);
          if (result >= 0 && xstring->opening_loc.start != NULL && xstring->opening_loc.start[0] == '<') {
            ctx->nodes[result].line = fleek_flay_line(ctx, xstring->content_loc.start);
            ctx->nodes[result].line_max = fleek_flay_line(ctx, xstring->content_loc.end);
          }
          return result;
        }
        case PM_SYMBOL_NODE: {
          const pm_symbol_node_t *symbol = (const pm_symbol_node_t *) node;
          int64_t result = fleek_flay_s(ctx, node, "lit");
          if (symbol->value_loc.start != NULL && symbol->value_loc.end - symbol->value_loc.start == 2 && memcmp(symbol->value_loc.start, "!@", 2) == 0)
            return fleek_flay_add(ctx, result, fleek_flay_text_atom(ctx, 's', "!@"));
          return fleek_flay_add(ctx, result, fleek_flay_atom(ctx, 's', pm_string_source(&symbol->unescaped), pm_string_length(&symbol->unescaped)));
        }
        case PM_LAMBDA_NODE: {
          const pm_lambda_node_t *lambda = (const pm_lambda_node_t *) node;
          int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "iter"), fleek_flay_s(ctx, node, "lambda"));
          const pm_node_t *parameters = lambda->parameters;
          if (parameters == NULL || PM_NODE_TYPE_P(parameters, PM_IT_PARAMETERS_NODE) || PM_NODE_TYPE_P(parameters, PM_NUMBERED_PARAMETERS_NODE))
            fleek_flay_add(ctx, result, fleek_flay_number(ctx, 0));
          else
            fleek_flay_add_visit(ctx, result, parameters);
          return lambda->body == NULL ? result : fleek_flay_add_visit(ctx, result, lambda->body);
        }
        case PM_MATCH_PREDICATE_NODE: case PM_MATCH_REQUIRED_NODE: {
          const pm_match_predicate_node_t *match = (const pm_match_predicate_node_t *) node;
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "case"), match->value);
          int64_t clause = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "in"), fleek_flay_visit_mode(ctx, match->pattern, -1, 1));
          fleek_flay_add(ctx, result, fleek_flay_add(ctx, clause, FLEEK_FLAY_NIL));
          return fleek_flay_add(ctx, result, FLEEK_FLAY_NIL);
        }
        case PM_MATCH_WRITE_NODE: {
          const pm_call_node_t *call = ((const pm_match_write_node_t *) node)->call;
          const pm_node_list_t *arguments = fleek_flay_arguments(call->arguments);
          if (arguments->size == 0) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
          return fleek_flay_add_visit(ctx, fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "match2"), call->receiver), arguments->nodes[0]);
        }
        case PM_MULTI_TARGET_NODE: {
          const pm_multi_target_node_t *target = (const pm_multi_target_node_t *) node;
          return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "masgn"), fleek_flay_targets(ctx, node, &target->lefts, target->rest, &target->rights));
        }
        case PM_MULTI_WRITE_NODE: {
          const pm_multi_write_node_t *write = (const pm_multi_write_node_t *) node;
          int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "masgn"), fleek_flay_targets(ctx, node, &write->lefts, write->rest, &write->rights));
          const pm_node_t *value = write->value;
          if (PM_NODE_TYPE_P(value, PM_ARRAY_NODE) && ((const pm_array_node_t *) value)->opening_loc.start == NULL) {
            const pm_array_node_t *array = (const pm_array_node_t *) value;
            if (array->elements.size == 1 && PM_NODE_TYPE_P(array->elements.nodes[0], PM_SPLAT_NODE)) return fleek_flay_add_visit(ctx, result, array->elements.nodes[0]);
            return fleek_flay_add_visit(ctx, result, value);
          }
          return fleek_flay_add(ctx, result, fleek_flay_add_visit(ctx, fleek_flay_s(ctx, value, "to_ary"), value));
        }
        case PM_NUMBERED_REFERENCE_READ_NODE: return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "nth_ref"), fleek_flay_number(ctx, ((const pm_numbered_reference_read_node_t *) node)->number));
        case PM_PARENTHESES_NODE: {
          const pm_node_t *body = ((const pm_parentheses_node_t *) node)->body;
          return body == NULL ? fleek_flay_s(ctx, node, "nil") : fleek_flay_visit(ctx, body);
        }
        case PM_PINNED_EXPRESSION_NODE: return fleek_flay_visit_mode(ctx, ((const pm_pinned_expression_node_t *) node)->expression, -1, 0);
        case PM_PINNED_VARIABLE_NODE: {
          const pm_node_t *variable = ((const pm_pinned_variable_node_t *) node)->variable;
          if (PM_NODE_TYPE_P(variable, PM_LOCAL_VARIABLE_READ_NODE)) {
            pm_constant_id_t name = ((const pm_local_variable_read_node_t *) variable)->name;
            pm_constant_t *constant = pm_constant_pool_id_to_constant(&ctx->parser->constant_pool, name);
            if (constant->length == 2 && constant->start[0] == '_' && constant->start[1] >= '0' && constant->start[1] <= '9')
              return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "lvar"), fleek_flay_symbol(ctx, name));
          }
          return fleek_flay_visit(ctx, variable);
        }
        case PM_PRE_EXECUTION_NODE: case PM_POST_EXECUTION_NODE: {
          const pm_statements_node_t *statements = PM_NODE_TYPE_P(node, PM_PRE_EXECUTION_NODE) ? ((const pm_pre_execution_node_t *) node)->statements : ((const pm_post_execution_node_t *) node)->statements;
          int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "iter"), fleek_flay_s(ctx, node, PM_NODE_TYPE_P(node, PM_PRE_EXECUTION_NODE) ? "preexe" : "postexe"));
          fleek_flay_add(ctx, result, fleek_flay_number(ctx, 0));
          return fleek_flay_add_visit(ctx, result, (const pm_node_t *) statements);
        }
        case PM_RANGE_NODE: {
          const pm_range_node_t *range = (const pm_range_node_t *) node;
          bool exclude = PM_NODE_FLAG_P(node, PM_RANGE_FLAGS_EXCLUDE_END);
          bool literal = !ctx->in_pattern && range->left != NULL && range->right != NULL &&
            (PM_NODE_TYPE_P(range->left, PM_NIL_NODE) || PM_NODE_TYPE_P(range->left, PM_INTEGER_NODE)) &&
            (PM_NODE_TYPE_P(range->right, PM_NIL_NODE) || PM_NODE_TYPE_P(range->right, PM_INTEGER_NODE));
          if (literal) return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "lit"), fleek_flay_range_atom(ctx, range->left, range->right, exclude));
          int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, exclude ? "dot3" : "dot2"), fleek_flay_range_bound(ctx, range->left));
          return fleek_flay_add(ctx, result, fleek_flay_range_bound(ctx, range->right));
        }
        case PM_RESCUE_MODIFIER_NODE: {
          const pm_rescue_modifier_node_t *rescue = (const pm_rescue_modifier_node_t *) node;
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "rescue"), rescue->expression);
          int64_t body = fleek_flay_add(ctx, fleek_flay_s(ctx, rescue->rescue_expression, "resbody"), fleek_flay_s(ctx, rescue->rescue_expression, "array"));
          return fleek_flay_add(ctx, result, fleek_flay_add_visit(ctx, body, rescue->rescue_expression));
        }
        case PM_RESCUE_NODE: {
          const pm_rescue_node_t *rescue = (const pm_rescue_node_t *) node;
          int64_t exceptions = rescue->exceptions.size == 1 && PM_NODE_TYPE_P(rescue->exceptions.nodes[0], PM_SPLAT_NODE) ?
            fleek_flay_visit(ctx, rescue->exceptions.nodes[0]) : fleek_flay_add_all(ctx, fleek_flay_s(ctx, node, "array"), &rescue->exceptions);
          if (rescue->reference != NULL) {
            int64_t reference = fleek_flay_visit(ctx, rescue->reference);
            fleek_flay_add(ctx, reference, fleek_flay_add(ctx, fleek_flay_s(ctx, rescue->reference, "gvar"), fleek_flay_text_atom(ctx, 's', "$!")));
            fleek_flay_add(ctx, exceptions, reference);
          }
          int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "resbody"), exceptions);
          if (rescue->statements == NULL) return fleek_flay_add(ctx, result, FLEEK_FLAY_NIL);
          return fleek_flay_add_all(ctx, result, &rescue->statements->body);
        }
        case PM_SHAREABLE_CONSTANT_NODE: return fleek_flay_visit(ctx, ((const pm_shareable_constant_node_t *) node)->write);
        case PM_SOURCE_ENCODING_NODE: {
          int64_t result = fleek_flay_add(ctx, fleek_flay_s(ctx, node, "colon2"), fleek_flay_add(ctx, fleek_flay_s(ctx, node, "const"), fleek_flay_text_atom(ctx, 's', "Encoding")));
          return fleek_flay_add(ctx, result, fleek_flay_text_atom(ctx, 's', "UTF_8"));
        }
        case PM_SOURCE_FILE_NODE:
          if (ctx->file_path == NULL) { ctx->failed = true; return FLEEK_FLAY_FAIL; }
          return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "str"), fleek_flay_atom(ctx, 't', (const uint8_t *) ctx->file_path, ctx->file_path_length));
        case PM_SOURCE_LINE_NODE:
          return fleek_flay_add(ctx, fleek_flay_s(ctx, node, "lit"), fleek_flay_number(ctx, fleek_flay_line(ctx, node->location.start) - ctx->file_start_line + 1));
        case PM_SPLAT_NODE: {
          const pm_node_t *expression = ((const pm_splat_node_t *) node)->expression;
          int64_t result = fleek_flay_s(ctx, node, "splat");
          return expression == NULL ? result : fleek_flay_add_visit(ctx, result, expression);
        }
        case PM_STATEMENTS_NODE: return fleek_flay_statements(ctx, node, &((const pm_statements_node_t *) node)->body);
        case PM_UNDEF_NODE: {
          const pm_undef_node_t *undef = (const pm_undef_node_t *) node;
          if (undef->names.size == 1) return fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "undef"), undef->names.nodes[0]);
          int64_t result = fleek_flay_s(ctx, node, "block");
          for (size_t index = 0; index < undef->names.size; index++) fleek_flay_add(ctx, result, fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, "undef"), undef->names.nodes[index]));
          return result;
        }
        case PM_WHILE_NODE: case PM_UNTIL_NODE: {
          const pm_while_node_t *loop = (const pm_while_node_t *) node;
          int64_t result = fleek_flay_add_visit(ctx, fleek_flay_s(ctx, node, PM_NODE_TYPE_P(node, PM_WHILE_NODE) ? "while" : "until"), loop->predicate);
          fleek_flay_add_visit(ctx, result, (const pm_node_t *) loop->statements);
          return fleek_flay_add(ctx, result, fleek_flay_atom(ctx, PM_NODE_FLAG_P(node, PM_LOOP_FLAGS_BEGIN_MODIFIER) ? 'F' : 'T', NULL, 0));
        }
        default:
          ctx->failed = true;
          return FLEEK_FLAY_FAIL;
      }
    }

    /* Post-order shape, value and mass computation. */
    static bool fleek_flay_finish(fleek_flay_ctx_t *ctx, uint32_t index) {
      fleek_flay_sexp_t *node = &ctx->nodes[index];
      if (node->shape != 0 || node->value != 0 || node->mass != 0) return true;
      uint32_t stack_shape[32], stack_value[32];
      size_t words = (size_t) node->count + 1;
      uint32_t *shape = words <= 32 ? stack_shape : malloc(words * sizeof(uint32_t));
      uint32_t *value = words <= 32 ? stack_value : malloc(words * sizeof(uint32_t));
      bool ok = shape != NULL && value != NULL;
      size_t shape_count = 0;
      uint32_t mass = 1;
      bool has_sexp = false;
      if (ok) { shape[shape_count++] = node->type; value[0] = node->type; }
      for (uint32_t item = 0; ok && item < ctx->nodes[index].count; item++) {
        fleek_flay_item_t child = ctx->nodes[index].items[item];
        if (child.atom) { value[item + 1] = child.ref * 2 + 1; continue; }
        if (!fleek_flay_finish(ctx, child.ref)) { ok = false; break; }
        const fleek_flay_sexp_t *sub = &ctx->nodes[child.ref];
        has_sexp = true;
        mass += sub->mass;
        shape[shape_count++] = sub->shape;
        value[item + 1] = sub->value * 2;
      }
      if (ok) {
        node = &ctx->nodes[index];
        node->has_sexp = has_sexp;
        node->mass = mass;
        node->shape = fleek_flay_intern(&fleek_flay_shapes, shape, shape_count) + 1;
        node->value = fleek_flay_intern(&fleek_flay_values, value, words) + 1;
        ok = node->shape != 0 && node->value != 0;
      }
      if (shape != stack_shape) free(shape);
      if (value != stack_value) free(value);
      return ok;
    }

    typedef struct { uint32_t *nodes; size_t count, capacity; } fleek_flay_list_t;
    static bool fleek_flay_list_push(fleek_flay_list_t *list, uint32_t value) {
      if (list->count == list->capacity) {
        size_t capacity = list->capacity == 0 ? 256 : list->capacity * 2;
        uint32_t *nodes = realloc(list->nodes, capacity * sizeof(uint32_t));
        if (nodes == NULL) return false;
        list->nodes = nodes; list->capacity = capacity;
      }
      list->nodes[list->count++] = value;
      return true;
    }
    static size_t fleek_flay_code_index(const char *type) {
      if (strcmp(type, "block") == 0) return 0;
      if (strcmp(type, "module") == 0) return 1;
      if (strcmp(type, "class") == 0 || strcmp(type, "defn") == 0 || strcmp(type, "iter") == 0) return 2;
      if (strcmp(type, "defs") == 0) return 3;
      return SIZE_MAX;
    }
    /* Flay#process_fuzzy: template plus every combination of code statements missing up to +difference+. */
    static bool fleek_flay_fuzzy(fleek_flay_ctx_t *ctx, uint32_t index, int mass_threshold, int difference, fleek_flay_list_t *hashed) {
      size_t code_index = fleek_flay_code_index(fleek_flay_type_names[ctx->nodes[index].type]);
      if (code_index == SIZE_MAX) return true;
      size_t size = (size_t) ctx->nodes[index].count + 1;
      if (size > 10 || ctx->nodes[index].mass / size > 12) return true;
      size_t template_items = code_index;
      if (template_items > ctx->nodes[index].count) template_items = ctx->nodes[index].count;
      size_t code_count = ctx->nodes[index].count - template_items;
      for (long remove = 1; remove <= difference; remove++) {
        long keep = (long) code_count - remove;
        if (keep < 0) break;
        size_t choice[16];
        for (long position = 0; position < keep; position++) choice[position] = (size_t) position;
        for (;;) {
          int64_t fuzzy = fleek_flay_sexp_at(ctx, fleek_flay_type_names[ctx->nodes[index].type], ctx->nodes[index].line, ctx->nodes[index].line_max);
          if (fuzzy < 0) return false;
          ctx->nodes[fuzzy].modified = true;
          for (size_t item = 0; item < template_items; item++) {
            fleek_flay_item_t copy = ctx->nodes[index].items[item];
            fleek_flay_add(ctx, fuzzy, copy.atom ? FLEEK_FLAY_ATOM(copy.ref) : (int64_t) copy.ref);
          }
          for (long position = 0; position < keep; position++) {
            fleek_flay_item_t copy = ctx->nodes[index].items[template_items + choice[position]];
            fleek_flay_add(ctx, fuzzy, copy.atom ? FLEEK_FLAY_ATOM(copy.ref) : (int64_t) copy.ref);
          }
          if (ctx->failed || !fleek_flay_finish(ctx, (uint32_t) fuzzy)) return false;
          const fleek_flay_sexp_t *created = &ctx->nodes[fuzzy];
          if (created->has_sexp && (int) created->mass >= mass_threshold) {
            bool duplicate = false;
            for (size_t existing = 0; existing < hashed->count && !duplicate; existing++) {
              const fleek_flay_sexp_t *other = &ctx->nodes[hashed->nodes[existing]];
              duplicate = other->shape == created->shape && other->line == created->line;
            }
            if (!duplicate && !fleek_flay_list_push(hashed, (uint32_t) fuzzy)) return false;
          }
          long position = keep - 1;
          while (position >= 0 && choice[position] == code_count - (size_t) keep + (size_t) position) position--;
          if (position < 0) break;
          choice[position]++;
          for (long next = position + 1; next < keep; next++) choice[next] = choice[next - 1] + 1;
        }
      }
      return true;
    }
    /* Flay#process_sexp: deep_each below the root, skipping atom-only and light subtrees. */
    static bool fleek_flay_collect(fleek_flay_ctx_t *ctx, uint32_t index, int mass_threshold, int fuzzy, fleek_flay_list_t *hashed) {
      for (uint32_t item = 0; item < ctx->nodes[index].count; item++) {
        if (ctx->nodes[index].items[item].atom) continue;
        uint32_t child = ctx->nodes[index].items[item].ref;
        if (!ctx->nodes[child].has_sexp || (int) ctx->nodes[child].mass < mass_threshold) continue;
        if (!fleek_flay_list_push(hashed, child)) return false;
        if (fuzzy > 0 && !fleek_flay_fuzzy(ctx, child, mass_threshold, fuzzy, hashed)) return false;
        if (!fleek_flay_collect(ctx, child, mass_threshold, fuzzy, hashed)) return false;
      }
      return true;
    }
    static void fleek_flay_mark_subshapes(const fleek_flay_ctx_t *ctx, uint32_t index, uint8_t *marked) {
      const fleek_flay_sexp_t *node = &ctx->nodes[index];
      for (uint32_t item = 0; item < node->count; item++) {
        if (node->items[item].atom) continue;
        marked[ctx->nodes[node->items[item].ref].shape] = 1;
        fleek_flay_mark_subshapes(ctx, node->items[item].ref, marked);
      }
    }
    static void fleek_flay_mark_liberal(const fleek_flay_ctx_t *ctx, uint32_t index, const uint64_t *masses, uint64_t top, uint8_t *pruned) {
      const fleek_flay_sexp_t *node = &ctx->nodes[index];
      for (uint32_t item = 0; item < node->count; item++) {
        if (node->items[item].atom) continue;
        uint32_t child = node->items[item].ref;
        uint64_t sub = masses[ctx->nodes[child].shape];
        if (!(sub != 0 && sub > top)) pruned[child] = 1;
        fleek_flay_mark_liberal(ctx, child, masses, top, pruned);
      }
    }

    /* Per-file parse failures, one "index\\tline\\tcolumn\\toffset\\tmessage" record per line. */
    static char *fleek_flay_failures;
    static size_t fleek_flay_failures_used, fleek_flay_failures_capacity;
    static bool fleek_flay_record_failure(size_t file, pm_parser_t *parser, const char *source, int32_t start_line) {
      const pm_diagnostic_t *diagnostic = (const pm_diagnostic_t *) parser->error_list.head;
      pm_line_column_t position = pm_newline_list_line_column(&parser->newline_list, diagnostic->location.start, parser->start_line);
      char record[1024];
      int written = snprintf(record, sizeof(record), "%zu\\t%d\\t%u\\t%ld\\t%s\\n", file, (int) (position.line - start_line + 1), (unsigned) position.column + 1,
        (long) (diagnostic->location.start - (const uint8_t *) source), diagnostic->message);
      if (written < 0) return false;
      size_t length = (size_t) written < sizeof(record) ? (size_t) written : sizeof(record) - 1;
      if (fleek_flay_failures_used + length + 1 > fleek_flay_failures_capacity) {
        size_t capacity = fleek_flay_failures_capacity == 0 ? 1024 : fleek_flay_failures_capacity * 2;
        while (fleek_flay_failures_used + length + 1 > capacity) capacity *= 2;
        char *resized = realloc(fleek_flay_failures, capacity);
        if (resized == NULL) return false;
        fleek_flay_failures = resized; fleek_flay_failures_capacity = capacity;
      }
      memcpy(fleek_flay_failures + fleek_flay_failures_used, record, length);
      fleek_flay_failures_used += length;
      fleek_flay_failures[fleek_flay_failures_used] = 0;
      return true;
    }
    static int fleek_flay_generic(const char *source, size_t length, int mass_threshold, int liberal, int fuzzy, int legacy, const char *file_offsets, const char *file_paths) {
      size_t offsets[4096];
      size_t file_count = 0;
      const char *cursor = file_offsets;
      while (cursor != NULL && *cursor != 0) {
        if (file_count == 4096) return FLEEK_FLAY_UNTRANSLATED;
        offsets[file_count++] = (size_t) strtoull(cursor, (char **) &cursor, 10);
        if (*cursor == ',') cursor++;
      }
      if (file_count == 0) offsets[file_count++] = 0;
      fleek_flay_ctx_t ctx = {0};
      pm_parser_t parser;
      int result = FLEEK_FLAY_UNTRANSLATED;
      fleek_flay_list_t hashed = {0};
      fleek_flay_type_count = 0;
      fleek_flay_intern_free(&fleek_flay_atoms); fleek_flay_intern_free(&fleek_flay_shapes); fleek_flay_intern_free(&fleek_flay_values);
      int32_t start_line = 1;
      size_t previous = 0;
      const char *path_cursor = file_paths != NULL && file_paths[0] != 0 ? file_paths : NULL;
      for (size_t file = 0; file < file_count; file++) {
        size_t start = offsets[file];
        size_t end = file + 1 < file_count ? offsets[file + 1] : length;
        if (start > end || end > length) goto done;
        for (size_t at = previous; at < start; at++) if (source[at] == '\\n') start_line++;
        previous = start;
        pm_options_t options = {0};
        options.line = start_line;
        options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
        options.partial_script = true;
        pm_parser_init(&parser, (const uint8_t *) source + start, end - start, &options);
        pm_node_t *root = pm_parse(&parser);
        bool parsed = parser.error_list.head == NULL && PM_NODE_TYPE_P(root, PM_PROGRAM_NODE);
        if (!parsed) {
          bool recorded = parser.error_list.head != NULL && fleek_flay_record_failure(file, &parser, source + start, start_line);
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
          if (!recorded) goto done;
          if (path_cursor != NULL) { const char *next = strchr(path_cursor, '\\n'); path_cursor = next == NULL ? NULL : next + 1; }
          continue;
        }
        if (legacy) {
          fleek_legacy_parser_state_t legacy_state = { false };
          pm_visit_node(root, fleek_legacy_parser_syntax_supported, &legacy_state);
          if (legacy_state.unsupported) { result = FLEEK_DUPLICATION_LEGACY_PARSE_ERROR; pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); goto done; }
        }
        ctx.file_path = path_cursor;
        ctx.file_path_length = path_cursor == NULL ? 0 : strcspn(path_cursor, "\\n");
        if (path_cursor != NULL) path_cursor = path_cursor[ctx.file_path_length] == 0 ? NULL : path_cursor + ctx.file_path_length + 1;
        ctx.parser = &parser;
        ctx.in_def = false; ctx.in_pattern = false;
        ctx.file_start_line = start_line;
        int64_t translated = FLEEK_FLAY_NIL;
        const pm_statements_node_t *statements = parsed ? ((const pm_program_node_t *) root)->statements : NULL;
        if (statements != NULL && statements->body.size != 0) translated = fleek_flay_visit(&ctx, (const pm_node_t *) statements);
        bool ok = parsed && !ctx.failed && translated != FLEEK_FLAY_FAIL;
        if (ok && translated >= 0) ok = fleek_flay_finish(&ctx, (uint32_t) translated) && fleek_flay_collect(&ctx, (uint32_t) translated, mass_threshold, fuzzy, &hashed);
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
        if (!ok) goto done;
      }
      {
        size_t shape_count = fleek_flay_shapes.count + 1;
        uint32_t *group_size = calloc(shape_count + 1, sizeof(uint32_t));
        uint32_t *group_start = calloc(shape_count + 1, sizeof(uint32_t));
        uint32_t *members = malloc((hashed.count + 1) * sizeof(uint32_t));
        uint8_t *removed = calloc(shape_count + 1, 1);
        uint8_t *pruned = calloc(ctx.count + 1, 1);
        uint64_t *masses = calloc(shape_count + 1, sizeof(uint64_t));
        int *lines = malloc((hashed.count + 1) * sizeof(int));
        int *fuzzy_lines = malloc((hashed.count + 1) * sizeof(int));
        bool ok = group_size && group_start && members && removed && pruned && masses && lines && fuzzy_lines;
        if (ok) {
          for (size_t index = 0; index < hashed.count; index++) group_size[ctx.nodes[hashed.nodes[index]].shape]++;
          uint32_t running = 0;
          for (size_t shape = 0; shape < shape_count; shape++) { group_start[shape] = running; running += group_size[shape]; group_size[shape] = 0; }
          for (size_t index = 0; index < hashed.count; index++) {
            uint32_t shape = ctx.nodes[hashed.nodes[index]].shape;
            members[group_start[shape] + group_size[shape]++] = hashed.nodes[index];
          }
          for (size_t shape = 0; shape < shape_count; shape++) {
            bool all_modified = group_size[shape] != 0;
            for (uint32_t member = 0; member < group_size[shape]; member++) if (!ctx.nodes[members[group_start[shape] + member]].modified) all_modified = false;
            if (group_size[shape] < 2 || all_modified) removed[shape] = 1;
          }
          if (liberal) {
            for (size_t shape = 0; shape < shape_count; shape++)
              if (!removed[shape]) masses[shape] = (uint64_t) ctx.nodes[members[group_start[shape]]].mass * group_size[shape];
            for (size_t shape = 0; shape < shape_count; shape++) {
              if (removed[shape]) continue;
              for (uint32_t member = 0; member < group_size[shape]; member++)
                fleek_flay_mark_liberal(&ctx, members[group_start[shape] + member], masses, masses[shape], pruned);
            }
            for (size_t shape = 0; shape < shape_count; shape++) {
              if (removed[shape]) continue;
              uint32_t kept = 0;
              for (uint32_t member = 0; member < group_size[shape]; member++) {
                uint32_t node = members[group_start[shape] + member];
                if (!pruned[node]) members[group_start[shape] + kept++] = node;
              }
              group_size[shape] = kept;
              if (kept <= 1) removed[shape] = 1;
            }
          } else {
            uint8_t *marked = calloc(shape_count + 1, 1);
            if (marked == NULL) ok = false;
            else {
              for (size_t shape = 0; shape < shape_count; shape++)
                if (!removed[shape]) fleek_flay_mark_subshapes(&ctx, members[group_start[shape]], marked);
              for (size_t shape = 0; shape < shape_count; shape++) if (marked[shape]) removed[shape] = 1;
              free(marked);
            }
          }
        }
        for (size_t shape = 0; ok && shape < shape_count; shape++) {
          if (removed[shape]) continue;
          const fleek_flay_sexp_t *first = &ctx.nodes[members[group_start[shape]]];
          bool identical = true, any_fuzzy = false;
          for (uint32_t member = 0; member < group_size[shape]; member++) {
            const fleek_flay_sexp_t *node = &ctx.nodes[members[group_start[shape] + member]];
            if (node->value != first->value) identical = false;
            lines[member] = node->line;
            fuzzy_lines[member] = node->modified ? node->line : 0;
            if (node->modified) any_fuzzy = true;
          }
          ok = fleek_duplication_append_group(fleek_flay_type_names[first->type], identical, first->mass, lines,
            group_size[shape], FLEEK_DUPLICATION_GROUP_ITER, any_fuzzy ? fuzzy_lines : NULL);
        }
        free(group_size); free(group_start); free(members); free(removed); free(pruned); free(masses); free(lines); free(fuzzy_lines);
        if (ok) result = fleek_duplication_total_score;
      }
    done:
      for (size_t index = 0; index < ctx.count; index++) free(ctx.nodes[index].items);
      free(ctx.nodes); free(hashed.nodes);
      fleek_flay_intern_free(&fleek_flay_atoms); fleek_flay_intern_free(&fleek_flay_shapes); fleek_flay_intern_free(&fleek_flay_values);
      if (result < 0) {
        if (fleek_duplication_buffer != NULL) fleek_duplication_buffer[0] = 0;
        fleek_duplication_buffer_used = 0;
        fleek_duplication_total_score = 0;
      }
      return result;
    }

    int fleek_structural_duplication(const char *source, size_t length, int mass_threshold, int liberal, int fuzzy, int legacy, const char *file_offsets, const char *file_paths) {
      fleek_flay_failures_used = 0;
      if (fleek_flay_failures != NULL) fleek_flay_failures[0] = 0;
      if (fleek_duplication_buffer != NULL) fleek_duplication_buffer[0] = 0;
      fleek_duplication_buffer_used = 0;
      fleek_duplication_total_score = 0;
      if (memchr(source, 0, length) != NULL) return FLEEK_DUPLICATION_NUL_SOURCE;
      int result = fleek_flay_generic(source, length, mass_threshold, liberal, fuzzy, legacy, file_offsets, file_paths);
      return result == FLEEK_FLAY_UNTRANSLATED ? FLEEK_DUPLICATION_UNSUPPORTED_SOURCE : result;
    }

    const char *fleek_structural_duplication_finding(void) { return fleek_duplication_buffer == NULL ? "" : fleek_duplication_buffer; }
    const char *fleek_structural_duplication_failures(void) { return fleek_flay_failures == NULL ? "" : fleek_flay_failures; }

    /* Reek AST translation (ADR 0257): Prism -> parser-gem AST as Reek 6.6.0 builds it
       (Parser::CurrentRuby with legacy builder modes and emit_lambda). Emits S-expression text. */
    typedef struct { char *text; size_t used, capacity; bool failed; bool annotate; bool in_parts; bool heredoc_next; pm_parser_t *parser; const uint8_t *source; const char *path; size_t path_length; int32_t start_line; } fleek_reek_ast_t;
    static char *fleek_reek_ast_buffer;
    static char *fleek_reek_comments_buffer;
    static void fleek_reek_emit(fleek_reek_ast_t *ast, const char *text, size_t length) {
      if (ast->failed) return;
      if (ast->used + length + 1 > ast->capacity) {
        size_t capacity = ast->capacity == 0 ? 4096 : ast->capacity;
        while (ast->used + length + 1 > capacity) capacity *= 2;
        char *resized = realloc(ast->text, capacity);
        if (resized == NULL) { ast->failed = true; return; }
        ast->text = resized; ast->capacity = capacity;
      }
      memcpy(ast->text + ast->used, text, length);
      ast->used += length;
      ast->text[ast->used] = 0;
    }
    static void fleek_reek_text(fleek_reek_ast_t *ast, const char *text) { fleek_reek_emit(ast, text, strlen(text)); }
    static int32_t fleek_reek_line(fleek_reek_ast_t *ast, const uint8_t *cursor) {
      return pm_newline_list_line(&ast->parser->newline_list, cursor, ast->parser->start_line);
    }
    /* Opens "(type" with an optional "@line:begin:end" expression annotation. */
    static void fleek_reek_open_at(fleek_reek_ast_t *ast, const char *type, const uint8_t *start, const uint8_t *end) {
      fleek_reek_text(ast, ast->used == 0 ? "(" : " (");
      fleek_reek_text(ast, type);
      bool heredoc = ast->heredoc_next;
      ast->heredoc_next = false;
      if (ast->annotate && start != NULL) {
        char location[64];
        int written = snprintf(location, sizeof(location), "@%d:%ld:%ld", (int) fleek_reek_line(ast, start),
          (long) (start - ast->source), (long) (end - ast->source));
        fleek_reek_emit(ast, location, (size_t) written);
        if (heredoc) fleek_reek_text(ast, ":h");
      }
    }
    static void fleek_reek_open(fleek_reek_ast_t *ast, const char *type, const pm_node_t *node) {
      fleek_reek_open_at(ast, type, node == NULL ? NULL : node->location.start, node == NULL ? NULL : node->location.end);
    }
    static void fleek_reek_close(fleek_reek_ast_t *ast) { fleek_reek_text(ast, ")"); }
    static void fleek_reek_nil(fleek_reek_ast_t *ast) { fleek_reek_text(ast, " nil"); }
    static bool fleek_reek_identifier(const uint8_t *bytes, size_t length) {
      if (length == 0) return false;
      size_t index = 0;
      if (bytes[0] == '$') { index = 1; }
      else if (bytes[0] == '@') { index = length > 1 && bytes[1] == '@' ? 2 : 1; }
      if (index >= length || !(isalpha(bytes[index]) || bytes[index] == '_' || bytes[index] >= 0x80)) return false;
      for (index++; index < length; index++) {
        uint8_t byte = bytes[index];
        if (isalnum(byte) || byte == '_' || byte >= 0x80) continue;
        if (index == length - 1 && (byte == '?' || byte == '!' || byte == '=') && bytes[0] != '$' && bytes[0] != '@') continue;
        return false;
      }
      return true;
    }
    static bool fleek_reek_operator(const uint8_t *bytes, size_t length) {
      static const char *operators[] = { "[]", "[]=", "+", "-", "*", "/", "%", "**", "==", "===", "!=", "<", ">", "<=", ">=", "<=>",
        "<<", ">>", "&", "|", "^", "~", "!", "+@", "-@", "=~", "!~", "`", NULL };
      for (size_t index = 0; operators[index] != NULL; index++)
        if (strlen(operators[index]) == length && memcmp(operators[index], bytes, length) == 0) return true;
      return false;
    }
    /* Ruby String#inspect body (without quotes). */
    static void fleek_reek_escaped(fleek_reek_ast_t *ast, const uint8_t *bytes, size_t length) {
      for (size_t index = 0; index < length; index++) {
        uint8_t byte = bytes[index];
        char escape[8];
        const char *text = NULL;
        switch (byte) {
          case '"': text = "\\\\\\""; break;
          case '\\\\': text = "\\\\\\\\"; break;
          case '\\n': text = "\\\\n"; break;
          case '\\t': text = "\\\\t"; break;
          case '\\r': text = "\\\\r"; break;
          case '\\f': text = "\\\\f"; break;
          case '\\v': text = "\\\\v"; break;
          case '\\a': text = "\\\\a"; break;
          case '\\b': text = "\\\\b"; break;
          case 27: text = "\\\\e"; break;
          case '#':
            if (index + 1 < length && (bytes[index + 1] == '{' || bytes[index + 1] == '$' || bytes[index + 1] == '@')) text = "\\\\#";
            break;
          default:
            if (byte < 0x20 || byte == 0x7f) { snprintf(escape, sizeof(escape), "\\\\x%02X", byte); text = escape; }
            break;
        }
        if (text != NULL) fleek_reek_text(ast, text);
        else fleek_reek_emit(ast, (const char *) &bytes[index], 1);
      }
    }
    static void fleek_reek_string_atom(fleek_reek_ast_t *ast, const uint8_t *bytes, size_t length) {
      fleek_reek_text(ast, " \\"");
      fleek_reek_escaped(ast, bytes, length);
      fleek_reek_text(ast, "\\"");
    }
    static void fleek_reek_symbol_bytes(fleek_reek_ast_t *ast, const uint8_t *bytes, size_t length) {
      if (fleek_reek_identifier(bytes, length) || fleek_reek_operator(bytes, length)) {
        fleek_reek_text(ast, " :");
        fleek_reek_emit(ast, (const char *) bytes, length);
      } else {
        fleek_reek_text(ast, " :\\"");
        fleek_reek_escaped(ast, bytes, length);
        fleek_reek_text(ast, "\\"");
      }
    }
    static void fleek_reek_symbol(fleek_reek_ast_t *ast, pm_constant_id_t name) {
      pm_constant_t *constant = pm_constant_pool_id_to_constant(&ast->parser->constant_pool, name);
      fleek_reek_symbol_bytes(ast, constant->start, constant->length);
    }
    static void fleek_reek_integer_raw(fleek_reek_ast_t *ast, const pm_integer_t *integer) {
      pm_buffer_t buffer = {0};
      pm_buffer_init(&buffer);
      pm_integer_string(&buffer, integer);
      fleek_reek_emit(ast, pm_buffer_value(&buffer), pm_buffer_length(&buffer));
      pm_buffer_free(&buffer);
    }
    static void fleek_reek_integer(fleek_reek_ast_t *ast, const pm_integer_t *integer) {
      fleek_reek_text(ast, " ");
      fleek_reek_integer_raw(ast, integer);
    }
    /* Ruby Float#inspect: shortest round-trip digits, scientific below 1e-4 or from 1e16. */
    static void fleek_reek_float_text(double value, char *out, size_t size) {
      if (value != value) { snprintf(out, size, "NaN"); return; }
      if (value == 1.0 / 0.0) { snprintf(out, size, "Infinity"); return; }
      if (value == -1.0 / 0.0) { snprintf(out, size, "-Infinity"); return; }
      char digits[64];
      int precision = 1;
      for (; precision <= 17; precision++) {
        snprintf(digits, sizeof(digits), "%.*e", precision - 1, value);
        if (strtod(digits, NULL) == value) break;
      }
      char *exponent_mark = strchr(digits, 'e');
      int exponent = atoi(exponent_mark + 1);
      *exponent_mark = 0;
      char mantissa[32]; size_t count = 0;
      const char *cursor = digits;
      bool negative = *cursor == '-';
      if (negative) cursor++;
      for (; *cursor; cursor++) if (*cursor != '.') mantissa[count++] = *cursor;
      mantissa[count] = 0;
      while (count > 1 && mantissa[count - 1] == '0') mantissa[--count] = 0;
      char *target = out; size_t left = size;
      int written;
      if (negative) { *target++ = '-'; left--; }
      if (exponent < -4 || exponent >= 16) {
        written = snprintf(target, left, "%c.%se%c%02d", mantissa[0], count > 1 ? mantissa + 1 : "0", exponent < 0 ? '-' : '+', exponent < 0 ? -exponent : exponent);
      } else if (exponent < 0) {
        written = snprintf(target, left, "0.%0*d%s", -exponent - 1, 0, mantissa);
        if (-exponent - 1 == 0) written = snprintf(target, left, "0.%s", mantissa);
      } else if ((size_t) exponent + 1 >= count) {
        written = snprintf(target, left, "%s%0*d.0", mantissa, (int) ((size_t) exponent + 1 - count), 0);
        if ((size_t) exponent + 1 == count) written = snprintf(target, left, "%s.0", mantissa);
      } else {
        written = snprintf(target, left, "%.*s.%s", exponent + 1, mantissa, mantissa + exponent + 1);
      }
      (void) written;
    }

    static void fleek_reek_visit(fleek_reek_ast_t *ast, const pm_node_t *node);
    static void fleek_reek_list(fleek_reek_ast_t *ast, const pm_node_list_t *list) {
      for (size_t index = 0; index < list->size; index++) fleek_reek_visit(ast, list->nodes[index]);
    }
    /* Bodies: nothing -> nil, one statement -> itself, more -> (begin ...). */
    static void fleek_reek_body(fleek_reek_ast_t *ast, const pm_node_t *body) {
      if (body == NULL) { fleek_reek_nil(ast); return; }
      if (PM_NODE_TYPE_P(body, PM_STATEMENTS_NODE)) {
        const pm_node_list_t *list = &((const pm_statements_node_t *) body)->body;
        if (list->size == 0) { fleek_reek_nil(ast); return; }
        if (list->size == 1) { fleek_reek_visit(ast, list->nodes[0]); return; }
        fleek_reek_open(ast, "begin", body);
        fleek_reek_list(ast, list);
        fleek_reek_close(ast);
        return;
      }
      fleek_reek_visit(ast, body);
    }
    static void fleek_reek_parameter(fleek_reek_ast_t *ast, const pm_node_t *node);
    static void fleek_reek_parameters(fleek_reek_ast_t *ast, const pm_parameters_node_t *parameters, const pm_node_t *locals_owner) {
      (void) locals_owner;
      if (parameters != NULL && parameters->keyword_rest != NULL && PM_NODE_TYPE_P(parameters->keyword_rest, PM_FORWARDING_PARAMETER_NODE) &&
          parameters->requireds.size == 0 && parameters->optionals.size == 0 && parameters->rest == NULL && parameters->posts.size == 0 &&
          parameters->keywords.size == 0 && parameters->block == NULL) {
        fleek_reek_open(ast, "forward_args", parameters->keyword_rest);
        fleek_reek_close(ast);
        return;
      }
      fleek_reek_open(ast, "args", (const pm_node_t *) parameters);
      if (parameters != NULL) {
        for (size_t index = 0; index < parameters->requireds.size; index++) fleek_reek_parameter(ast, parameters->requireds.nodes[index]);
        for (size_t index = 0; index < parameters->optionals.size; index++) fleek_reek_parameter(ast, parameters->optionals.nodes[index]);
        if (parameters->rest != NULL && !PM_NODE_TYPE_P(parameters->rest, PM_IMPLICIT_REST_NODE)) fleek_reek_parameter(ast, parameters->rest);
        for (size_t index = 0; index < parameters->posts.size; index++) fleek_reek_parameter(ast, parameters->posts.nodes[index]);
        for (size_t index = 0; index < parameters->keywords.size; index++) fleek_reek_parameter(ast, parameters->keywords.nodes[index]);
        if (parameters->keyword_rest != NULL) fleek_reek_parameter(ast, parameters->keyword_rest);
        if (parameters->block != NULL) fleek_reek_parameter(ast, (const pm_node_t *) parameters->block);
      }
      fleek_reek_close(ast);
    }
    static void fleek_reek_named(fleek_reek_ast_t *ast, const char *type, const pm_node_t *node, pm_constant_id_t name) {
      fleek_reek_open(ast, type, node);
      if (name != 0) fleek_reek_symbol(ast, name);
      else if (strcmp(type, "blockarg") == 0) fleek_reek_nil(ast);
      fleek_reek_close(ast);
    }
    static void fleek_reek_parameter(fleek_reek_ast_t *ast, const pm_node_t *node) {
      switch (PM_NODE_TYPE(node)) {
        case PM_REQUIRED_PARAMETER_NODE: fleek_reek_named(ast, "arg", node, ((const pm_required_parameter_node_t *) node)->name); return;
        case PM_OPTIONAL_PARAMETER_NODE: {
          const pm_optional_parameter_node_t *optional = (const pm_optional_parameter_node_t *) node;
          fleek_reek_open(ast, "optarg", node); fleek_reek_symbol(ast, optional->name); fleek_reek_visit(ast, optional->value); fleek_reek_close(ast);
          return;
        }
        case PM_REST_PARAMETER_NODE: fleek_reek_named(ast, "restarg", node, ((const pm_rest_parameter_node_t *) node)->name); return;
        case PM_REQUIRED_KEYWORD_PARAMETER_NODE: fleek_reek_named(ast, "kwarg", node, ((const pm_required_keyword_parameter_node_t *) node)->name); return;
        case PM_OPTIONAL_KEYWORD_PARAMETER_NODE: {
          const pm_optional_keyword_parameter_node_t *optional = (const pm_optional_keyword_parameter_node_t *) node;
          fleek_reek_open(ast, "kwoptarg", node); fleek_reek_symbol(ast, optional->name); fleek_reek_visit(ast, optional->value); fleek_reek_close(ast);
          return;
        }
        case PM_KEYWORD_REST_PARAMETER_NODE: fleek_reek_named(ast, "kwrestarg", node, ((const pm_keyword_rest_parameter_node_t *) node)->name); return;
        case PM_NO_KEYWORDS_PARAMETER_NODE: fleek_reek_open(ast, "kwnilarg", node); fleek_reek_close(ast); return;
        case PM_FORWARDING_PARAMETER_NODE: fleek_reek_open(ast, "forward_arg", node); fleek_reek_close(ast); return;
        case PM_BLOCK_PARAMETER_NODE: fleek_reek_named(ast, "blockarg", node, ((const pm_block_parameter_node_t *) node)->name); return;
        case PM_MULTI_TARGET_NODE: {
          const pm_multi_target_node_t *target = (const pm_multi_target_node_t *) node;
          fleek_reek_open(ast, "mlhs", node);
          for (size_t index = 0; index < target->lefts.size; index++) fleek_reek_parameter(ast, target->lefts.nodes[index]);
          if (target->rest != NULL && PM_NODE_TYPE_P(target->rest, PM_SPLAT_NODE)) {
            const pm_node_t *expression = ((const pm_splat_node_t *) target->rest)->expression;
            fleek_reek_named(ast, "restarg", target->rest, expression == NULL ? 0 : ((const pm_required_parameter_node_t *) expression)->name);
          }
          for (size_t index = 0; index < target->rights.size; index++) fleek_reek_parameter(ast, target->rights.nodes[index]);
          fleek_reek_close(ast);
          return;
        }
        case PM_BLOCK_LOCAL_VARIABLE_NODE: fleek_reek_named(ast, "shadowarg", node, ((const pm_block_local_variable_node_t *) node)->name); return;
        default: fleek_reek_visit(ast, node); return;
      }
    }
    static void fleek_reek_block_parameters(fleek_reek_ast_t *ast, const pm_node_t *parameters, const pm_node_t *at) {
      if (parameters == NULL) { fleek_reek_open(ast, "args", NULL); fleek_reek_close(ast); return; }
      if (!PM_NODE_TYPE_P(parameters, PM_BLOCK_PARAMETERS_NODE)) { fleek_reek_open(ast, "args", NULL); fleek_reek_close(ast); return; }
      const pm_block_parameters_node_t *block = (const pm_block_parameters_node_t *) parameters;
      fleek_reek_open(ast, "args", parameters);
      const pm_parameters_node_t *inner = block->parameters;
      if (inner != NULL) {
        for (size_t index = 0; index < inner->requireds.size; index++) fleek_reek_parameter(ast, inner->requireds.nodes[index]);
        for (size_t index = 0; index < inner->optionals.size; index++) fleek_reek_parameter(ast, inner->optionals.nodes[index]);
        if (inner->rest != NULL && !PM_NODE_TYPE_P(inner->rest, PM_IMPLICIT_REST_NODE)) fleek_reek_parameter(ast, inner->rest);
        for (size_t index = 0; index < inner->posts.size; index++) fleek_reek_parameter(ast, inner->posts.nodes[index]);
        for (size_t index = 0; index < inner->keywords.size; index++) fleek_reek_parameter(ast, inner->keywords.nodes[index]);
        if (inner->keyword_rest != NULL) fleek_reek_parameter(ast, inner->keyword_rest);
        if (inner->block != NULL) fleek_reek_parameter(ast, (const pm_node_t *) inner->block);
      }
      for (size_t index = 0; index < block->locals.size; index++) fleek_reek_parameter(ast, block->locals.nodes[index]);
      fleek_reek_close(ast);
      (void) at;
    }
    /* (block call args body) wrapper for literal blocks; numbered parameters become numblock. */
    static void fleek_reek_with_block(fleek_reek_ast_t *ast, const pm_node_t *at, const pm_node_t *block_node, void (*emit_call)(fleek_reek_ast_t *, const void *), const void *data) {
      if (block_node == NULL || !PM_NODE_TYPE_P(block_node, PM_BLOCK_NODE)) { emit_call(ast, data); return; }
      const pm_block_node_t *block = (const pm_block_node_t *) block_node;
      bool numbered = block->parameters != NULL && PM_NODE_TYPE_P(block->parameters, PM_NUMBERED_PARAMETERS_NODE);
      bool it = block->parameters != NULL && PM_NODE_TYPE_P(block->parameters, PM_IT_PARAMETERS_NODE);
      fleek_reek_open_at(ast, numbered ? "numblock" : it ? "itblock" : "block", at->location.start, at->location.end);
      emit_call(ast, data);
      if (numbered) {
        char count[16]; snprintf(count, sizeof(count), " %d", ((const pm_numbered_parameters_node_t *) block->parameters)->maximum);
        fleek_reek_text(ast, count);
      } else if (it) {
        fleek_reek_text(ast, " :it");
      } else {
        fleek_reek_block_parameters(ast, block->parameters, block_node);
      }
      fleek_reek_body(ast, block->body);
      fleek_reek_close(ast);
    }
    typedef struct { const pm_call_node_t *call; } fleek_reek_call_data_t;
    static void fleek_reek_call_arguments(fleek_reek_ast_t *ast, const pm_arguments_node_t *arguments, const pm_node_t *block) {
      if (arguments != NULL) fleek_reek_list(ast, &arguments->arguments);
      if (block != NULL && PM_NODE_TYPE_P(block, PM_BLOCK_ARGUMENT_NODE)) fleek_reek_visit(ast, block);
    }
    static void fleek_reek_emit_call(fleek_reek_ast_t *ast, const void *data) {
      const pm_call_node_t *call = ((const fleek_reek_call_data_t *) data)->call;
      const pm_node_t *node = (const pm_node_t *) call;
      bool safe = PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION);
      pm_constant_t *name = pm_constant_pool_id_to_constant(&ast->parser->constant_pool, call->name);
      bool not_keyword = name->length == 1 && name->start[0] == '!' && call->message_loc.start != NULL &&
        call->message_loc.end - call->message_loc.start == 3 && memcmp(call->message_loc.start, "not", 3) == 0;
      (void) not_keyword;
      const uint8_t *end = call->block != NULL && PM_NODE_TYPE_P(call->block, PM_BLOCK_NODE) ? (call->closing_loc.end != NULL ? call->closing_loc.end :
        call->arguments != NULL ? call->arguments->base.location.end : call->message_loc.end) : node->location.end;
      if (name->length == 2 && memcmp(name->start, "=~", 2) == 0 && call->receiver != NULL && PM_NODE_TYPE_P(call->receiver, PM_REGULAR_EXPRESSION_NODE) &&
          call->arguments != NULL && call->arguments->arguments.size == 1 && call->block == NULL) {
        fleek_reek_open(ast, "match_with_lvasgn", node);
        fleek_reek_visit(ast, call->receiver); fleek_reek_visit(ast, call->arguments->arguments.nodes[0]);
        fleek_reek_close(ast);
        return;
      }
      if (end == NULL) end = node->location.end;
      fleek_reek_open_at(ast, safe ? "csend" : "send", node->location.start, end);
      if (call->receiver == NULL) fleek_reek_nil(ast); else fleek_reek_visit(ast, call->receiver);
      fleek_reek_symbol(ast, call->name);
      fleek_reek_call_arguments(ast, call->arguments, call->block);
      fleek_reek_close(ast);
    }
    static void fleek_reek_call(fleek_reek_ast_t *ast, const pm_call_node_t *call) {
      fleek_reek_call_data_t data = { call };
      fleek_reek_with_block(ast, (const pm_node_t *) call, call->block, fleek_reek_emit_call, &data);
    }
    typedef struct { const pm_node_t *node; const char *type; const pm_arguments_node_t *arguments; const pm_node_t *block; } fleek_reek_keyword_data_t;
    static void fleek_reek_emit_keyword(fleek_reek_ast_t *ast, const void *data) {
      const fleek_reek_keyword_data_t *keyword = (const fleek_reek_keyword_data_t *) data;
      fleek_reek_open(ast, keyword->type, keyword->node);
      fleek_reek_call_arguments(ast, keyword->arguments, keyword->block);
      fleek_reek_close(ast);
    }
    static void fleek_reek_interpolated(fleek_reek_ast_t *ast, const char *type, const pm_node_t *node, const pm_node_list_t *parts) {
      fleek_reek_open(ast, type, node);
      bool saved = ast->in_parts;
      ast->in_parts = true;
      for (size_t index = 0; index < parts->size; index++) {
        const pm_node_t *part = parts->nodes[index];
        if (PM_NODE_TYPE_P(part, PM_INTERPOLATED_STRING_NODE)) {
          ast->in_parts = false;
          fleek_reek_visit(ast, part);
          ast->in_parts = true;
        } else {
          bool embedded = PM_NODE_TYPE_P(part, PM_EMBEDDED_STATEMENTS_NODE);
          if (embedded) ast->in_parts = false;
          fleek_reek_visit(ast, part);
          ast->in_parts = true;
        }
      }
      ast->in_parts = saved;
      fleek_reek_close(ast);
    }
    static void fleek_reek_regopt(fleek_reek_ast_t *ast, const pm_node_t *node, const uint8_t *closing_start, const uint8_t *closing_end) {
      fleek_reek_open_at(ast, "regopt", closing_start, closing_end);
      static const char order[] = "eimnosux";
      for (size_t flag = 0; flag < sizeof(order) - 1; flag++) {
        for (const uint8_t *cursor = closing_start == NULL ? NULL : closing_start + 1; cursor != NULL && cursor < closing_end; cursor++) {
          if (*cursor == (uint8_t) order[flag]) { char text[4] = { ' ', ':', order[flag], 0 }; fleek_reek_text(ast, text); break; }
        }
      }
      fleek_reek_close(ast);
      (void) node;
    }
    static void fleek_reek_variable(fleek_reek_ast_t *ast, const char *type, const pm_node_t *node, pm_constant_id_t name) {
      fleek_reek_open(ast, type, node); fleek_reek_symbol(ast, name); fleek_reek_close(ast);
    }
    static void fleek_reek_assignment(fleek_reek_ast_t *ast, const char *type, const pm_node_t *node, pm_constant_id_t name, const pm_node_t *value) {
      fleek_reek_open(ast, type, node); fleek_reek_symbol(ast, name);
      if (value != NULL) fleek_reek_visit(ast, value);
      fleek_reek_close(ast);
    }
    /* op-asgn / or-asgn / and-asgn around a target the caller emits. kind: 0 operator, 1 or, 2 and. */
    static void fleek_reek_operator_assignment(fleek_reek_ast_t *ast, const pm_node_t *node, int kind, const char *target_type, pm_constant_id_t name,
        const pm_location_t *target_location, pm_constant_id_t operator, const pm_node_t *value) {
      fleek_reek_open(ast, kind == 0 ? "op_asgn" : kind == 1 ? "or_asgn" : "and_asgn", node);
      fleek_reek_open_at(ast, target_type, target_location->start, target_location->end);
      fleek_reek_symbol(ast, name);
      fleek_reek_close(ast);
      if (kind == 0) {
        pm_constant_t *constant = pm_constant_pool_id_to_constant(&ast->parser->constant_pool, operator);
        fleek_reek_symbol_bytes(ast, constant->start, constant->length);
      }
      fleek_reek_visit(ast, value);
      fleek_reek_close(ast);
    }
    static void fleek_reek_jump(fleek_reek_ast_t *ast, const char *type, const pm_node_t *node, const pm_arguments_node_t *arguments) {
      fleek_reek_open(ast, type, node);
      if (arguments != NULL) fleek_reek_list(ast, &arguments->arguments);
      fleek_reek_close(ast);
    }
    static void fleek_reek_constant_path(fleek_reek_ast_t *ast, const pm_node_t *node, const pm_node_t *parent, pm_constant_id_t name, const char *type) {
      fleek_reek_open(ast, type, node);
      if (parent == NULL) {
        const uint8_t *start = node->location.start;
        fleek_reek_open_at(ast, "cbase", start, start + 2); fleek_reek_close(ast);
      } else {
        fleek_reek_visit(ast, parent);
      }
      fleek_reek_symbol(ast, name);
    }
    static void fleek_reek_call_target(fleek_reek_ast_t *ast, const pm_node_t *node, const pm_node_t *receiver, pm_location_t call_operator, pm_constant_id_t read_name) {
      bool safe = PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION);
      fleek_reek_open(ast, safe ? "csend" : "send", receiver);
      fleek_reek_visit(ast, receiver);
      fleek_reek_symbol(ast, read_name);
      fleek_reek_close(ast);
      (void) call_operator;
    }

    /* Patterns in case/in, `in` and `=>`, using the parser gem's legacy pattern nodes. */
    /* The parser gem lexes a string spanning source lines as one str per line; a standalone literal becomes dstr. */
    static void fleek_reek_string_lines(fleek_reek_ast_t *ast, const pm_node_t *node, const pm_location_t *content, const pm_string_t *value, bool standalone) {
      const uint8_t *bytes = pm_string_source(value);
      size_t length = pm_string_length(value);
      size_t physical = 0, logical = 0;
      for (const uint8_t *cursor = content->start; cursor != NULL && cursor < content->end; cursor++) if (*cursor == '\\n') physical++;
      for (size_t index = 0; index < length; index++) if (bytes[index] == '\\n') logical++;
      size_t segments = physical == 0 ? 1 : (length != 0 && bytes[length - 1] == '\\n' ? physical : physical + 1);
      if (physical != 0 && physical != logical) { ast->failed = true; return; }
      bool compose = standalone && segments > 1;
      if (compose) fleek_reek_open(ast, "dstr", node);
      size_t start = 0;
      const uint8_t *line_start = content->start;
      for (size_t segment = 0; segment < segments; segment++) {
        size_t end = start;
        while (end < length && bytes[end] != '\\n') end++;
        if (end < length) end++;
        const uint8_t *line_end = line_start;
        while (line_end != NULL && line_end < content->end && *line_end != '\\n') line_end++;
        if (line_end != NULL && line_end < content->end) line_end++;
        if (segments == 1) fleek_reek_open(ast, "str", node);
        else fleek_reek_open_at(ast, "str", line_start, line_end);
        fleek_reek_string_atom(ast, bytes + start, end - start);
        fleek_reek_close(ast);
        start = end;
        line_start = line_end;
      }
      if (compose) fleek_reek_close(ast);
    }
    static void fleek_reek_pattern(fleek_reek_ast_t *ast, const pm_node_t *node);
    static void fleek_reek_pattern_list(fleek_reek_ast_t *ast, const pm_node_list_t *list) {
      for (size_t index = 0; index < list->size; index++) fleek_reek_pattern(ast, list->nodes[index]);
    }
    static void fleek_reek_match_rest(fleek_reek_ast_t *ast, const pm_node_t *splat) {
      fleek_reek_open(ast, "match_rest", splat);
      const pm_node_t *expression = PM_NODE_TYPE_P(splat, PM_SPLAT_NODE) ? ((const pm_splat_node_t *) splat)->expression : NULL;
      if (expression != NULL) fleek_reek_pattern(ast, expression);
      fleek_reek_close(ast);
    }
    static void fleek_reek_pattern(fleek_reek_ast_t *ast, const pm_node_t *node) {
      if (node == NULL) { fleek_reek_nil(ast); return; }
      switch (PM_NODE_TYPE(node)) {
        case PM_LOCAL_VARIABLE_TARGET_NODE: fleek_reek_variable(ast, "match_var", node, ((const pm_local_variable_target_node_t *) node)->name); return;
        case PM_HASH_PATTERN_NODE: {
          const pm_hash_pattern_node_t *pattern = (const pm_hash_pattern_node_t *) node;
          if (pattern->constant != NULL) { fleek_reek_open(ast, "const_pattern", node); fleek_reek_visit(ast, pattern->constant); }
          fleek_reek_open(ast, "hash_pattern", node);
          for (size_t index = 0; index < pattern->elements.size; index++) {
            const pm_assoc_node_t *assoc = (const pm_assoc_node_t *) pattern->elements.nodes[index];
            if (PM_NODE_TYPE_P(assoc->value, PM_IMPLICIT_NODE)) {
              const pm_symbol_node_t *key = (const pm_symbol_node_t *) assoc->key;
              fleek_reek_open(ast, "match_var", (const pm_node_t *) assoc);
              fleek_reek_symbol_bytes(ast, pm_string_source(&key->unescaped), pm_string_length(&key->unescaped));
              fleek_reek_close(ast);
            } else {
              fleek_reek_open(ast, "pair", (const pm_node_t *) assoc); fleek_reek_visit(ast, assoc->key); fleek_reek_pattern(ast, assoc->value); fleek_reek_close(ast);
            }
          }
          if (pattern->rest != NULL && PM_NODE_TYPE_P(pattern->rest, PM_ASSOC_SPLAT_NODE)) {
            const pm_node_t *value = ((const pm_assoc_splat_node_t *) pattern->rest)->value;
            fleek_reek_open(ast, "match_rest", pattern->rest); if (value != NULL) fleek_reek_pattern(ast, value); fleek_reek_close(ast);
          } else if (pattern->rest != NULL && PM_NODE_TYPE_P(pattern->rest, PM_NO_KEYWORDS_PARAMETER_NODE)) {
            fleek_reek_open(ast, "match_nil_pattern", pattern->rest); fleek_reek_close(ast);
          }
          fleek_reek_close(ast);
          if (pattern->constant != NULL) fleek_reek_close(ast);
          return;
        }
        case PM_ARRAY_PATTERN_NODE: {
          const pm_array_pattern_node_t *pattern = (const pm_array_pattern_node_t *) node;
          if (pattern->constant != NULL) { fleek_reek_open(ast, "const_pattern", node); fleek_reek_visit(ast, pattern->constant); }
          fleek_reek_open(ast, "array_pattern", node);
          fleek_reek_pattern_list(ast, &pattern->requireds);
          if (pattern->rest != NULL && !PM_NODE_TYPE_P(pattern->rest, PM_IMPLICIT_REST_NODE)) fleek_reek_match_rest(ast, pattern->rest);
          fleek_reek_pattern_list(ast, &pattern->posts);
          fleek_reek_close(ast);
          if (pattern->constant != NULL) fleek_reek_close(ast);
          return;
        }
        case PM_FIND_PATTERN_NODE: {
          const pm_find_pattern_node_t *pattern = (const pm_find_pattern_node_t *) node;
          if (pattern->constant != NULL) { fleek_reek_open(ast, "const_pattern", node); fleek_reek_visit(ast, pattern->constant); }
          fleek_reek_open(ast, "find_pattern", node);
          fleek_reek_match_rest(ast, (const pm_node_t *) pattern->left);
          fleek_reek_pattern_list(ast, &pattern->requireds);
          fleek_reek_match_rest(ast, pattern->right);
          fleek_reek_close(ast);
          if (pattern->constant != NULL) fleek_reek_close(ast);
          return;
        }
        case PM_ALTERNATION_PATTERN_NODE: {
          const pm_alternation_pattern_node_t *pattern = (const pm_alternation_pattern_node_t *) node;
          fleek_reek_open(ast, "match_alt", node); fleek_reek_pattern(ast, pattern->left); fleek_reek_pattern(ast, pattern->right); fleek_reek_close(ast);
          return;
        }
        case PM_CAPTURE_PATTERN_NODE: {
          const pm_capture_pattern_node_t *pattern = (const pm_capture_pattern_node_t *) node;
          fleek_reek_open(ast, "match_as", node); fleek_reek_pattern(ast, pattern->value); fleek_reek_pattern(ast, (const pm_node_t *) pattern->target); fleek_reek_close(ast);
          return;
        }
        case PM_PINNED_VARIABLE_NODE: fleek_reek_open(ast, "pin", node); fleek_reek_visit(ast, ((const pm_pinned_variable_node_t *) node)->variable); fleek_reek_close(ast); return;
        case PM_PINNED_EXPRESSION_NODE: {
          const pm_pinned_expression_node_t *pinned = (const pm_pinned_expression_node_t *) node;
          fleek_reek_open(ast, "pin", node);
          fleek_reek_open_at(ast, "begin", pinned->lparen_loc.start, pinned->rparen_loc.end); fleek_reek_visit(ast, pinned->expression); fleek_reek_close(ast);
          fleek_reek_close(ast);
          return;
        }
        default: fleek_reek_visit(ast, node); return;
      }
    }
    static void fleek_reek_in_clause(fleek_reek_ast_t *ast, const pm_in_node_t *clause) {
      const pm_node_t *pattern = clause->pattern;
      const pm_node_t *guard = NULL;
      const char *guard_type = NULL;
      if ((PM_NODE_TYPE_P(pattern, PM_IF_NODE) || PM_NODE_TYPE_P(pattern, PM_UNLESS_NODE))) {
        bool if_guard = PM_NODE_TYPE_P(pattern, PM_IF_NODE);
        const pm_statements_node_t *statements = if_guard ? ((const pm_if_node_t *) pattern)->statements : ((const pm_unless_node_t *) pattern)->statements;
        if (statements != NULL && statements->body.size == 1) {
          guard = if_guard ? ((const pm_if_node_t *) pattern)->predicate : ((const pm_unless_node_t *) pattern)->predicate;
          guard_type = if_guard ? "if_guard" : "unless_guard";
          pattern = statements->body.nodes[0];
        }
      }
      fleek_reek_open(ast, "in_pattern", (const pm_node_t *) clause);
      fleek_reek_pattern(ast, pattern);
      if (guard != NULL) { fleek_reek_open(ast, guard_type, guard); fleek_reek_visit(ast, guard); fleek_reek_close(ast); }
      else fleek_reek_nil(ast);
      fleek_reek_body(ast, (const pm_node_t *) clause->statements);
      fleek_reek_close(ast);
    }
    static void fleek_reek_visit(fleek_reek_ast_t *ast, const pm_node_t *node) {
      if (node == NULL) { fleek_reek_nil(ast); return; }
      if (ast->failed) return;
      switch (PM_NODE_TYPE(node)) {
        case PM_PROGRAM_NODE: fleek_reek_body(ast, (const pm_node_t *) ((const pm_program_node_t *) node)->statements); return;
        case PM_STATEMENTS_NODE: fleek_reek_body(ast, node); return;
        case PM_NIL_NODE: fleek_reek_open(ast, "nil", node); fleek_reek_close(ast); return;
        case PM_TRUE_NODE: fleek_reek_open(ast, "true", node); fleek_reek_close(ast); return;
        case PM_FALSE_NODE: fleek_reek_open(ast, "false", node); fleek_reek_close(ast); return;
        case PM_SELF_NODE: fleek_reek_open(ast, "self", node); fleek_reek_close(ast); return;
        case PM_REDO_NODE: fleek_reek_open(ast, "redo", node); fleek_reek_close(ast); return;
        case PM_RETRY_NODE: fleek_reek_open(ast, "retry", node); fleek_reek_close(ast); return;
        case PM_INTEGER_NODE: fleek_reek_open(ast, "int", node); fleek_reek_integer(ast, &((const pm_integer_node_t *) node)->value); fleek_reek_close(ast); return;
        case PM_FLOAT_NODE: {
          char text[64]; fleek_reek_float_text(((const pm_float_node_t *) node)->value, text, sizeof(text));
          fleek_reek_open(ast, "float", node); fleek_reek_text(ast, " "); fleek_reek_text(ast, text); fleek_reek_close(ast);
          return;
        }
        case PM_RATIONAL_NODE: {
          const pm_rational_node_t *rational = (const pm_rational_node_t *) node;
          fleek_reek_open(ast, "rational", node); fleek_reek_text(ast, " (");
          fleek_reek_integer_raw(ast, &rational->numerator); fleek_reek_text(ast, "/");
          fleek_reek_integer_raw(ast, &rational->denominator); fleek_reek_text(ast, ")");
          fleek_reek_close(ast);
          return;
        }
        case PM_IMAGINARY_NODE: {
          const pm_node_t *numeric = ((const pm_imaginary_node_t *) node)->numeric;
          fleek_reek_open(ast, "complex", node); fleek_reek_text(ast, " (0+");
          if (PM_NODE_TYPE_P(numeric, PM_INTEGER_NODE)) fleek_reek_integer_raw(ast, &((const pm_integer_node_t *) numeric)->value);
          else if (PM_NODE_TYPE_P(numeric, PM_FLOAT_NODE)) { char text[64]; fleek_reek_float_text(((const pm_float_node_t *) numeric)->value, text, sizeof(text)); fleek_reek_text(ast, text); }
          else { ast->failed = true; return; }
          fleek_reek_text(ast, "i)"); fleek_reek_close(ast);
          return;
        }
        case PM_STRING_NODE: {
          const pm_string_node_t *string = (const pm_string_node_t *) node;
          ast->heredoc_next = !ast->in_parts && string->opening_loc.start != NULL && string->opening_loc.start[0] == '<';
          fleek_reek_string_lines(ast, node, &string->content_loc, &string->unescaped, !ast->in_parts);
          return;
        }
        case PM_X_STRING_NODE: {
          const pm_x_string_node_t *string = (const pm_x_string_node_t *) node;
          fleek_reek_open(ast, "xstr", node);
          fleek_reek_open_at(ast, "str", string->content_loc.start, string->content_loc.end);
          fleek_reek_string_atom(ast, pm_string_source(&string->unescaped), pm_string_length(&string->unescaped));
          fleek_reek_close(ast); fleek_reek_close(ast);
          return;
        }
        case PM_SYMBOL_NODE: {
          const pm_symbol_node_t *symbol = (const pm_symbol_node_t *) node;
          fleek_reek_open(ast, "sym", node);
          fleek_reek_symbol_bytes(ast, pm_string_source(&symbol->unescaped), pm_string_length(&symbol->unescaped));
          fleek_reek_close(ast);
          return;
        }
        case PM_REGULAR_EXPRESSION_NODE: {
          const pm_regular_expression_node_t *regexp = (const pm_regular_expression_node_t *) node;
          fleek_reek_open(ast, "regexp", node);
          if (regexp->content_loc.end > regexp->content_loc.start) {
            fleek_reek_open_at(ast, "str", regexp->content_loc.start, regexp->content_loc.end);
            fleek_reek_string_atom(ast, regexp->content_loc.start, (size_t) (regexp->content_loc.end - regexp->content_loc.start));
            fleek_reek_close(ast);
          }
          fleek_reek_regopt(ast, node, regexp->closing_loc.start, regexp->closing_loc.end);
          fleek_reek_close(ast);
          return;
        }
        case PM_INTERPOLATED_REGULAR_EXPRESSION_NODE: {
          const pm_interpolated_regular_expression_node_t *regexp = (const pm_interpolated_regular_expression_node_t *) node;
          fleek_reek_open(ast, "regexp", node);
          fleek_reek_list(ast, &regexp->parts);
          fleek_reek_regopt(ast, node, regexp->closing_loc.start, regexp->closing_loc.end);
          fleek_reek_close(ast);
          return;
        }
        case PM_INTERPOLATED_STRING_NODE: {
          const pm_interpolated_string_node_t *string = (const pm_interpolated_string_node_t *) node;
          ast->heredoc_next = string->opening_loc.start != NULL && string->opening_loc.start[0] == '<';
          fleek_reek_interpolated(ast, "dstr", node, &string->parts);
          return;
        }
        case PM_INTERPOLATED_SYMBOL_NODE: fleek_reek_interpolated(ast, "dsym", node, &((const pm_interpolated_symbol_node_t *) node)->parts); return;
        case PM_INTERPOLATED_X_STRING_NODE: fleek_reek_interpolated(ast, "xstr", node, &((const pm_interpolated_x_string_node_t *) node)->parts); return;
        case PM_EMBEDDED_STATEMENTS_NODE: {
          const pm_embedded_statements_node_t *embedded = (const pm_embedded_statements_node_t *) node;
          fleek_reek_open(ast, "begin", node);
          if (embedded->statements != NULL) fleek_reek_list(ast, &embedded->statements->body);
          fleek_reek_close(ast);
          return;
        }
        case PM_EMBEDDED_VARIABLE_NODE: fleek_reek_visit(ast, ((const pm_embedded_variable_node_t *) node)->variable); return;
        case PM_ARRAY_NODE: fleek_reek_open(ast, "array", node); fleek_reek_list(ast, &((const pm_array_node_t *) node)->elements); fleek_reek_close(ast); return;
        case PM_HASH_NODE: case PM_KEYWORD_HASH_NODE: {
          const pm_node_list_t *elements = PM_NODE_TYPE_P(node, PM_HASH_NODE) ? &((const pm_hash_node_t *) node)->elements : &((const pm_keyword_hash_node_t *) node)->elements;
          fleek_reek_open(ast, "hash", node); fleek_reek_list(ast, elements); fleek_reek_close(ast);
          return;
        }
        case PM_ASSOC_NODE: {
          const pm_assoc_node_t *assoc = (const pm_assoc_node_t *) node;
          fleek_reek_open(ast, "pair", node); fleek_reek_visit(ast, assoc->key);
          if (PM_NODE_TYPE_P(assoc->value, PM_IMPLICIT_NODE)) fleek_reek_visit(ast, ((const pm_implicit_node_t *) assoc->value)->value);
          else fleek_reek_visit(ast, assoc->value);
          fleek_reek_close(ast);
          return;
        }
        case PM_ASSOC_SPLAT_NODE: {
          const pm_node_t *value = ((const pm_assoc_splat_node_t *) node)->value;
          fleek_reek_open(ast, "kwsplat", node); if (value != NULL) fleek_reek_visit(ast, value); fleek_reek_close(ast);
          return;
        }
        case PM_SPLAT_NODE: {
          const pm_node_t *expression = ((const pm_splat_node_t *) node)->expression;
          fleek_reek_open(ast, "splat", node); if (expression != NULL) fleek_reek_visit(ast, expression); fleek_reek_close(ast);
          return;
        }
        case PM_BLOCK_ARGUMENT_NODE: {
          const pm_node_t *expression = ((const pm_block_argument_node_t *) node)->expression;
          fleek_reek_open(ast, "block_pass", node); fleek_reek_visit(ast, expression); fleek_reek_close(ast);
          return;
        }
        case PM_RANGE_NODE: case PM_FLIP_FLOP_NODE: {
          const pm_range_node_t *range = (const pm_range_node_t *) node;
          bool exclude = PM_NODE_FLAG_P(node, PM_RANGE_FLAGS_EXCLUDE_END);
          bool flip = PM_NODE_TYPE_P(node, PM_FLIP_FLOP_NODE);
          fleek_reek_open(ast, flip ? (exclude ? "eflipflop" : "iflipflop") : (exclude ? "erange" : "irange"), node);
          fleek_reek_visit(ast, range->left); fleek_reek_visit(ast, range->right);
          fleek_reek_close(ast);
          return;
        }
        case PM_LOCAL_VARIABLE_READ_NODE: fleek_reek_variable(ast, "lvar", node, ((const pm_local_variable_read_node_t *) node)->name); return;
        case PM_INSTANCE_VARIABLE_READ_NODE: fleek_reek_variable(ast, "ivar", node, ((const pm_instance_variable_read_node_t *) node)->name); return;
        case PM_GLOBAL_VARIABLE_READ_NODE: fleek_reek_variable(ast, "gvar", node, ((const pm_global_variable_read_node_t *) node)->name); return;
        case PM_CLASS_VARIABLE_READ_NODE: fleek_reek_variable(ast, "cvar", node, ((const pm_class_variable_read_node_t *) node)->name); return;
        case PM_BACK_REFERENCE_READ_NODE: fleek_reek_variable(ast, "back_ref", node, ((const pm_back_reference_read_node_t *) node)->name); return;
        case PM_NUMBERED_REFERENCE_READ_NODE: {
          char text[16]; snprintf(text, sizeof(text), " %u", ((const pm_numbered_reference_read_node_t *) node)->number);
          fleek_reek_open(ast, "nth_ref", node); fleek_reek_text(ast, text); fleek_reek_close(ast);
          return;
        }
        case PM_IT_LOCAL_VARIABLE_READ_NODE: fleek_reek_open(ast, "lvar", node); fleek_reek_text(ast, " :it"); fleek_reek_close(ast); return;
        case PM_LOCAL_VARIABLE_WRITE_NODE: fleek_reek_assignment(ast, "lvasgn", node, ((const pm_local_variable_write_node_t *) node)->name, ((const pm_local_variable_write_node_t *) node)->value); return;
        case PM_INSTANCE_VARIABLE_WRITE_NODE: fleek_reek_assignment(ast, "ivasgn", node, ((const pm_instance_variable_write_node_t *) node)->name, ((const pm_instance_variable_write_node_t *) node)->value); return;
        case PM_GLOBAL_VARIABLE_WRITE_NODE: fleek_reek_assignment(ast, "gvasgn", node, ((const pm_global_variable_write_node_t *) node)->name, ((const pm_global_variable_write_node_t *) node)->value); return;
        case PM_CLASS_VARIABLE_WRITE_NODE: fleek_reek_assignment(ast, "cvasgn", node, ((const pm_class_variable_write_node_t *) node)->name, ((const pm_class_variable_write_node_t *) node)->value); return;
        case PM_LOCAL_VARIABLE_TARGET_NODE: fleek_reek_assignment(ast, "lvasgn", node, ((const pm_local_variable_target_node_t *) node)->name, NULL); return;
        case PM_INSTANCE_VARIABLE_TARGET_NODE: fleek_reek_assignment(ast, "ivasgn", node, ((const pm_instance_variable_target_node_t *) node)->name, NULL); return;
        case PM_GLOBAL_VARIABLE_TARGET_NODE: fleek_reek_assignment(ast, "gvasgn", node, ((const pm_global_variable_target_node_t *) node)->name, NULL); return;
        case PM_CLASS_VARIABLE_TARGET_NODE: fleek_reek_assignment(ast, "cvasgn", node, ((const pm_class_variable_target_node_t *) node)->name, NULL); return;
        #define FLEEK_REEK_OPERATOR_WRITES(PREFIX, STRUCT, TYPE) \\
          case PM_##PREFIX##_OPERATOR_WRITE_NODE: { const pm_##STRUCT##_operator_write_node_t *write = (const void *) node; \\
            fleek_reek_operator_assignment(ast, node, 0, TYPE, write->name, &write->name_loc, write->binary_operator, write->value); return; } \\
          case PM_##PREFIX##_OR_WRITE_NODE: { const pm_##STRUCT##_or_write_node_t *write = (const void *) node; \\
            fleek_reek_operator_assignment(ast, node, 1, TYPE, write->name, &write->name_loc, 0, write->value); return; } \\
          case PM_##PREFIX##_AND_WRITE_NODE: { const pm_##STRUCT##_and_write_node_t *write = (const void *) node; \\
            fleek_reek_operator_assignment(ast, node, 2, TYPE, write->name, &write->name_loc, 0, write->value); return; }
        FLEEK_REEK_OPERATOR_WRITES(LOCAL_VARIABLE, local_variable, "lvasgn")
        FLEEK_REEK_OPERATOR_WRITES(INSTANCE_VARIABLE, instance_variable, "ivasgn")
        FLEEK_REEK_OPERATOR_WRITES(GLOBAL_VARIABLE, global_variable, "gvasgn")
        FLEEK_REEK_OPERATOR_WRITES(CLASS_VARIABLE, class_variable, "cvasgn")
        case PM_CONSTANT_OPERATOR_WRITE_NODE: case PM_CONSTANT_OR_WRITE_NODE: case PM_CONSTANT_AND_WRITE_NODE: {
          const pm_constant_operator_write_node_t *write = (const pm_constant_operator_write_node_t *) node;
          int kind = PM_NODE_TYPE_P(node, PM_CONSTANT_OPERATOR_WRITE_NODE) ? 0 : PM_NODE_TYPE_P(node, PM_CONSTANT_OR_WRITE_NODE) ? 1 : 2;
          fleek_reek_open(ast, kind == 0 ? "op_asgn" : kind == 1 ? "or_asgn" : "and_asgn", node);
          fleek_reek_open_at(ast, "casgn", write->name_loc.start, write->name_loc.end); fleek_reek_nil(ast); fleek_reek_symbol(ast, write->name); fleek_reek_close(ast);
          if (kind == 0) fleek_reek_symbol(ast, write->binary_operator);
          fleek_reek_visit(ast, kind == 0 ? write->value : ((const pm_constant_or_write_node_t *) node)->value);
          fleek_reek_close(ast);
          return;
        }
        case PM_CONSTANT_READ_NODE: fleek_reek_open(ast, "const", node); fleek_reek_nil(ast); fleek_reek_symbol(ast, ((const pm_constant_read_node_t *) node)->name); fleek_reek_close(ast); return;
        case PM_CONSTANT_TARGET_NODE: fleek_reek_open(ast, "casgn", node); fleek_reek_nil(ast); fleek_reek_symbol(ast, ((const pm_constant_target_node_t *) node)->name); fleek_reek_close(ast); return;
        case PM_CONSTANT_WRITE_NODE: {
          const pm_constant_write_node_t *write = (const pm_constant_write_node_t *) node;
          fleek_reek_open(ast, "casgn", node); fleek_reek_nil(ast); fleek_reek_symbol(ast, write->name); fleek_reek_visit(ast, write->value); fleek_reek_close(ast);
          return;
        }
        case PM_CONSTANT_PATH_NODE: {
          const pm_constant_path_node_t *path = (const pm_constant_path_node_t *) node;
          fleek_reek_constant_path(ast, node, path->parent, path->name, "const"); fleek_reek_close(ast);
          return;
        }
        case PM_CONSTANT_PATH_TARGET_NODE: {
          const pm_constant_path_target_node_t *path = (const pm_constant_path_target_node_t *) node;
          fleek_reek_constant_path(ast, node, path->parent, path->name, "casgn"); fleek_reek_close(ast);
          return;
        }
        case PM_CONSTANT_PATH_WRITE_NODE: {
          const pm_constant_path_write_node_t *write = (const pm_constant_path_write_node_t *) node;
          fleek_reek_constant_path(ast, node, write->target->parent, write->target->name, "casgn");
          fleek_reek_visit(ast, write->value); fleek_reek_close(ast);
          return;
        }
        case PM_CONSTANT_PATH_OPERATOR_WRITE_NODE: case PM_CONSTANT_PATH_OR_WRITE_NODE: case PM_CONSTANT_PATH_AND_WRITE_NODE: {
          const pm_constant_path_or_write_node_t *write = (const pm_constant_path_or_write_node_t *) node;
          int kind = PM_NODE_TYPE_P(node, PM_CONSTANT_PATH_OPERATOR_WRITE_NODE) ? 0 : PM_NODE_TYPE_P(node, PM_CONSTANT_PATH_OR_WRITE_NODE) ? 1 : 2;
          fleek_reek_open(ast, kind == 0 ? "op_asgn" : kind == 1 ? "or_asgn" : "and_asgn", node);
          fleek_reek_constant_path(ast, (const pm_node_t *) write->target, write->target->parent, write->target->name, "casgn"); fleek_reek_close(ast);
          if (kind == 0) fleek_reek_symbol(ast, ((const pm_constant_path_operator_write_node_t *) node)->binary_operator);
          fleek_reek_visit(ast, kind == 0 ? ((const pm_constant_path_operator_write_node_t *) node)->value : write->value);
          fleek_reek_close(ast);
          return;
        }
        case PM_CALL_NODE: fleek_reek_call(ast, (const pm_call_node_t *) node); return;
        case PM_CALL_OPERATOR_WRITE_NODE: case PM_CALL_OR_WRITE_NODE: case PM_CALL_AND_WRITE_NODE: {
          const pm_call_operator_write_node_t *write = (const pm_call_operator_write_node_t *) node;
          int kind = PM_NODE_TYPE_P(node, PM_CALL_OPERATOR_WRITE_NODE) ? 0 : PM_NODE_TYPE_P(node, PM_CALL_OR_WRITE_NODE) ? 1 : 2;
          fleek_reek_open(ast, kind == 0 ? "op_asgn" : kind == 1 ? "or_asgn" : "and_asgn", node);
          fleek_reek_call_target(ast, node, write->receiver, write->call_operator_loc, write->read_name);
          if (kind == 0) fleek_reek_symbol(ast, write->binary_operator);
          fleek_reek_visit(ast, kind == 0 ? write->value : ((const pm_call_or_write_node_t *) node)->value);
          fleek_reek_close(ast);
          return;
        }
        case PM_INDEX_OPERATOR_WRITE_NODE: case PM_INDEX_OR_WRITE_NODE: case PM_INDEX_AND_WRITE_NODE: {
          const pm_index_operator_write_node_t *write = (const pm_index_operator_write_node_t *) node;
          int kind = PM_NODE_TYPE_P(node, PM_INDEX_OPERATOR_WRITE_NODE) ? 0 : PM_NODE_TYPE_P(node, PM_INDEX_OR_WRITE_NODE) ? 1 : 2;
          fleek_reek_open(ast, kind == 0 ? "op_asgn" : kind == 1 ? "or_asgn" : "and_asgn", node);
          fleek_reek_open_at(ast, "send", write->receiver->location.start, write->closing_loc.end);
          fleek_reek_visit(ast, write->receiver); fleek_reek_text(ast, " :[]");
          fleek_reek_call_arguments(ast, write->arguments, (const pm_node_t *) write->block);
          fleek_reek_close(ast);
          if (kind == 0) fleek_reek_symbol(ast, write->binary_operator);
          fleek_reek_visit(ast, kind == 0 ? write->value : ((const pm_index_or_write_node_t *) node)->value);
          fleek_reek_close(ast);
          return;
        }
        case PM_CALL_TARGET_NODE: {
          const pm_call_target_node_t *target = (const pm_call_target_node_t *) node;
          fleek_reek_open(ast, PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION) ? "csend" : "send", node);
          fleek_reek_visit(ast, target->receiver); fleek_reek_symbol(ast, target->name); fleek_reek_close(ast);
          return;
        }
        case PM_INDEX_TARGET_NODE: {
          const pm_index_target_node_t *target = (const pm_index_target_node_t *) node;
          fleek_reek_open(ast, "send", node); fleek_reek_visit(ast, target->receiver); fleek_reek_text(ast, " :[]=");
          fleek_reek_call_arguments(ast, target->arguments, (const pm_node_t *) target->block); fleek_reek_close(ast);
          return;
        }
        case PM_MULTI_TARGET_NODE: case PM_MULTI_WRITE_NODE: {
          bool write = PM_NODE_TYPE_P(node, PM_MULTI_WRITE_NODE);
          const pm_node_list_t *lefts = write ? &((const pm_multi_write_node_t *) node)->lefts : &((const pm_multi_target_node_t *) node)->lefts;
          const pm_node_t *rest = write ? ((const pm_multi_write_node_t *) node)->rest : ((const pm_multi_target_node_t *) node)->rest;
          const pm_node_list_t *rights = write ? &((const pm_multi_write_node_t *) node)->rights : &((const pm_multi_target_node_t *) node)->rights;
          if (write) fleek_reek_open(ast, "masgn", node);
          const uint8_t *mlhs_start = lefts->size != 0 ? lefts->nodes[0]->location.start : rest != NULL ? rest->location.start : node->location.start;
          fleek_reek_open_at(ast, "mlhs", write ? mlhs_start : node->location.start, node->location.end);
          fleek_reek_list(ast, lefts);
          if (rest != NULL && !PM_NODE_TYPE_P(rest, PM_IMPLICIT_REST_NODE)) fleek_reek_visit(ast, rest);
          fleek_reek_list(ast, rights);
          fleek_reek_close(ast);
          if (write) { fleek_reek_visit(ast, ((const pm_multi_write_node_t *) node)->value); fleek_reek_close(ast); }
          return;
        }
        case PM_AND_NODE: fleek_reek_open(ast, "and", node); fleek_reek_visit(ast, ((const pm_and_node_t *) node)->left); fleek_reek_visit(ast, ((const pm_and_node_t *) node)->right); fleek_reek_close(ast); return;
        case PM_OR_NODE: fleek_reek_open(ast, "or", node); fleek_reek_visit(ast, ((const pm_or_node_t *) node)->left); fleek_reek_visit(ast, ((const pm_or_node_t *) node)->right); fleek_reek_close(ast); return;
        case PM_PARENTHESES_NODE: {
          const pm_node_t *body = ((const pm_parentheses_node_t *) node)->body;
          fleek_reek_open(ast, "begin", node);
          if (body != NULL && PM_NODE_TYPE_P(body, PM_STATEMENTS_NODE)) fleek_reek_list(ast, &((const pm_statements_node_t *) body)->body);
          else if (body != NULL) fleek_reek_visit(ast, body);
          fleek_reek_close(ast);
          return;
        }
        case PM_IF_NODE: {
          const pm_if_node_t *branch = (const pm_if_node_t *) node;
          fleek_reek_open(ast, "if", node); fleek_reek_visit(ast, branch->predicate);
          fleek_reek_body(ast, (const pm_node_t *) branch->statements);
          const pm_node_t *subsequent = branch->subsequent;
          if (subsequent != NULL && PM_NODE_TYPE_P(subsequent, PM_ELSE_NODE)) fleek_reek_body(ast, (const pm_node_t *) ((const pm_else_node_t *) subsequent)->statements);
          else fleek_reek_visit(ast, subsequent);
          fleek_reek_close(ast);
          return;
        }
        case PM_UNLESS_NODE: {
          const pm_unless_node_t *branch = (const pm_unless_node_t *) node;
          fleek_reek_open(ast, "if", node); fleek_reek_visit(ast, branch->predicate);
          fleek_reek_body(ast, branch->else_clause == NULL ? NULL : (const pm_node_t *) branch->else_clause->statements);
          fleek_reek_body(ast, (const pm_node_t *) branch->statements);
          fleek_reek_close(ast);
          return;
        }
        case PM_WHILE_NODE: case PM_UNTIL_NODE: {
          const pm_while_node_t *loop = (const pm_while_node_t *) node;
          bool post = PM_NODE_FLAG_P(node, PM_LOOP_FLAGS_BEGIN_MODIFIER);
          const char *type = PM_NODE_TYPE_P(node, PM_WHILE_NODE) ? (post ? "while_post" : "while") : (post ? "until_post" : "until");
          fleek_reek_open(ast, type, node); fleek_reek_visit(ast, loop->predicate);
          fleek_reek_body(ast, (const pm_node_t *) loop->statements);
          fleek_reek_close(ast);
          return;
        }
        case PM_FOR_NODE: {
          const pm_for_node_t *loop = (const pm_for_node_t *) node;
          fleek_reek_open(ast, "for", node); fleek_reek_visit(ast, loop->index); fleek_reek_visit(ast, loop->collection);
          fleek_reek_body(ast, (const pm_node_t *) loop->statements); fleek_reek_close(ast);
          return;
        }
        case PM_CASE_NODE: case PM_CASE_MATCH_NODE: {
          const pm_case_node_t *branch = (const pm_case_node_t *) node;
          fleek_reek_open(ast, PM_NODE_TYPE_P(node, PM_CASE_NODE) ? "case" : "case_match", node);
          fleek_reek_visit(ast, branch->predicate); fleek_reek_list(ast, &branch->conditions);
          fleek_reek_body(ast, branch->else_clause == NULL ? NULL : (const pm_node_t *) branch->else_clause->statements);
          fleek_reek_close(ast);
          return;
        }
        case PM_WHEN_NODE: {
          const pm_when_node_t *clause = (const pm_when_node_t *) node;
          fleek_reek_open(ast, "when", node); fleek_reek_list(ast, &clause->conditions);
          fleek_reek_body(ast, (const pm_node_t *) clause->statements); fleek_reek_close(ast);
          return;
        }
        case PM_RETURN_NODE: fleek_reek_jump(ast, "return", node, ((const pm_return_node_t *) node)->arguments); return;
        case PM_BREAK_NODE: fleek_reek_jump(ast, "break", node, ((const pm_break_node_t *) node)->arguments); return;
        case PM_NEXT_NODE: fleek_reek_jump(ast, "next", node, ((const pm_next_node_t *) node)->arguments); return;
        case PM_YIELD_NODE: fleek_reek_jump(ast, "yield", node, ((const pm_yield_node_t *) node)->arguments); return;
        case PM_SUPER_NODE: {
          const pm_super_node_t *call = (const pm_super_node_t *) node;
          fleek_reek_keyword_data_t data = { node, "super", call->arguments, call->block };
          fleek_reek_with_block(ast, node, call->block, fleek_reek_emit_keyword, &data);
          return;
        }
        case PM_FORWARDING_SUPER_NODE: {
          const pm_forwarding_super_node_t *call = (const pm_forwarding_super_node_t *) node;
          fleek_reek_keyword_data_t data = { node, "zsuper", NULL, NULL };
          fleek_reek_with_block(ast, node, (const pm_node_t *) call->block, fleek_reek_emit_keyword, &data);
          return;
        }
        case PM_FORWARDING_ARGUMENTS_NODE: fleek_reek_open(ast, "forwarded_args", node); fleek_reek_close(ast); return;
        case PM_DEFINED_NODE: fleek_reek_open(ast, "defined?", node); fleek_reek_visit(ast, ((const pm_defined_node_t *) node)->value); fleek_reek_close(ast); return;
        case PM_ALIAS_METHOD_NODE: case PM_ALIAS_GLOBAL_VARIABLE_NODE: {
          const pm_alias_method_node_t *alias = (const pm_alias_method_node_t *) node;
          fleek_reek_open(ast, "alias", node); fleek_reek_visit(ast, alias->new_name); fleek_reek_visit(ast, alias->old_name); fleek_reek_close(ast);
          return;
        }
        case PM_UNDEF_NODE: fleek_reek_open(ast, "undef", node); fleek_reek_list(ast, &((const pm_undef_node_t *) node)->names); fleek_reek_close(ast); return;
        case PM_LAMBDA_NODE: {
          const pm_lambda_node_t *lambda = (const pm_lambda_node_t *) node;
          bool numbered = lambda->parameters != NULL && PM_NODE_TYPE_P(lambda->parameters, PM_NUMBERED_PARAMETERS_NODE);
          fleek_reek_open(ast, numbered ? "numblock" : "block", node);
          fleek_reek_open_at(ast, "lambda", lambda->operator_loc.start, lambda->operator_loc.end); fleek_reek_close(ast);
          if (numbered) { char count[16]; snprintf(count, sizeof(count), " %d", ((const pm_numbered_parameters_node_t *) lambda->parameters)->maximum); fleek_reek_text(ast, count); }
          else fleek_reek_block_parameters(ast, lambda->parameters, node);
          fleek_reek_body(ast, lambda->body);
          fleek_reek_close(ast);
          return;
        }
        case PM_CLASS_NODE: {
          const pm_class_node_t *scope = (const pm_class_node_t *) node;
          fleek_reek_open(ast, "class", node); fleek_reek_visit(ast, scope->constant_path); fleek_reek_visit(ast, scope->superclass);
          fleek_reek_body(ast, scope->body); fleek_reek_close(ast);
          return;
        }
        case PM_MODULE_NODE: {
          const pm_module_node_t *scope = (const pm_module_node_t *) node;
          fleek_reek_open(ast, "module", node); fleek_reek_visit(ast, scope->constant_path); fleek_reek_body(ast, scope->body); fleek_reek_close(ast);
          return;
        }
        case PM_SINGLETON_CLASS_NODE: {
          const pm_singleton_class_node_t *scope = (const pm_singleton_class_node_t *) node;
          fleek_reek_open(ast, "sclass", node); fleek_reek_visit(ast, scope->expression); fleek_reek_body(ast, scope->body); fleek_reek_close(ast);
          return;
        }
        case PM_DEF_NODE: {
          const pm_def_node_t *method = (const pm_def_node_t *) node;
          fleek_reek_open(ast, method->receiver == NULL ? "def" : "defs", node);
          if (method->receiver != NULL) fleek_reek_visit(ast, method->receiver);
          fleek_reek_symbol(ast, method->name);
          fleek_reek_parameters(ast, method->parameters, node);
          fleek_reek_body(ast, method->body);
          fleek_reek_close(ast);
          return;
        }
        case PM_BEGIN_NODE: {
          const pm_begin_node_t *begin = (const pm_begin_node_t *) node;
          bool keyword = begin->begin_keyword_loc.start != NULL;
          if (keyword) fleek_reek_open(ast, "kwbegin", node);
          bool ensure = begin->ensure_clause != NULL;
          if (ensure) fleek_reek_open(ast, "ensure", node);
          bool rescue = begin->rescue_clause != NULL;
          if (rescue) {
            fleek_reek_open(ast, "rescue", node);
            fleek_reek_body(ast, (const pm_node_t *) begin->statements);
            for (const pm_rescue_node_t *clause = begin->rescue_clause; clause != NULL; clause = clause->subsequent) fleek_reek_visit(ast, (const pm_node_t *) clause);
            fleek_reek_body(ast, begin->else_clause == NULL ? NULL : (const pm_node_t *) begin->else_clause->statements);
            fleek_reek_close(ast);
          } else if (keyword && !ensure && begin->statements != NULL) {
            fleek_reek_list(ast, &begin->statements->body);
          } else if (!keyword || ensure) {
            fleek_reek_body(ast, (const pm_node_t *) begin->statements);
          }
          if (ensure) { fleek_reek_body(ast, (const pm_node_t *) begin->ensure_clause->statements); fleek_reek_close(ast); }
          if (keyword) fleek_reek_close(ast);
          return;
        }
        case PM_RESCUE_NODE: {
          const pm_rescue_node_t *clause = (const pm_rescue_node_t *) node;
          fleek_reek_open(ast, "resbody", node);
          if (clause->exceptions.size == 0) fleek_reek_nil(ast);
          else { fleek_reek_open(ast, "array", clause->exceptions.nodes[0]); fleek_reek_list(ast, &clause->exceptions); fleek_reek_close(ast); }
          fleek_reek_visit(ast, clause->reference);
          fleek_reek_body(ast, (const pm_node_t *) clause->statements);
          fleek_reek_close(ast);
          return;
        }
        case PM_RESCUE_MODIFIER_NODE: {
          const pm_rescue_modifier_node_t *rescue = (const pm_rescue_modifier_node_t *) node;
          fleek_reek_open(ast, "rescue", node); fleek_reek_visit(ast, rescue->expression);
          fleek_reek_open(ast, "resbody", rescue->rescue_expression); fleek_reek_nil(ast); fleek_reek_nil(ast); fleek_reek_visit(ast, rescue->rescue_expression); fleek_reek_close(ast);
          fleek_reek_nil(ast); fleek_reek_close(ast);
          return;
        }
        case PM_SOURCE_FILE_NODE: {
          fleek_reek_open(ast, "str", node);
          fleek_reek_string_atom(ast, (const uint8_t *) ast->path, ast->path_length);
          fleek_reek_close(ast);
          return;
        }
        case PM_SOURCE_LINE_NODE: {
          char text[24]; snprintf(text, sizeof(text), " %d", (int) (fleek_reek_line(ast, node->location.start) - ast->start_line + 1));
          fleek_reek_open(ast, "int", node); fleek_reek_text(ast, text); fleek_reek_close(ast);
          return;
        }
        case PM_SOURCE_ENCODING_NODE:
          fleek_reek_open(ast, "const", node); fleek_reek_open(ast, "const", node); fleek_reek_nil(ast); fleek_reek_text(ast, " :Encoding"); fleek_reek_close(ast);
          fleek_reek_text(ast, " :UTF_8"); fleek_reek_close(ast);
          return;
        case PM_SHAREABLE_CONSTANT_NODE: fleek_reek_visit(ast, ((const pm_shareable_constant_node_t *) node)->write); return;
        case PM_PRE_EXECUTION_NODE: fleek_reek_open(ast, "preexe", node); fleek_reek_body(ast, (const pm_node_t *) ((const pm_pre_execution_node_t *) node)->statements); fleek_reek_close(ast); return;
        case PM_POST_EXECUTION_NODE: fleek_reek_open(ast, "postexe", node); fleek_reek_body(ast, (const pm_node_t *) ((const pm_post_execution_node_t *) node)->statements); fleek_reek_close(ast); return;
        case PM_IN_NODE: fleek_reek_in_clause(ast, (const pm_in_node_t *) node); return;
        case PM_MATCH_PREDICATE_NODE: case PM_MATCH_REQUIRED_NODE: {
          const pm_match_predicate_node_t *match = (const pm_match_predicate_node_t *) node;
          fleek_reek_open(ast, PM_NODE_TYPE_P(node, PM_MATCH_PREDICATE_NODE) ? "match_pattern_p" : "match_pattern", node);
          fleek_reek_visit(ast, match->value); fleek_reek_pattern(ast, match->pattern); fleek_reek_close(ast);
          return;
        }
        case PM_MATCH_WRITE_NODE: {
          const pm_call_node_t *call = ((const pm_match_write_node_t *) node)->call;
          fleek_reek_open(ast, "match_with_lvasgn", node); fleek_reek_visit(ast, call->receiver);
          if (call->arguments != NULL) fleek_reek_list(ast, &call->arguments->arguments);
          fleek_reek_close(ast);
          return;
        }
        default:
          fprintf(stderr, "REEKDEBUG %s\\n", pm_node_type_to_str(PM_NODE_TYPE(node)));
          ast->failed = true;
          return;
      }
    }

    /* Translates source into Reek's AST text. annotate adds "@line:begin:end" after each node type. */
    int fleek_reek_ast(const char *source, size_t length, const char *path, int annotate) {
      free(fleek_reek_ast_buffer);
      fleek_reek_ast_buffer = NULL;
      free(fleek_reek_comments_buffer);
      fleek_reek_comments_buffer = NULL;
      if (memchr(source, 0, length) != NULL) return -2;
      pm_options_t options = {0};
      options.line = 1;
      options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      options.partial_script = true;
      pm_parser_t parser;
      pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_node_t *root = pm_parse(&parser);
      int result = -1;
      if (parser.error_list.head == NULL) {
        fleek_reek_ast_t ast = { NULL, 0, 0, false, annotate != 0, false, false, &parser, (const uint8_t *) source, path, strlen(path), 1 };
        const pm_statements_node_t *statements = ((const pm_program_node_t *) root)->statements;
        if (statements != NULL && statements->body.size != 0) fleek_reek_visit(&ast, root);
        if (!ast.failed) {
          fleek_reek_ast_t comments = { NULL, 0, 0, false, false, false, false, &parser, (const uint8_t *) source, path, 0, 1 };
          fleek_reek_text(&comments, "");
          for (pm_list_node_t *item = parser.comment_list.head; item != NULL; item = item->next) {
            const pm_comment_t *comment = (const pm_comment_t *) item;
            char record[64];
            int written = snprintf(record, sizeof(record), "%ld\\t%ld\\n", (long) (comment->location.start - (const uint8_t *) source), (long) (comment->location.end - (const uint8_t *) source));
            fleek_reek_emit(&comments, record, (size_t) written);
          }
          fleek_reek_comments_buffer = comments.text;
        }
        if (!ast.failed) { fleek_reek_ast_buffer = ast.text; result = 0; }
        else { free(ast.text); result = -4; }
      }
      pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
      return result;
    }
    const char *fleek_reek_ast_text(void) { return fleek_reek_ast_buffer == NULL ? "" : fleek_reek_ast_buffer; }
    const char *fleek_reek_comments_text(void) { return fleek_reek_comments_buffer == NULL ? "" : fleek_reek_comments_buffer; }

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
    ffi_func :fleek_reek_ast, [:str, :size_t, :str, :int], :int
    ffi_func :fleek_reek_ast_text, [], :str
    ffi_func :fleek_reek_comments_text, [], :str
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
    ffi_func :fleek_long_parameter_list, [:str, :size_t, :size_t, :size_t], :int
    ffi_func :fleek_long_parameter_list_finding, [], :str
    ffi_func :fleek_boolean_parameter, [:str, :size_t], :int
    ffi_func :fleek_boolean_parameter_finding, [], :str
    ffi_func :fleek_long_yield_list, [:str, :size_t, :size_t], :int
    ffi_func :fleek_long_yield_list_finding, [], :str
    ffi_func :fleek_unused_parameters, [:str, :size_t], :int
    ffi_func :fleek_unused_parameters_finding, [], :str
    ffi_func :fleek_unused_private_method, [:str, :size_t], :int
    ffi_func :fleek_unused_private_method_finding, [], :str
    ffi_func :fleek_manual_dispatch, [:str, :size_t], :int
    ffi_func :fleek_manual_dispatch_finding, [], :str
    ffi_func :fleek_missing_safe_method, [:str, :size_t], :int
    ffi_func :fleek_missing_safe_method_finding, [], :str
    ffi_func :fleek_repeated_conditional, [:str, :size_t, :size_t], :int
    ffi_func :fleek_repeated_conditional_finding, [], :str
    ffi_func :fleek_data_clump, [:str, :size_t, :size_t, :size_t], :int
    ffi_func :fleek_data_clump_finding, [], :str
    ffi_func :fleek_too_many_constants, [:str, :size_t, :size_t], :int
    ffi_func :fleek_too_many_constants_finding, [], :str
    ffi_func :fleek_too_many_instance_variables, [:str, :size_t, :size_t], :int
    ffi_func :fleek_too_many_instance_variables_finding, [], :str
    ffi_func :fleek_too_many_methods, [:str, :size_t, :size_t], :int
    ffi_func :fleek_too_many_methods_finding, [], :str
    ffi_func :fleek_uncommunicative_method_name, [:str, :size_t, :str, :str], :int
    ffi_func :fleek_uncommunicative_method_name_finding, [], :str
    ffi_func :fleek_uncommunicative_module_name, [:str, :size_t, :str, :str], :int
    ffi_func :fleek_uncommunicative_module_name_finding, [], :str
    ffi_func :fleek_uncommunicative_parameter_name, [:str, :size_t, :str, :str], :int
    ffi_func :fleek_uncommunicative_parameter_name_finding, [], :str
    ffi_func :fleek_uncommunicative_variable_name, [:str, :size_t, :str, :str], :int
    ffi_func :fleek_uncommunicative_variable_name_finding, [], :str
    ffi_func :fleek_structural_duplication, [:str, :size_t, :int, :int, :int, :int, :str, :str], :int
    ffi_func :fleek_structural_duplication_finding, [], :str
    ffi_func :fleek_structural_duplication_failures, [], :str
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
      @override_markers = []
      @detector_excludes = []
      @scope_detector_excludes = []
      @list_detector = ""
      @list_setting = ""
      @override_detector = ""
      @override_context = ""
      @override_start_line = 0
      @override_context_indentation = 0
      @override_setting_indentation = 0
      @override_scope_index = -1
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
      lines = source.lines
      lines.each_with_index { |line, index| parse_line(line, index + 1) }
      finish_detector_override(lines.length + 1) unless @override_detector.empty?
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
      unless @override_detector.empty?
        return parse_detector_override(key, value, indentation, number) if indentation >= @override_context_indentation
        finish_detector_override(number)
        return if @error.length.positive?
      end
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
      elsif indentation == 4 && detector == "LongParameterList" && key == "overrides" && value.empty?
        start_detector_override(detector, false, number)
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
      elsif indentation == 6 && @scope_detector == "LongParameterList" && key == "overrides" && value.empty?
        start_detector_override(@scope_detector, true, number)
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

    def start_detector_override(detector, scoped, number)
      scope = scoped ? @scope_index : -1
      marker = "#{scope}:#{detector}"
      if @override_markers.include?(marker)
        fail_config(number, "duplicate #{detector} overrides")
        return
      end
      @override_markers << marker
      @override_detector = detector
      @override_context = ""
      @override_start_line = number
      @override_context_indentation = scoped ? 8 : 6
      @override_setting_indentation = @override_context_indentation + 2
      @override_scope_index = scope
    end

    def parse_detector_override(key, value, indentation, number)
      if indentation == @override_context_indentation && @override_context.empty?
        unless key == "initialize" && value.empty?
          fail_config(number, "unsupported #{@override_detector} override context #{key}")
          return
        end
        @override_context = key
      elsif indentation == @override_setting_indentation && !@override_context.empty?
        unless key == "max_params" && value.match?(/\A[0-9]+\z/)
          fail_config(number, "unsupported #{@override_detector} override setting #{key}")
          return
        end
        settings = @override_scope_index >= 0 ? @scope_detector_settings : @detector_settings
        settings << [@override_scope_index, @override_detector, "overrides.#{@override_context}.#{key}", value]
      else
        fail_config(number, "unsupported #{@override_detector} overrides mapping")
      end
    end

    def finish_detector_override(number)
      settings = @override_scope_index >= 0 ? @scope_detector_settings : @detector_settings
      found = settings.any? do |entry|
        entry[0] == @override_scope_index && entry[1] == @override_detector && entry[2] == "overrides.#{@override_context}.max_params"
      end
      unless !@override_context.empty? && found
        fail_config(@override_start_line, "incomplete #{@override_detector} overrides mapping")
      end
      @override_detector = ""
      @override_context = ""
      @override_start_line = 0
      @override_context_indentation = 0
      @override_setting_indentation = 0
      @override_scope_index = -1
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

    # Reek default exclusions apply when configuration names none for the detector.
    DEFAULT_DETECTOR_EXCLUDES = { "TooManyStatements" => ["initialize"] }.freeze

    def detector_excludes(detector)
      configured = @detector_excludes.select { |entry| entry.start_with?("#{detector}=") }.map { |entry| entry.split("=", 2)[1] }
      configured.empty? ? DEFAULT_DETECTOR_EXCLUDES.fetch(detector, []) : configured
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

  def self.print_probe_usage
    puts "       fleek --parse-ruby4 SOURCE (parser prototype; runs no checks)"
    puts "       fleek --reek-ast SOURCE (prints the parser AST Reek analyzes; runs no checks)"
  end

  def self.print_analysis_usage
    print_probe_usage
    puts "       fleek --checks reek:ClassVariable[,flay:StructuralDuplication] [--reek-config FILE] SOURCE"
    puts "       fleek --checks flay:StructuralDuplication,reek:ClassVariable [--mass MASS] [--timeout SECONDS] [--liberal] [--fuzzy [DIFF]] [--legacy] [-#] [--reek-config FILE] SOURCE..."
    puts "       fleek --checks reek:ClassVariable [--reek-config FILE] --stdin SOURCE [PATH...]"
    puts "       fleek --checks flay:StructuralDuplication [--mass MASS] [--timeout SECONDS] [--liberal] [--fuzzy [DIFF]] [--legacy] [-#] [--only NODE] SOURCE"
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
    warn "Use long options: --checks, --mass, --timeout, --liberal, --fuzzy, --legacy, and --reek-config; -# suppresses group numbering."
    warn "Usage: fleek [--help | --version]"
    1
  end

  def self.parse_ruby4_requested?(arguments)
    arguments.length == 2 && arguments[0] == "--parse-ruby4"
  end

  def self.reek_ast_requested?(arguments)
    arguments.length == 2 && arguments[0] == "--reek-ast"
  end

  # Developer probe: prints the parser-gem AST Reek 6.6.0 would analyze.
  def self.print_reek_ast(arguments)
    path = arguments[1]
    status = translate_reek_ast(path)
    return report_reek_ast_failure(path, status) unless status.zero?
    puts NativePrism.fleek_reek_ast_text
    0
  end

  def self.translate_reek_ast(path)
    source = File.binread(path)
    NativePrism.fleek_reek_ast(source, source.bytesize, path, 0)
  end

  def self.report_reek_ast_failure(path, status)
    warn "ERROR: Reek AST translation failed with status #{status}: #{quote_text(path)}"
    1
  end

  # :reek:BooleanParameter
  def self.run_structural_duplication(inputs, joint_run = false, timeout_failures = [])
    ignore_patterns, input_error = duplication_analysis_options(inputs)
    return report_duplication_input_failure(input_error) unless input_error == ""
    report = duplication_input_report(inputs, ignore_patterns)
    apply_duplication_timeout_failures(report, timeout_failures)
    read_and_analyze_duplication(report, joint_run)
  end

  def self.apply_duplication_timeout_failures(report, timeout_failures)
    report.paths = report.paths - timeout_failures.map(&:path)
    report.errors = report.errors + timeout_failures
  end

  def self.duplication_analysis_options(inputs)
    input_error = structural_duplication_input_error(inputs)
    return [[], input_error] unless input_error.length.zero?
    load_flay_ignore_patterns
  end

  def self.duplication_input_report(inputs, ignore_patterns)
    files, errors = discover_sources(duplication_source_paths(inputs), ReekConfiguration.new)
    files = files.map { |path| normalize_duplication_source_path(path) }.uniq
    included, excluded = partition_flay_sources(files, ignore_patterns)
    DuplicationReport.new(included, errors.sort_by(&:path), [], duplication_mass_threshold(inputs), excluded, nil, nil, duplication_only_node(inputs), inputs.include?("--liberal"), duplication_fuzzy_distance(inputs), inputs.include?("--legacy"))
  end

  def self.partition_flay_sources(files, patterns)
    included, excluded = files.partition { |path| !flay_ignored?(path, patterns) }
    [included.sort, excluded.sort]
  end

  def self.load_flay_ignore_patterns
    File.exist?(".flayignore") ? [File.read(".flayignore").split("\n"), ""] : [[], ""]
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
    return File.fnmatch?(absolute_pattern.tr("/", "\u0001"), absolute_path.tr("/", "\u0001")) unless pattern.include?("/")
    File.fnmatch?(absolute_pattern, absolute_path, File::FNM_PATHNAME)
  end

  # :reek:TooManyStatements
  def self.structural_duplication_input_error(inputs)
    mass_error = duplication_mass_error(inputs)
    return mass_error unless mass_error.empty?
    timeout_error = duplication_timeout_error(inputs)
    return timeout_error unless timeout_error.empty?
    fuzzy_error = duplication_fuzzy_error(inputs)
    return fuzzy_error unless fuzzy_error.empty?
    only_error = duplication_only_error(inputs)
    return only_error unless only_error.empty?
    duplication_source_input_error(inputs)
  end

  # :reek:TooManyStatements
  # :reek:NilCheck
  def self.duplication_fuzzy_error(inputs)
    index = 0
    length = inputs.length
    while index < length
      input = inputs[index]
      if input.start_with?("--fuzzy=")
        return "--fuzzy requires an integer distance." if integer_option_value(input.delete_prefix("--fuzzy=")).nil?
      elsif input == "--fuzzy"
        next_index = index + 1
        if next_index < length
          value = inputs[next_index]
          unless value.start_with?("-")
            return "--fuzzy requires an integer distance." if integer_option_value(value).nil?
            index = next_index
          end
        end
      end
      index += 1
    end
    ""
  end

  # :reek:DuplicateMethodCall
  # :reek:TooManyStatements
  def self.duplication_fuzzy_distance(inputs)
    distance = 0
    index = 0
    while index < inputs.length
      input = inputs[index]
      next_input = inputs[index + 1]
      if input == "--fuzzy"
        candidate = integer_option_value(next_input)
        distance = candidate || 1
        index += next_input && !next_input.start_with?("-") ? 2 : 1
      elsif input.start_with?("--fuzzy=")
        distance = integer_option_value(input.delete_prefix("--fuzzy=")) || 0
        index += 1
      else
        index += 1
      end
    end
    [[distance, 0].max, 10].min
  end

  def self.integer_option_value(value)
    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end

  # :reek:TooManyStatements
  def self.duplication_only_error(inputs)
    index = 0
    while index < inputs.length
      if inputs[index] == "--only"
        node = inputs[index + 1]
        return "--only requires a node type." unless node && !node.start_with?("-")
        index += 2
      else
        index += 1
      end
    end
    ""
  end

  def self.duplication_only_node(inputs)
    node = ""
    index = 0
    while index < inputs.length
      node = inputs[index + 1] if inputs[index] == "--only"
      index += 1
    end
    node
  end

  # :reek:TooManyStatements
  def self.duplication_mass_error(inputs)
    mass_indices = inputs.each_index.select { |index| inputs[index] == "--mass" }
    return "" if mass_indices.empty?
    return "--mass requires an integer from 3 through 2147483647 for the supported syntax." if mass_indices.any? { |index| !valid_duplication_mass?(inputs[index + 1]) }
    ""
  end

  def self.valid_duplication_mass?(mass_value)
    return false unless mass_value && mass_value.match?(/\A[0-9]+\z/)
    mass = mass_value.to_i
    mass >= 3 && mass <= 2_147_483_647
  end

  def self.duplication_timeout_error(inputs)
    inputs.each_index do |index|
      next unless inputs[index] == "--timeout"
      return "--timeout requires an integer number of seconds." unless integer_option_value(inputs[index + 1])
    end
    ""
  end

  def self.duplication_timeout(inputs)
    value = nil
    inputs.each_index { |index| value = integer_option_value(inputs[index + 1]) if inputs[index] == "--timeout" }
    value
  end

  def self.duplication_source_input_error(inputs)
    unsupported_option = duplication_unsupported_option(inputs)
    return "Unsupported Flay option: #{quote_text(unsupported_option)}" if unsupported_option
    return "flay:StructuralDuplication requires at least one Ruby source path." if duplication_source_paths(inputs).empty?
    ""
  end

  def self.duplication_unsupported_option(inputs)
    unsupported_index = inputs.each_index.find do |index|
      input = inputs[index]
      input.start_with?("-") && !(index.positive? && inputs[index - 1] == "--timeout") && input != "--mass" && input != "--only" && input != "--liberal" && input != "--fuzzy" && input != "--legacy" && input != "--timeout" && input != "-#" && !input.start_with?("--fuzzy=")
    end
    inputs[unsupported_index] if unsupported_index
  end

  def self.duplication_source_paths(inputs)
    paths = without_option_pairs(without_option(without_optional_integer_option(without_option(without_option_pairs(without_option_pairs(inputs, "--mass"), "--only"), "--liberal"), "--fuzzy"), "--legacy"), "--timeout")
    paths = without_option(paths, "-#")
    paths.map { |path| normalize_duplication_source_path(path) }.uniq
  end

  # :reek:DuplicateMethodCall
  # :reek:TooManyStatements
  def self.normalize_duplication_source_path(path)
    return "" if path.empty?
    absolute = path.start_with?("/")
    parts = []
    path.split("/").each do |part|
      next if part.empty? || part == "."
      if part == ".."
        if !parts.empty? && parts.last != ".."
          parts.pop
        elsif !absolute
          parts << part
        end
      else
        parts << part
      end
    end
    normalized = parts.join("/")
    return "/#{normalized}" if absolute && !normalized.empty?
    return "/" if absolute
    normalized.empty? ? "." : normalized
  end

  # :reek:DuplicateMethodCall
  # :reek:TooManyStatements
  def self.without_optional_integer_option(inputs, option)
    result = []
    index = 0
    while index < inputs.length
      input = inputs[index]
      next_input = inputs[index + 1]
      if input == option
        index += next_input && next_input.match?(/\A[0-9]+\z/) ? 2 : 1
      elsif input.start_with?("#{option}=")
        index += 1
      else
        result << input
        index += 1
      end
    end
    result
  end

  def self.without_option(inputs, option)
    inputs.reject { |input| input == option }
  end

  def self.duplication_mass_index(inputs)
    inputs.rindex("--mass") || inputs.length
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

  # :reek:TooManyStatements
  def self.append_duplication_source(source, source_map, path)
    content = File.binread(path)
    source_map << [path, source.count("\n") + 1, source.bytesize]
    source + content + (content.end_with?("\n") ? "" : "\n")
  end

  # :reek:BooleanParameter
  def self.analyze_structural_duplication(report, combined_analysis = false)
    run_native_duplication(report)
    result = report.result
    return report_duplication_analysis_failure(report, combined_analysis) if result + 1 <= 0
    print_duplication_report(report, result, combined_analysis)
  end

  def self.duplication_file_offsets(source_map)
    source_map.map { |entry| entry[2].to_s }.join(",")
  end
  def self.duplication_file_paths(source_map)
    source_map.map { |entry| entry[0] }.join("\n")
  end

  # :reek:TooManyStatements
  def self.run_native_duplication(report)
    source = report.source
    source_map = report.source_map
    report.result = NativePrism.fleek_structural_duplication(source, source.bytesize, report.mass_threshold, report.liberal ? 1 : 0, report.fuzzy, report.legacy ? 1 : 0, duplication_file_offsets(source_map), duplication_file_paths(source_map))
    apply_duplication_parse_failures(report, NativePrism.fleek_structural_duplication_failures)
  end

  def self.apply_duplication_parse_failures(report, records)
    failures = records.split("\n").map { |record| duplication_parse_failure(report.source_map, record) }
    apply_duplication_timeout_failures(report, failures) unless failures.empty?
  end

  def self.duplication_parse_failure(source_map, record)
    index, line, column, offset, message = record.split("\t", 5)
    path = source_map[index.to_i][0]
    warn_syntax_error(path, [line, column, offset], message)
    SourceFailure.new(path, "ERROR: Ruby syntax error; source was not analyzed.", :source)
  end


  # :reek:BooleanParameter
  def self.report_duplication_analysis_failure(report, combined_analysis)
    print_duplication_header(report, combined_analysis)
    report_invalid_duplication_sources(report, combined_analysis)
  end

  # :reek:BooleanParameter
  # :reek:TooManyStatements
  def self.report_invalid_duplication_sources(report, combined_error = false)
    result = report.result
    return report_legacy_duplication_parse_failure(report, combined_error) if result == NativePrism::DUPLICATION_LEGACY_PARSE_ERROR
    return report_unsupported_duplication_sources(report, combined_error) if result == NativePrism::DUPLICATION_UNSUPPORTED_SOURCE
    return report_single_duplication_parse_failure(report, combined_error) if report.paths.length == 1
    warn "ERROR: Combined source set could not be parsed; no duplication results were analyzed."
    report_duplication_failure_summary(report, combined_error)
  end

  # :reek:TooManyStatements
  def self.report_legacy_duplication_parse_failure(report, combined_error)
    paths = report.paths
    path = paths.length == 1 ? " #{quote_text(paths[0])}" : ""
    warn "ERROR: Flay --legacy cannot parse a line-leading boolean operator in#{path}; selected sources were not analyzed."
    report_duplication_errors(report.errors)
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
    warn "Use --mass MASS, --fuzzy, and --legacy; check-specific options use long names."
    1
  end

  # :reek:BooleanParameter
  def self.report_unsupported_duplication_sources(report, combined_syntax = false)
    warn "ERROR: unsupported Flay syntax; a selected source could not be translated into Flay 2.14.4 sexps (Prism 1.9.0 Translation::RubyParser semantics)."
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
    report.paths.each { |path| print_duplication_source(path, "included") }
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
    puts "Scope limits: whole files translated into Flay 2.14.4 sexps (Prism 1.9.0 Translation::RubyParser semantics); Flay mass #{mass_threshold}."
  end

  # :reek:BooleanParameter
  def self.print_duplication_report(report, score, combined_report = false)
    print_duplication_header(report, combined_report)
    groups = print_duplication_results(report, score)
    print_duplication_status(report, groups.empty? ? 0 : score, combined_report)
  end

  # :reek:ControlParameter
  # :reek:BooleanParameter
  # :reek:RepeatedConditional
  def self.print_duplication_status(report, score, combined_status = false)
    status = duplication_exit_status(report.errors.length, score)
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
    report.paths.length
  end

  def self.duplication_failed_count(report)
    report.errors.length
  end

  # :reek:BooleanParameter
  # :reek:ControlParameter
  def self.print_duplication_coverage(coverage, combined_status)
    return report_section_coverage("Duplication", coverage) if combined_status
    report_input_summary(coverage.selected, coverage.analyzed, coverage.failed, coverage.excluded, coverage.state)
  end

  # :reek:TooManyStatements
  def self.print_duplication_results(report, score)
    groups = score > 0 ? print_duplication_groups(report.source_map, report.only_node) : []
    puts "Total duplication score: #{score}"
    print_duplication_file_scores(report.paths, groups)
    groups
  end

  def self.print_duplication_file_scores(paths, groups)
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

  def self.print_duplication_groups(source_map, only_node = "")
    groups = selected_duplication_groups(source_map, only_node)
    groups.each { |group| print_duplication_group(group) }
    groups
  end

  def self.selected_duplication_groups(source_map, only_node)
    groups = duplication_groups(source_map)
    only_node.empty? ? groups : groups.select { |group| group.node == only_node }
  end

  def self.duplication_groups(source_map)
    records = NativePrism.fleek_structural_duplication_finding.split("\n")
    records.map { |record| duplication_group(record, source_map) }.sort_by { |group| duplication_group_sort_key(group) }
  end

  def self.duplication_group(record, source_map)
    node, kind, mass, score, lines, fuzzy_lines = record.split("\t")
    fuzzy_locations = fuzzy_lines && !fuzzy_lines.empty? ? duplication_group_locations(fuzzy_lines, source_map) : []
    DuplicationGroup.new(node, kind, mass.to_i, score.to_i, duplication_group_locations(lines, source_map), fuzzy_locations)
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
    fuzzy_locations = group.fuzzy_locations
    fuzzy = fuzzy_locations.empty? ? "" : " fuzzy_locations=#{quote_text(fuzzy_locations.join(","))}"
    "  Group: check=\"flay:StructuralDuplication\" node=#{quote_text(group.node)} kind=#{quote_text(group.kind)} locations=#{quote_text(group.locations.join(","))}#{fuzzy} mass=#{group.mass} score=#{group.score}"
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
    "Attribute" => ["public literal attr_accessor and attr_writer declarations in one simple class or module, including one direct nested class", "%s is a writable attribute"],
    "InstanceVariableAssumption" => ["direct instance methods in one simple class, including one direct nested class", "%s assumes too much for instance variable '%s'"],
    "SubclassedFromCoreClass" => ["one simple class inheriting directly from Array, Hash, or String", "%s inherits from core class '%s'"],
    "ModuleInitialize" => ["one simple module or one direct nested module with direct instance methods", "%s has initialize method"],
    "IrresponsibleModule" => ["whole files through the ported Reek context engine", "%s has no descriptive comment"],
    "LongParameterList" => ["one simple class or module with direct instance methods and supported parameter lists", "%s has %s parameters"],
    "BooleanParameter" => ["one simple class or module with direct instance methods and supported parameter lists", "%s has boolean parameter '%s'"],
    "LongYieldList" => ["one simple class or module with direct instance methods", "%s yields %s parameters"],
    "ControlParameter" => ["whole files through the ported Reek context engine", "%s is controlled by argument '%s'"],
    "UnusedParameters" => ["simple method parameter lists and supported method bodies with one iterator block", "%s has unused parameter '%s'"],
    "UnusedPrivateMethod" => ["one simple class with direct instance methods and bare private/public/protected visibility", "%s has the unused private instance method '%s'"],
    "UtilityFunction" => ["whole files through the ported Reek context engine", "%s doesn't depend on instance state (maybe move it to another class?)"],
    "DuplicateMethodCall" => ["whole files through the ported Reek context engine", "%s calls '%s' %s times"],
    "ManualDispatch" => ["simple method bodies containing respond_to?", "%s manually dispatches method call"],
    "NilCheck" => ["whole files through the ported Reek context engine", "%s performs a nil-check"],
    "MissingSafeMethod" => ["direct bang methods without matching non-bang methods", "%s has missing safe method '%s'"],
    "RepeatedConditional" => ["simple method conditions compared within direct top-level classes", "%s tests '%s' at least %s times"],
    "NestedIterators" => ["whole files through the ported Reek context engine", "%s contains iterators nested %s deep"],
    "FeatureEnvy" => ["whole files through the ported Reek context engine", "%s refers to '%s' more than self (maybe move it to another class?)"],
    "DataClump" => ["direct instance methods and class << self methods with matching parameter names", "%s takes parameters %s to %s methods"],
    "TooManyConstants" => ["direct constant assignments in one simple class or module, or in a direct nested module within one top-level module", "%s has %s constants"],
    "TooManyInstanceVariables" => ["one simple class, or two direct nested classes within one top-level class", "%s has at least %s instance variables"],
    "TooManyMethods" => ["direct instance methods in one simple class, or in one class with a single direct nested class", "%s has at least %s methods"],
    "TooManyStatements" => ["whole files through the ported Reek context engine", "%s has approx %s statements"],
    "UncommunicativeMethodName" => ["direct methods in one simple class or module, including one direct nested class", "%s has the name '%s'"],
    "UncommunicativeModuleName" => ["simple names and one-level qualified class/module constant paths", "%s has the name '%s'"],
    "UncommunicativeParameterName" => ["simple method parameters", "%s has the parameter name '%s'"],
    "UncommunicativeVariableName" => ["simple local assignments and required block parameters in direct methods", "%s has the variable name '%s'"]
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

  def self.run_unused_parameters(inputs)
    run_reek_detector(inputs, "UnusedParameters", :single)
  end

  # :reek:TooManyStatements
  def self.run_reek_detector(inputs, detector, report_mode)
    configuration, source_inputs, error = reek_detector_configuration(inputs)
    return report_configuration_error(error) if error.length.positive?
    files, errors = discover_sources(source_inputs, ReekConfiguration.new)
    selected, excluded, disabled = detector_source_sets(files, configuration, detector)
    if report_mode == :single_selected
      selected = files.reject { |path| excluded.include?(path) }
      disabled = []
    end
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
    if report_mode != :combined
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
    if detector == "LongParameterList"
      settings << Integer(configuration.detector_setting(detector, "overrides.initialize.max_params", path) || "5", 10)
    end
    utility_function = detector == "UtilityFunction"
    visibility_setting = utility_function && configuration.detector_setting(detector, "public_methods_only", path) == "true"
    settings << visibility_setting if utility_function
    result = run_native_reek_detector(detector, source, settings, path)
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
  def self.run_native_reek_detector(detector, source, settings, path)
    return run_reek_engine_detector(detector, source, path, settings) if REEK_ENGINE_DETECTORS.include?(detector)
    length = source.bytesize
    maximum = settings[0]
    option = settings[1]
    accepted_names = settings[2]
    detector_option = settings[3]
    minimum = Integer(option, 10) if detector == "DataClump"
    case detector
    when "Attribute" then NativePrism.fleek_attribute(source, length)
    when "InstanceVariableAssumption" then NativePrism.fleek_instance_variable_assumption(source, length)
    when "SubclassedFromCoreClass" then NativePrism.fleek_subclassed_from_core_class(source, length)
    when "ModuleInitialize" then NativePrism.fleek_module_initialize(source, length)
    when "LongParameterList" then NativePrism.fleek_long_parameter_list(source, length, maximum, detector_option)
    when "BooleanParameter" then NativePrism.fleek_boolean_parameter(source, length)
    when "LongYieldList" then NativePrism.fleek_long_yield_list(source, length, maximum)
    when "UnusedParameters" then NativePrism.fleek_unused_parameters(source, length)
    when "UnusedPrivateMethod" then NativePrism.fleek_unused_private_method(source, length)
    when "ManualDispatch" then NativePrism.fleek_manual_dispatch(source, length)
    when "MissingSafeMethod" then NativePrism.fleek_missing_safe_method(source, length)
    when "RepeatedConditional" then NativePrism.fleek_repeated_conditional(source, length, maximum)
    when "DataClump" then NativePrism.fleek_data_clump(source, length, maximum, minimum)
    when "TooManyConstants" then NativePrism.fleek_too_many_constants(source, length, maximum)
    when "TooManyInstanceVariables" then NativePrism.fleek_too_many_instance_variables(source, length, maximum)
    when "TooManyMethods" then NativePrism.fleek_too_many_methods(source, length, maximum)
    when "UncommunicativeMethodName" then NativePrism.fleek_uncommunicative_method_name(source, length, option, accepted_names)
    when "UncommunicativeModuleName" then NativePrism.fleek_uncommunicative_module_name(source, length, option, accepted_names)
    when "UncommunicativeParameterName" then NativePrism.fleek_uncommunicative_parameter_name(source, length, option, accepted_names)
    when "UncommunicativeVariableName" then NativePrism.fleek_uncommunicative_variable_name(source, length, option, accepted_names)
    end
  end

  # Records from the last run of a detector on the ported Reek context engine (ADR 0257).
  REEK_ENGINE_RECORDS = [""]

  # Detectors running on the ported Reek context engine.
  REEK_ENGINE_DETECTORS = %w[ControlParameter DuplicateMethodCall FeatureEnvy IrresponsibleModule NestedIterators NilCheck TooManyStatements UtilityFunction].freeze

  # :reek:LongParameterList
  def self.run_reek_engine_detector(detector, source, path, settings)
    status = NativePrism.fleek_reek_ast(source, source.bytesize, path, 1)
    return status unless status.zero?
    store_reek_engine_records(ReekEngine.records(detector, reek_engine_contexts(source), source, settings))
  end

  def self.store_reek_engine_records(records)
    REEK_ENGINE_RECORDS[0] = records
    records.empty? ? 0 : 1
  end

  def self.reek_engine_contexts(source)
    tree = ReekEngine::Tree.new(NativePrism.fleek_reek_ast_text, NativePrism.fleek_reek_comments_text, source)
    ReekEngine::ContextBuilder.new(tree).root
  end

  # :reek:ControlParameter
  # :reek:TooManyStatements
  def self.native_reek_findings(detector)
    return REEK_ENGINE_RECORDS[0] if REEK_ENGINE_DETECTORS.include?(detector)
    case detector
    when "Attribute" then NativePrism.fleek_attribute_finding
    when "InstanceVariableAssumption" then NativePrism.fleek_instance_variable_assumption_finding
    when "SubclassedFromCoreClass" then NativePrism.fleek_subclassed_from_core_class_finding
    when "ModuleInitialize" then NativePrism.fleek_module_initialize_finding
    when "LongParameterList" then NativePrism.fleek_long_parameter_list_finding
    when "BooleanParameter" then NativePrism.fleek_boolean_parameter_finding
    when "LongYieldList" then NativePrism.fleek_long_yield_list_finding
    when "UnusedParameters" then NativePrism.fleek_unused_parameters_finding
    when "UnusedPrivateMethod" then NativePrism.fleek_unused_private_method_finding
    when "ManualDispatch" then NativePrism.fleek_manual_dispatch_finding
    when "MissingSafeMethod" then NativePrism.fleek_missing_safe_method_finding
    when "RepeatedConditional" then NativePrism.fleek_repeated_conditional_finding
    when "DataClump" then NativePrism.fleek_data_clump_finding
    when "TooManyConstants" then NativePrism.fleek_too_many_constants_finding
    when "TooManyInstanceVariables" then NativePrism.fleek_too_many_instance_variables_finding
    when "TooManyMethods" then NativePrism.fleek_too_many_methods_finding
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
  # :reek:DuplicateMethodCall
  def self.extract_reek_configuration(inputs)
    remaining = []
    config_path = ""
    config_seen = false
    index = 0
    input_count = inputs.length
    while index < input_count
      input = inputs[index]
      if input == "--reek-config"
        return ["", [], "--reek-config may appear only once."] if config_seen
        value_index = index + 1
        return ["", [], "--reek-config requires a file."] if value_index >= input_count
        config_path = inputs[value_index]
        return ["", [], "--reek-config requires a non-empty file path."] if config_path.empty?
        config_seen = true
        index += 2
      else
        remaining << input
        index += 1
      end
    end
    [config_path, remaining, ""]
  end

  def self.report_configuration_error(message)
    warn "ERROR: Reek configuration #{message}"
    1
  end

  # :reek:TooManyStatements
  def self.run_combined_checks(inputs, profile = CheckProfiles::EXPLICIT, timeout_failures = [])
    analysis = prepare_combined_analysis(inputs)
    error = analysis.error
    return report_combined_input_error(error) if error != ""
    disabled_paths = analysis.disabled_paths
    return report_disabled_check(disabled_paths, analysis.configuration) unless disabled_paths.empty? || !profile.run.include?("reek:ClassVariable")
    print_combined_header(profile)
    run_combined_sections(analysis, profile, timeout_failures)
  end

  def self.print_combined_header(profile = CheckProfiles::EXPLICIT)
    print_report_identity
    profile.report_lines.each { |line| puts line }
    puts "Scope limits: supported Flay and Reek syntax subsets; analyzer-specific exclusions; separate scores."
  end

  # :reek:TooManyStatements
  def self.prepare_combined_analysis(inputs)
    flay_inputs = without_option_pairs(inputs, "--reek-config")
    reek_inputs = without_option(without_option_pairs(without_option(without_option_pairs(without_option_pairs(without_option(without_optional_integer_option(inputs, "--fuzzy"), "--liberal"), "--mass"), "--only"), "--legacy"), "--timeout"), "-#")
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
  def self.run_combined_sections(analysis, profile = CheckProfiles::EXPLICIT, timeout_failures = [])
    puts "Duplication section:"
    duplication_status = run_profile_check(profile, "flay:StructuralDuplication", analysis.flay_inputs, timeout_failures)
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

  # Timeout failures extend the Flay source report without changing Reek inputs.
  # :reek:LongParameterList
  def self.run_profile_check(profile, check, inputs, timeout_failures = [])
    return 0 unless profile.run.include?(check)
    return run_structural_duplication(inputs, true, timeout_failures) if selected_flay_only?(check)
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

  # :reek:ControlParameter
  # :reek:TooManyStatements
  def self.without_option_pairs(inputs, option)
    remaining = []
    index = 0
    while index < inputs.length
      input = inputs[index]
      if input == option
        index += 2
      else
        remaining << input
        index += 1
      end
    end
    remaining
  end

  def self.report_combined_input_error(message)
    warn "ERROR: #{message}"
    warn "Use long options: --checks, --mass, --timeout, --liberal, and --reek-config."
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
    warn_syntax_error(path, [line, column, offset], NativePrism.fleek_parse_message)
  end

  def self.warn_syntax_error(path, position, message)
    line, column, offset = position
    warn "#{quote_text(path)}:#{line}:#{column}: #{message} (byte #{offset})"
  end

  def self.run(arguments)
    first_argument = arguments[0]
    internal_result = run_internal_timeout_command(arguments)
    return internal_result if internal_result
    return report_unsupported_format if unsupported_format_requested?(arguments)
    run_with_flay_timeout(arguments)
  end

  def self.run_internal_timeout_command(arguments)
    first_argument = arguments[0]
    return run_timeout_worker_arguments(arguments) if first_argument == "--timeout-worker"
    return run_timeout_killer(arguments) if first_argument == "--timeout-killer" && ENV["FLEEK_TIMEOUT_PARENT"] == Process.ppid.to_s
    nil
  end

  def self.run_with_flay_timeout(arguments)
    timeout, timeout_error = selected_flay_timeout(arguments)
    return print_usage_error(timeout_error) unless timeout_error.empty?
    return report_timeout_skip(arguments, timeout) if timeout && timeout < 0
    return run_positive_flay_timeout(arguments, timeout) if timeout && timeout > 0
    run_without_unsupported_format(arguments)
  end

  def self.run_positive_flay_timeout(arguments, timeout)
    return run_timeout_child(arguments, timeout) unless timeout_source_count(arguments) > 1
    run_per_file_timeout(arguments, timeout)
  end

  # Preserves source failures, timeout diagnostics, and standalone versus combined dispatch.
  # :reek:TooManyStatements
  def self.run_per_file_timeout(arguments, timeout)
    failures = per_file_timeout_failures(arguments, timeout)
    failures.each { |failure| warn "#{failure.message} #{quote_text(failure.path)}" }
    inputs = without_option_pairs(arguments[2..], "--timeout")
    run_per_file_timeout_analysis(arguments, inputs, failures)
  end

  def self.per_file_timeout_failures(arguments, timeout)
    timeout_source_report(arguments).paths.select { |path| timeout_source_exceeded?(arguments, path, timeout) }.map do |path|
      SourceFailure.new(path, "ERROR: Flay timeout after #{timeout} seconds; source was not analyzed.", :source)
    end
  end

  def self.run_per_file_timeout_analysis(arguments, inputs, failures)
    return run_structural_duplication(inputs, false, failures) if arguments[0] == "--checks" && arguments[1] == FLAY_CHECK
    run_combined_checks(inputs, CheckProfiles::EXPLICIT, failures)
  end

  def self.timeout_source_exceeded?(arguments, path, timeout)
    files = timeout_worker_files
    # Keep probe to one source while preserving Flay controls.
    probe = ["--checks", FLAY_CHECK] + timeout_probe_options(arguments) + ["--timeout", timeout.to_s, path]
    _status, expired = run_timeout_worker(probe, timeout, files)
    expired
  ensure
    cleanup_timeout_worker_files(files) if files
  end

  # Each supported Flay parser option must be copied explicitly into isolated probes.
  # :reek:TooManyStatements
  def self.timeout_probe_options(arguments)
    inputs = arguments[2..]
    options = []
    ["--mass", "--only", "--fuzzy"].each do |option|
      index = inputs.index(option)
      options += [option, inputs[index + 1]] if index
    end
    options << "--liberal" if inputs.include?("--liberal")
    options << "--legacy" if inputs.include?("--legacy")
    options
  end

  def self.run_timeout_worker_arguments(arguments)
    run_without_unsupported_format(File.read(arguments[1]).split("\u0000"))
  end

  def self.selected_flay_timeout(arguments)
    return [nil, ""] unless selected_checks_requested?(arguments, arguments[0])
    check = arguments[1]
    return [nil, ""] unless check.include?(FLAY_CHECK)
    inputs = arguments[2..]
    [duplication_timeout(inputs), duplication_timeout_error(inputs)]
  end

  def self.run_timeout_child(arguments, timeout)
    files = timeout_worker_files
    status, expired = run_timeout_worker(arguments, timeout, files)
    return report_timeout_skip(arguments, timeout) if expired
    print_timeout_worker_output(files)
    status
  ensure
    cleanup_timeout_worker_files(files) if files
  end

  def self.timeout_worker_files
    token = Process.pid.to_s
    ["/tmp/fleek-timeout-#{token}.out", "/tmp/fleek-timeout-#{token}.err", "/tmp/fleek-timeout-#{token}.args", "/tmp/fleek-timeout-#{token}.expired"]
  end

  def self.run_timeout_worker(arguments, timeout, files)
    output, error, argument_path, expired_path = files
    timeout_budget = prepare_timeout_worker(arguments, timeout, argument_path)
    process_id = Process.spawn($0, "--timeout-worker", argument_path, out: output, err: error)
    wait_for_timeout_worker_start(process_id, timeout_budget, expired_path)
  end

  def self.prepare_timeout_worker(arguments, timeout, argument_path)
    child_arguments = without_option_pairs(arguments, "--timeout")
    timeout_budget = timeout * timeout_source_count(arguments)
    File.write(argument_path, child_arguments.join("\u0000"))
    timeout_budget
  end

  def self.wait_for_timeout_worker_start(process_id, timeout_budget, expired_path)
    timer_id = Process.spawn("env", "FLEEK_TIMEOUT_PARENT=#{Process.pid}", $0, "--timeout-killer", process_id.to_s, timeout_budget.to_s, expired_path, out: "/dev/null", err: "/dev/null")
    _, worker_status = Process.waitpid2(process_id)
    stop_timeout_timer(timer_id)
    [worker_status.exitstatus || 1, File.file?(expired_path)]
  end

  # :reek:TooManyStatements
  def self.run_timeout_killer(arguments)
    process_id = arguments[1].to_i
    sleep(arguments[2].to_i)
    File.write(arguments[3], "timeout")
    Process.kill("KILL", process_id)
    0
  rescue SystemCallError
    0
  end

  def self.stop_timeout_timer(timer_id)
    begin
      Process.kill("KILL", timer_id)
    rescue SystemCallError
      nil
    end
    Process.waitpid2(timer_id)
  rescue SystemCallError
    nil
  end

  def self.print_timeout_worker_output(files)
    output, error = files
    $stdout.write(File.read(output))
    $stderr.write(File.read(error))
  end

  def self.cleanup_timeout_worker_files(files)
    files.each { |path| File.delete(path) if File.file?(path) }
  end

  def self.timeout_source_count(arguments)
    report = timeout_source_report(arguments)
    count = report.paths.length + report.errors.length
    count.positive? ? count : 1
  end

  def self.timeout_source_report(arguments)
    inputs = without_option_pairs(without_option_pairs(arguments[2..], "--timeout"), "--reek-config")
    ignore_patterns, = load_flay_ignore_patterns
    duplication_input_report(inputs, ignore_patterns)
  end

  def self.report_timeout_skip(arguments, timeout)
    check = arguments[1]
    report, inputs, error = timeout_failure_context(arguments)
    return print_usage_error(error) if error.size > 0
    return report_standalone_timeout(report, timeout) if check == FLAY_CHECK
    report_combined_timeout_skip(report, inputs, timeout)
  end

  def self.timeout_failure_context(arguments)
    inputs = without_option_pairs(arguments[2..], "--timeout")
    flay_inputs = without_option_pairs(inputs, "--reek-config")
    report, error = duplication_timeout_report_for_inputs(flay_inputs)
    [report, inputs, error]
  end

  def self.duplication_timeout_report_for_inputs(inputs)
    input_error = structural_duplication_input_error(inputs)
    return [nil, input_error] unless input_error.empty?
    duplication_timeout_report(inputs)
  end

  def self.duplication_timeout_report(inputs)
    ignore_patterns, error = load_flay_ignore_patterns
    return [nil, error] unless error == ""
    [duplication_input_report(inputs, ignore_patterns), ""]
  end

  def self.report_standalone_timeout(report, timeout)
    print_duplication_header(report)
    warn "ERROR: Flay timeout after #{timeout} seconds; selected sources were not analyzed."
    report_duplication_failure_summary(report)
  end

  def self.report_combined_timeout_skip(report, inputs, timeout)
    analysis = prepare_combined_analysis(inputs)
    analysis_error = analysis.error
    return report_combined_input_error(analysis_error) unless analysis_error.empty?
    print_combined_header
    finish_combined_timeout(report, analysis, timeout)
  end

  def self.finish_combined_timeout(report, analysis, timeout)
    report_combined_timeout_sections(report, analysis, timeout)
    finish_combined_analysis(1, 1)
  end

  def self.report_combined_timeout_sections(report, analysis, timeout)
    report_combined_flay_timeout(report, timeout)
    report_combined_smell_timeout(analysis)
  end

  def self.report_combined_flay_timeout(report, timeout)
    puts "Duplication section:"
    print_duplication_header(report, true)
    warn "ERROR: Flay timeout after #{timeout} seconds; selected sources were not analyzed."
    report_duplication_failure_summary(report, true)
  end

  def self.report_combined_smell_timeout(analysis)
    puts "Smell section:"
    configuration = analysis.configuration
    files, errors = discover_sources(analysis.reek_inputs, configuration)
    report_combined_smell_timeout_coverage(files, errors, configuration)
  end

  def self.report_combined_smell_timeout_coverage(files, errors, configuration)
    excluded = files.count { |path| configuration.excluded_path?(path) }
    failed = files.length - excluded + errors.length
    coverage = Coverage.new(failed + excluded, 0, failed, excluded, "incomplete")
    report_section_coverage("Smell", coverage)
  end

  # :reek:TooManyStatements
  def self.run_without_unsupported_format(arguments)
    first_argument = arguments[0]
    return parse_ruby4_file(arguments[1]) if parse_ruby4_requested?(arguments)
    return print_reek_ast(arguments) if reek_ast_requested?(arguments)
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
    source_paths = default_profile_source_paths(source_inputs)
    [CheckProfiles.default(configuration, source_paths), ""]
  end

  def self.default_profile_source_paths(source_inputs)
    discover_sources(without_flay_options(source_inputs), ReekConfiguration.new)[0]
  end

  def self.without_flay_options(inputs)
    without_option(without_option_pairs(without_option(without_option_pairs(without_option_pairs(without_option(without_optional_integer_option(inputs, "--fuzzy"), "--liberal"), "--mass"), "--only"), "--legacy"), "--timeout"), "-#")
  end

  # :reek:TooManyStatements
  def self.run_selected_checks(arguments)
    inputs = arguments[2..]
    check = arguments[1]
    option_error = selected_check_option_error(check, inputs)
    return report_combined_input_error(option_error) unless option_error.empty?
    detector = check.delete_prefix("reek:")
    return run_selected_opt_in_detector(inputs, "UnusedPrivateMethod") if check == "reek:UnusedPrivateMethod"
    return run_class_variable(inputs) if check == "reek:ClassVariable"
    return run_attribute(inputs) if check == "reek:Attribute"
    return run_instance_variable_assumption(inputs) if check == "reek:InstanceVariableAssumption"
    return run_irresponsible_module(inputs) if check == "reek:IrresponsibleModule"
    return run_long_parameter_list(inputs) if check == "reek:LongParameterList"
    return run_boolean_parameter(inputs) if check == "reek:BooleanParameter"
    return run_long_yield_list(inputs) if check == "reek:LongYieldList"
    return run_unused_parameters(inputs) if check == "reek:UnusedParameters"
    return run_reek_detector(inputs, detector, :single) if check.start_with?("reek:") && REEK_DETECTORS.key?(detector)
    return run_module_initialize(inputs) if check == "reek:ModuleInitialize"
    return run_subclassed_from_core_class(inputs) if check == "reek:SubclassedFromCoreClass"
    return run_structural_duplication(inputs) if check == FLAY_CHECK
    return run_combined_checks(inputs) if check == "flay:StructuralDuplication,reek:ClassVariable" || check == "reek:ClassVariable,flay:StructuralDuplication"
    print_usage_error(input_error(arguments))
  end

  def self.selected_check_option_error(check, inputs)
    reek_option = inputs.find { |argument| ["--mass", "--only", "--liberal", "--fuzzy", "--legacy", "--timeout", "-#"].include?(argument) || argument.start_with?("--fuzzy=") } if check.start_with?("reek:") && !check.include?(FLAY_CHECK)
    return "#{reek_option} applies only to flay:StructuralDuplication." if reek_option
    check == FLAY_CHECK && inputs.include?("--reek-config") ? "--reek-config applies only to Reek checks." : ""
  end

  def self.selected_flay_only?(check)
    check == FLAY_CHECK
  end

  def self.run_selected_opt_in_detector(inputs, detector)
    profile, error = selected_opt_in_profile(inputs, detector)
    return report_configuration_error(error) unless error.empty?
    configured = inputs.include?("--reek-config") || !ReekConfiguration.discovered_path.empty?
    return run_reek_detector(inputs, detector, :single_selected) unless configured
    run_combined_checks(inputs, profile)
  end

  # :reek:TooManyStatements
  def self.selected_opt_in_profile(inputs, detector)
    configuration, sources, error = parse_reek_configuration(inputs)
    return [nil, error] unless error.empty?
    files, = discover_sources(sources, ReekConfiguration.new)
    enabled_by_config = configuration.detector_enabled_anywhere?(detector, files)
    check = "reek:#{detector}"
    configured = inputs.include?("--reek-config") || !ReekConfiguration.discovered_path.empty?
    disabled = configured && !enabled_by_config ? [check] : []
    run = disabled.empty? ? [check] : []
    [AnalysisProfile.new([check], run, disabled, [], true), ""]
  end
end

exit Fleek.run(ARGV)
