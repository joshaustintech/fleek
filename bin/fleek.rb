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
  DuplicationReport = Struct.new(:paths, :errors, :source_map, :mass_threshold, :excluded_paths, :source, :result, :partial, :partial_paths, :source_scope, :only_node, :liberal, :fuzzy, :legacy)
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
    static char fleek_unused_private_method_buffer[8192];
    static size_t fleek_unused_private_method_used;
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
    static pm_constant_id_t *fleek_duplication_scope_scratch;
    static size_t fleek_duplication_scope_scratch_capacity;
    static uint8_t *fleek_duplication_scope_type_scratch;
    static size_t fleek_duplication_scope_type_scratch_capacity;
    enum { FLEEK_DUPLICATION_CLASS_SCOPE = 1, FLEEK_DUPLICATION_MODULE_SCOPE = 2 };

    typedef struct {
      union {
        struct { const pm_node_t **nodes; size_t *tree_starts; size_t *tree_ends; size_t *node_ends; int8_t *mass_adjustments; int16_t *tree; size_t node_capacity; size_t tree_capacity; size_t tree_count; } ast;
      } data;
      size_t shape_count;
      size_t parameter_mass;
      size_t body_statement_count;
      bool has_optional_method_parameters;
      int line;
      int scope_kind;
      pm_constant_id_t *scope_names;
      uint8_t *scope_types;
      size_t scope_depth;
      size_t scope_mass;
      size_t source_offset;
    } fleek_duplication_method_t;

    typedef struct {
      const pm_def_node_t **methods;
      fleek_duplication_method_t *candidates;
      size_t *scope_indices;
      size_t *scope_body_counts;
      size_t *scope_candidate_counts;
      int *scope_lines;
      size_t capacity;
      size_t scope_count;
      size_t namespace_count;
      size_t count;
    } fleek_duplication_class_candidates_t;

    static bool fleek_duplication_reserve_class_candidates(fleek_duplication_class_candidates_t *set, size_t required) {
      if (required <= set->capacity) return true;
      size_t next = set->capacity == 0 ? 16 : set->capacity;
      while (next < required) {
        if (next > SIZE_MAX / 2) return false;
        next *= 2;
      }
      if (next > SIZE_MAX / sizeof(const pm_def_node_t *) || next > SIZE_MAX / sizeof(fleek_duplication_method_t) ||
          next > SIZE_MAX / sizeof(size_t) || next > SIZE_MAX / sizeof(int)) return false;
      const pm_def_node_t **methods = realloc(set->methods, next * sizeof(const pm_def_node_t *));
      if (methods == NULL) return false;
      set->methods = methods;
      fleek_duplication_method_t *candidates = realloc(set->candidates, next * sizeof(fleek_duplication_method_t));
      if (candidates == NULL) return false;
      set->candidates = candidates;
      size_t *scope_indices = realloc(set->scope_indices, next * sizeof(size_t));
      if (scope_indices == NULL) return false;
      set->scope_indices = scope_indices;
      size_t *scope_body_counts = realloc(set->scope_body_counts, next * sizeof(size_t));
      if (scope_body_counts == NULL) return false;
      set->scope_body_counts = scope_body_counts;
      size_t *scope_candidate_counts = realloc(set->scope_candidate_counts, next * sizeof(size_t));
      if (scope_candidate_counts == NULL) return false;
      set->scope_candidate_counts = scope_candidate_counts;
      int *scope_lines = realloc(set->scope_lines, next * sizeof(int));
      if (scope_lines == NULL) return false;
      set->scope_lines = scope_lines;
      memset(set->candidates + set->capacity, 0, (next - set->capacity) * sizeof(fleek_duplication_method_t));
      set->capacity = next;
      return true;
    }

    static bool fleek_duplication_reserve_next_class_candidate(fleek_duplication_class_candidates_t *set) {
      return set->count < SIZE_MAX && fleek_duplication_reserve_class_candidates(set, set->count + 1);
    }

    static bool fleek_duplication_reserve_names(pm_constant_id_t **names, size_t *capacity, size_t required) {
      if (required <= *capacity) return true;
      size_t next = *capacity == 0 ? 16 : *capacity;
      while (next < required) {
        if (next > SIZE_MAX / 2) return false;
        next *= 2;
      }
      if (next > SIZE_MAX / sizeof(pm_constant_id_t)) return false;
      pm_constant_id_t *resized = realloc(*names, next * sizeof(pm_constant_id_t));
      if (resized == NULL) return false;
      *names = resized;
      *capacity = next;
      return true;
    }

    static bool fleek_duplication_reserve_scope_types(size_t required) {
      if (required <= fleek_duplication_scope_type_scratch_capacity) return true;
      size_t next = fleek_duplication_scope_type_scratch_capacity == 0 ? 16 : fleek_duplication_scope_type_scratch_capacity;
      while (next < required) {
        if (next > SIZE_MAX / 2) return false;
        next *= 2;
      }
      uint8_t *resized = realloc(fleek_duplication_scope_type_scratch, next * sizeof(uint8_t));
      if (resized == NULL) return false;
      fleek_duplication_scope_type_scratch = resized;
      fleek_duplication_scope_type_scratch_capacity = next;
      return true;
    }

    static bool fleek_duplication_store_scope_path(fleek_duplication_method_t *candidate, const pm_constant_id_t *names, const uint8_t *types, size_t count, uint8_t default_type) {
      size_t allocation_count = count == 0 ? 1 : count;
      if (allocation_count > SIZE_MAX / sizeof(pm_constant_id_t)) return false;
      pm_constant_id_t *stored = malloc(allocation_count * sizeof(pm_constant_id_t));
      if (stored == NULL) return false;
      uint8_t *stored_types = malloc(allocation_count * sizeof(uint8_t));
      if (stored_types == NULL) { free(stored); return false; }
      candidate->scope_names = stored;
      candidate->scope_types = stored_types;
      candidate->scope_depth = count;
      for (size_t index = 0; index < count; index++) {
        stored[index] = names[index];
        stored_types[index] = types == NULL ? default_type : types[index];
      }
      return true;
    }

    static bool fleek_duplication_store_scope_names(fleek_duplication_method_t *candidate, const pm_constant_id_t *names, size_t count, uint8_t type) {
      return fleek_duplication_store_scope_path(candidate, names, NULL, count, type);
    }

    static bool fleek_duplication_prepend_scope_name(fleek_duplication_method_t *candidate, pm_constant_id_t name, uint8_t type) {
      size_t count = candidate->scope_depth;
      if (count == SIZE_MAX || count + 1 > SIZE_MAX / sizeof(pm_constant_id_t)) return false;
      pm_constant_id_t *expanded = realloc(candidate->scope_names, (count + 1) * sizeof(pm_constant_id_t));
      if (expanded == NULL) return false;
      uint8_t *expanded_types = realloc(candidate->scope_types, (count + 1) * sizeof(uint8_t));
      if (expanded_types == NULL) { candidate->scope_names = expanded; return false; }
      for (size_t index = count; index > 0; index--) expanded[index] = expanded[index - 1];
      for (size_t index = count; index > 0; index--) expanded_types[index] = expanded_types[index - 1];
      expanded[0] = name;
      expanded_types[0] = type;
      candidate->scope_names = expanded;
      candidate->scope_types = expanded_types;
      candidate->scope_depth++;
      return true;
    }

    static pm_constant_id_t fleek_duplication_candidate_scope_name(const fleek_duplication_class_candidates_t *set, size_t candidate, size_t name) {
      return set->candidates[candidate].scope_names[name];
    }

    static bool fleek_constants_equal(pm_parser_t *parser, pm_constant_id_t left, pm_constant_id_t right);

    static bool fleek_duplication_scope_path_element_equal(pm_parser_t *parser, const fleek_duplication_class_candidates_t *set, size_t left, size_t right, size_t index) {
      return set->candidates[left].scope_types[index] == set->candidates[right].scope_types[index] &&
        fleek_constants_equal(parser, fleek_duplication_candidate_scope_name(set, left, index),
          fleek_duplication_candidate_scope_name(set, right, index));
    }

    static bool fleek_duplication_scope_types_equal(const fleek_duplication_class_candidates_t *set, size_t left, size_t right) {
      size_t left_depth = set->candidates[left].scope_depth;
      size_t right_depth = set->candidates[right].scope_depth;
      size_t shared_depth = left_depth < right_depth ? left_depth : right_depth;
      for (size_t index = 0; index < shared_depth; index++) {
        if (set->candidates[left].scope_types[index] != set->candidates[right].scope_types[index]) return false;
      }
      return left_depth == right_depth;
    }

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
      pm_visit_node(root, fleek_collect_classes, NULL);
      fleek_class_new_search_t class_new = fleek_find_class_new_assignment(&parser, root);
      if (class_new.unsupported) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
      }
      if (class_new.call != NULL) {
        bool supported_class_new = class_new.assignment != NULL && class_new.call->block == NULL && class_new.call->arguments != NULL &&
          class_new.call->arguments->arguments.size == 1 && fleek_class_count == 0 && fleek_module_count == 0 &&
          PM_NODE_TYPE_P(class_new.call->arguments->arguments.nodes[0], PM_CONSTANT_READ_NODE);
        if (!supported_class_new) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        const pm_constant_write_node_t *assignment = (const pm_constant_write_node_t *) class_new.assignment;
        pm_constant_t *class_name = pm_constant_pool_id_to_constant(&parser.constant_pool, assignment->name);
        int comment_status = fleek_scope_descriptively_commented(&parser, assignment->name_loc.start);
        if (comment_status < 0) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4;
        }
        int result = 0;
        if (comment_status == 0) {
          int line = fleek_source_line((const uint8_t *) source, assignment->name_loc.start);
          int written = snprintf(fleek_irresponsible_module_buffer, sizeof(fleek_irresponsible_module_buffer), "%d\\t%.*s\\t\\n", line, (int) class_name->length, class_name->start);
          result = written < 0 || (size_t) written >= sizeof(fleek_irresponsible_module_buffer) ? -4 : 1;
        }
        pm_node_destroy(&parser, root);
        pm_parser_free(&parser);
        pm_options_free(&options);
        return result;
      }
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
    typedef struct { size_t maximum; const pm_node_t *scope; } fleek_long_parameter_state_t;
    static int fleek_long_parameter_list_method(pm_parser_t *, const uint8_t *, const char *, size_t, const pm_node_t *, void *);
    typedef struct { bool public_methods_only; bool method_is_public; bool unsupported_visibility; } fleek_utility_scan_t;
    typedef struct { size_t maximum; bool singleton_seen; } fleek_too_many_statements_scan_t;
    typedef struct { bool found; } fleek_nested_method_state_t;
    static bool fleek_find_nested_method(const pm_node_t *node, void *data) {
      fleek_nested_method_state_t *state = (fleek_nested_method_state_t *) data;
      if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) { state->found = true; return false; }
      return !PM_NODE_TYPE_P(node, PM_CLASS_NODE) && !PM_NODE_TYPE_P(node, PM_MODULE_NODE);
    }
    static int fleek_utility_function_method(pm_parser_t *, const uint8_t *, const char *, size_t, const pm_node_t *, void *);
    static int fleek_missing_safe_method_method(pm_parser_t *, const uint8_t *, const char *, size_t, const pm_node_t *, void *);
    static int fleek_too_many_statements_method(pm_parser_t *, const uint8_t *, const char *, size_t, const pm_node_t *, void *);
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
        bool utility_scan = analyze == fleek_utility_function_method;
        bool current_method_public = true;
        if (utility_scan && ((fleek_utility_scan_t *) state)->public_methods_only && fleek_class_count + fleek_module_count == 0)
          ((fleek_utility_scan_t *) state)->unsupported_visibility = true;
        if (statements->body.size > 128) findings = -1;
        for (size_t index = 0; findings >= 0 && index < statements->body.size; index++) {
          const pm_node_t *statement = statements->body.nodes[index];
          if (utility_scan && PM_NODE_TYPE_P(statement, PM_CALL_NODE)) {
            const pm_call_node_t *call = (const pm_call_node_t *) statement;
            bool no_arguments = call->arguments == NULL || call->arguments->arguments.size == 0;
            bool visibility = call->receiver == NULL && no_arguments && call->block == NULL &&
              (fleek_name_is(&parser, call->name, "public") || fleek_name_is(&parser, call->name, "private") || fleek_name_is(&parser, call->name, "protected"));
            if (visibility) {
              current_method_public = fleek_name_is(&parser, call->name, "public");
              continue;
            }
            if (((fleek_utility_scan_t *) state)->public_methods_only) ((fleek_utility_scan_t *) state)->unsupported_visibility = true;
          }
          if (analyze == fleek_too_many_statements_method && PM_NODE_TYPE_P(statement, PM_SINGLETON_CLASS_NODE)) {
            fleek_too_many_statements_scan_t *scan = (fleek_too_many_statements_scan_t *) state;
            scan->singleton_seen = true;
            const pm_singleton_class_node_t *singleton = (const pm_singleton_class_node_t *) statement;
            if (!PM_NODE_TYPE_P(singleton->expression, PM_SELF_NODE) || !PM_NODE_TYPE_P(singleton->body, PM_STATEMENTS_NODE)) { findings = -1; continue; }
            const pm_statements_node_t *singleton_body = (const pm_statements_node_t *) singleton->body;
            bool singleton_unsupported = singleton_body->body.size > 128;
            size_t singleton_findings = 0;
            for (size_t method_index = 0; method_index < singleton_body->body.size; method_index++) {
              const pm_node_t *singleton_statement = singleton_body->body.nodes[method_index];
              if (PM_NODE_TYPE_P(singleton_statement, PM_DEF_NODE)) {
                int result = analyze(&parser, (const uint8_t *) source, class_name_text, class_name_length, singleton_statement, state);
                if (result < 0) singleton_unsupported = true;
                else singleton_findings += (size_t) result;
              } else {
                fleek_nested_method_state_t nested = { false }; pm_visit_node(singleton_statement, fleek_find_nested_method, &nested);
                if (nested.found) singleton_unsupported = true;
              }
            }
            if (singleton_unsupported) findings = -1;
            else findings += (int) singleton_findings;
            continue;
          }
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
          if (utility_scan) {
            fleek_utility_scan_t *utility = (fleek_utility_scan_t *) state;
            utility->method_is_public = current_method_public;
            if (utility->public_methods_only && !current_method_public) continue;
          }
          int result = analyze(&parser, (const uint8_t *) source, class_name_text,
            class_name_length, statement, state);
          if (result < 0) findings = -1;
          else findings += result;
        }
        if (utility_scan && ((fleek_utility_scan_t *) state)->unsupported_visibility) findings = -1;
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
      if (!PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE) || !PM_NODE_TYPE_P(class_node->body, PM_STATEMENTS_NODE)) return false;
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
      fleek_long_parameter_state_t state = { maximum, NULL };
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
      if (PM_NODE_TYPE_P(node, PM_BLOCK_NODE)) return fleek_control_condition(((const pm_block_node_t *) node)->body, name, parser, conditional);
      if (PM_NODE_TYPE_P(node, PM_CALL_NODE)) {
        const pm_call_node_t *call = (const pm_call_node_t *) node;
        return call->block != NULL && fleek_control_condition((const pm_node_t *) call->block, name, parser, conditional);
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
      if (PM_NODE_TYPE_P(node, PM_BLOCK_NODE)) return fleek_control_condition_lines(((const pm_block_node_t *) node)->body, name, parser, source, lines, count);
      if (PM_NODE_TYPE_P(node, PM_CALL_NODE)) {
        const pm_call_node_t *call = (const pm_call_node_t *) node;
        return call->block == NULL || fleek_control_condition_lines((const pm_node_t *) call->block, name, parser, source, lines, count);
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
      if (PM_NODE_TYPE_P(node, PM_BLOCK_NODE)) return fleek_parameter_used_outside_condition(parser, ((const pm_block_node_t *) node)->body, name);
      if (PM_NODE_TYPE_P(node, PM_CALL_NODE)) {
        const pm_call_node_t *call = (const pm_call_node_t *) node;
        return fleek_body_uses_name(parser, (const pm_node_t *) call->arguments, name) ||
          (call->block != NULL && fleek_parameter_used_outside_condition(parser, (const pm_node_t *) call->block, name));
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
      int control_parameter_mode = 1;
      return fleek_scan_method_scope(source, length, fleek_method_api_method, &control_parameter_mode, NULL);
    }
    const char *fleek_control_parameter_finding(void) { return fleek_control_parameter_buffer; }
    int fleek_unused_parameters(const char *source, size_t length) {
      fleek_unused_parameters_buffer[0] = 0; fleek_unused_parameters_used = 0;
      int unused_parameter_mode = 2;
      return fleek_scan_method_scope(source, length, fleek_method_api_method, &unused_parameter_mode, NULL);
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
      fleek_utility_scan_t *options = (fleek_utility_scan_t *) data;
      if (options->public_methods_only && !options->method_is_public) return 0;
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
    int fleek_utility_function(const char *source, size_t length, size_t public_methods_only) {
      fleek_utility_function_buffer[0] = 0; fleek_utility_function_used = 0;
      fleek_utility_scan_t options = { public_methods_only != 0, true, false };
      return fleek_scan_method_scope(source, length, fleek_utility_function_method, &options, NULL);
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
      return fleek_scan_method_scope(source, length, fleek_duplicate_method_call_method, &options, NULL);
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
      return fleek_scan_method_scope(source, length, fleek_manual_dispatch_method, NULL, NULL);
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
      if (!fleek_single_block_body_supported(method->body)) return -1;
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
      return fleek_scan_method_scope(source, length, fleek_nil_check_method, NULL, NULL);
    }
    const char *fleek_nil_check_finding(void) { return fleek_nil_check_buffer; }
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
      return fleek_scan_method_scope(source, length, fleek_nested_iterator_method, &state, NULL);
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
      if (!fleek_single_block_body_supported(method->body)) return -1;
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
      return fleek_scan_method_scope(source, length, fleek_feature_envy_method, NULL, NULL);
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
      if (fleek_name_is(parser, method->name, "initialize") || count <= ((fleek_too_many_statements_scan_t *) data)->maximum) return 0;
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
      fleek_too_many_statements_scan_t scan = { maximum, false };
      int result = fleek_scan_method_scope(source, length, fleek_too_many_statements_method, &scan, NULL);
      if (result == -4 && fleek_too_many_statements_used > 0) return -5;
      if (found && !scan.singleton_seen) return fleek_too_many_statements_used > 0 ? -5 : -4;
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

    static bool fleek_duplication_reserve_candidate_nodes(fleek_duplication_method_t *method, size_t required) {
      if (required <= method->data.ast.node_capacity) return true;
      size_t next = method->data.ast.node_capacity == 0 ? 16 : method->data.ast.node_capacity;
      while (next < required) {
        if (next > SIZE_MAX / 2) return false;
        next *= 2;
      }
      if (next > SIZE_MAX / sizeof(const pm_node_t *) || next > SIZE_MAX / sizeof(size_t)) return false;
      const pm_node_t **nodes = realloc(method->data.ast.nodes, next * sizeof(const pm_node_t *));
      if (nodes == NULL) return false;
      method->data.ast.nodes = nodes;
      size_t *tree_starts = realloc(method->data.ast.tree_starts, next * sizeof(size_t));
      if (tree_starts == NULL) return false;
      method->data.ast.tree_starts = tree_starts;
      size_t *tree_ends = realloc(method->data.ast.tree_ends, next * sizeof(size_t));
      if (tree_ends == NULL) return false;
      method->data.ast.tree_ends = tree_ends;
      size_t *node_ends = realloc(method->data.ast.node_ends, next * sizeof(size_t));
      if (node_ends == NULL) return false;
      method->data.ast.node_ends = node_ends;
      int8_t *adjustments = realloc(method->data.ast.mass_adjustments, next * sizeof(int8_t));
      if (adjustments == NULL) return false;
      method->data.ast.mass_adjustments = adjustments;
      method->data.ast.node_capacity = next;
      return true;
    }
    static bool fleek_duplication_reserve_candidate_tree(fleek_duplication_method_t *method, size_t required) {
      if (required <= method->data.ast.tree_capacity) return true;
      size_t next = method->data.ast.tree_capacity == 0 ? 32 : method->data.ast.tree_capacity;
      while (next < required) {
        if (next > SIZE_MAX / 2) return false;
        next *= 2;
      }
      if (next > SIZE_MAX / sizeof(int16_t)) return false;
      int16_t *tree = realloc(method->data.ast.tree, next * sizeof(int16_t));
      if (tree == NULL) return false;
      method->data.ast.tree = tree;
      method->data.ast.tree_capacity = next;
      return true;
    }
    static void fleek_duplication_free_candidate_ast(fleek_duplication_method_t *method) {
      free(method->data.ast.nodes);
      free(method->data.ast.tree_starts);
      free(method->data.ast.tree_ends);
      free(method->data.ast.node_ends);
      free(method->data.ast.mass_adjustments);
      free(method->data.ast.tree);
      method->data.ast.nodes = NULL;
      method->data.ast.tree_starts = NULL;
      method->data.ast.tree_ends = NULL;
      method->data.ast.node_ends = NULL;
      method->data.ast.mass_adjustments = NULL;
      method->data.ast.tree = NULL;
    }
    typedef struct { fleek_duplication_method_t *method; bool overflow; const pm_node_t *parent; } fleek_duplication_ast_t;
    typedef enum {
      FLEEK_DUPLICATION_IDENTITY_NONE,
      FLEEK_DUPLICATION_IDENTITY_CONSTANT,
      FLEEK_DUPLICATION_IDENTITY_INTEGER,
      FLEEK_DUPLICATION_IDENTITY_FLOAT,
      FLEEK_DUPLICATION_IDENTITY_STRING,
      FLEEK_DUPLICATION_IDENTITY_SYMBOL,
      FLEEK_DUPLICATION_IDENTITY_RANGE,
      FLEEK_DUPLICATION_IDENTITY_REGULAR_EXPRESSION,
      FLEEK_DUPLICATION_IDENTITY_INTERPOLATED_REGULAR_EXPRESSION
    } fleek_duplication_identity_t;
    typedef struct {
      size_t name_offset;
      size_t operator_offset;
      int8_t mass_adjustment;
      bool compares_name;
      bool compares_operator;
      bool supported;
      fleek_duplication_identity_t identity;
      size_t identity_offset;
    } fleek_duplication_node_rule_t;
    #define FLEEK_NAMED_NODE_RULE(type, node, mass) [type] = { offsetof(node, name), 0, mass, true, false, true }
    #define FLEEK_OPERATOR_NODE_RULE(type, node, mass) [type] = { offsetof(node, name), offsetof(node, binary_operator), mass, true, true, true }
    // Indexed by Prism node type so support and unconditional Flay mass stay in one table.
    static const fleek_duplication_node_rule_t fleek_duplication_node_rules[PM_SCOPE_NODE + 1] = {
      [PM_MULTI_WRITE_NODE] = { 0, 0, 2, false, false, true },
      FLEEK_NAMED_NODE_RULE(PM_LOCAL_VARIABLE_READ_NODE, pm_local_variable_read_node_t, 0),
      FLEEK_NAMED_NODE_RULE(PM_LOCAL_VARIABLE_WRITE_NODE, pm_local_variable_write_node_t, 0),
      FLEEK_OPERATOR_NODE_RULE(PM_LOCAL_VARIABLE_OPERATOR_WRITE_NODE, pm_local_variable_operator_write_node_t, 2),
      FLEEK_NAMED_NODE_RULE(PM_LOCAL_VARIABLE_AND_WRITE_NODE, pm_local_variable_and_write_node_t, 2),
      FLEEK_NAMED_NODE_RULE(PM_LOCAL_VARIABLE_OR_WRITE_NODE, pm_local_variable_or_write_node_t, 2),
      FLEEK_NAMED_NODE_RULE(PM_LOCAL_VARIABLE_TARGET_NODE, pm_local_variable_target_node_t, 0),
      FLEEK_NAMED_NODE_RULE(PM_INSTANCE_VARIABLE_READ_NODE, pm_instance_variable_read_node_t, 0),
      FLEEK_NAMED_NODE_RULE(PM_INSTANCE_VARIABLE_WRITE_NODE, pm_instance_variable_write_node_t, 0),
      FLEEK_OPERATOR_NODE_RULE(PM_INSTANCE_VARIABLE_OPERATOR_WRITE_NODE, pm_instance_variable_operator_write_node_t, 2),
      FLEEK_NAMED_NODE_RULE(PM_CLASS_VARIABLE_READ_NODE, pm_class_variable_read_node_t, 0),
      FLEEK_OPERATOR_NODE_RULE(PM_CLASS_VARIABLE_OPERATOR_WRITE_NODE, pm_class_variable_operator_write_node_t, 2),
      FLEEK_NAMED_NODE_RULE(PM_CLASS_VARIABLE_AND_WRITE_NODE, pm_class_variable_and_write_node_t, 2),
      FLEEK_NAMED_NODE_RULE(PM_CLASS_VARIABLE_OR_WRITE_NODE, pm_class_variable_or_write_node_t, 2),
      FLEEK_NAMED_NODE_RULE(PM_CLASS_VARIABLE_WRITE_NODE, pm_class_variable_write_node_t, 0),
      [PM_MULTI_TARGET_NODE] = { 0, 0, 0, false, false, true },
      [PM_CALL_NODE] = { 0, 0, 0, false, false, true, FLEEK_DUPLICATION_IDENTITY_CONSTANT, offsetof(pm_call_node_t, name) },
      [PM_STRING_NODE] = { 0, 0, 0, false, false, true, FLEEK_DUPLICATION_IDENTITY_STRING, offsetof(pm_string_node_t, unescaped) },
      [PM_INTERPOLATED_STRING_NODE] = { 0, 0, 0, false, false, true },
      [PM_EMBEDDED_VARIABLE_NODE] = { 0, 0, -1, false, false, true },
      [PM_EMBEDDED_STATEMENTS_NODE] = { 0, 0, 0, false, false, true },
      [PM_FLOAT_NODE] = { 0, 0, 0, false, false, true, FLEEK_DUPLICATION_IDENTITY_FLOAT, offsetof(pm_float_node_t, value) },
      [PM_RANGE_NODE] = { .mass_adjustment = -2, .supported = true, .identity = FLEEK_DUPLICATION_IDENTITY_RANGE },
      [PM_SYMBOL_NODE] = { 0, 0, 0, false, false, true, FLEEK_DUPLICATION_IDENTITY_SYMBOL, offsetof(pm_symbol_node_t, unescaped) },
      [PM_INTEGER_NODE] = { 0, 0, 0, false, false, true, FLEEK_DUPLICATION_IDENTITY_INTEGER, offsetof(pm_integer_node_t, value) },
      [PM_TRUE_NODE] = { 0, 0, 0, false, false, true },
      [PM_FALSE_NODE] = { 0, 0, 0, false, false, true },
      [PM_NIL_NODE] = { 0, 0, 0, false, false, true },
      [PM_AND_NODE] = { 0, 0, 0, false, false, true },
      [PM_OR_NODE] = { 0, 0, 0, false, false, true },
      [PM_CONSTANT_READ_NODE] = { 0, 0, 0, false, false, true, FLEEK_DUPLICATION_IDENTITY_CONSTANT, offsetof(pm_constant_read_node_t, name) },
      [PM_CONSTANT_PATH_NODE] = { 0, 0, 0, false, false, true, FLEEK_DUPLICATION_IDENTITY_CONSTANT, offsetof(pm_constant_path_node_t, name) },
      [PM_KEYWORD_HASH_NODE] = { 0, 0, -1, false, false, true },
      [PM_HASH_NODE] = { 0, 0, 0, false, false, true },
      [PM_ASSOC_NODE] = { 0, 0, 0, false, false, true },
      [PM_ARRAY_NODE] = { 0, 0, 0, false, false, true },
      [PM_CASE_NODE] = { 0, 0, 0, false, false, true },
      [PM_WHEN_NODE] = { 0, 0, 1, false, false, true },
      [PM_WHILE_NODE] = { 0, 0, 0, false, false, true },
      [PM_UNTIL_NODE] = { 0, 0, 0, false, false, true },
      [PM_FOR_NODE] = { 0, 0, 0, false, false, true },
      [PM_SELF_NODE] = { 0, 0, 0, false, false, true },
      [PM_SPLAT_NODE] = { 0, 0, 0, false, false, true },
      [PM_BLOCK_NODE] = { 0, 0, -2, false, false, true },
      [PM_BLOCK_PARAMETERS_NODE] = { 0, 0, 0, false, false, true },
      [PM_PARAMETERS_NODE] = { 0, 0, 0, false, false, true },
      [PM_REQUIRED_PARAMETER_NODE] = { 0, 0, 0, false, false, true },
      [PM_OPTIONAL_PARAMETER_NODE] = { 0, 0, 0, false, false, true },
      [PM_INTERPOLATED_REGULAR_EXPRESSION_NODE] = { .mass_adjustment = -1, .supported = true,
        .identity = FLEEK_DUPLICATION_IDENTITY_INTERPOLATED_REGULAR_EXPRESSION },
      [PM_RETURN_NODE] = { 0, 0, 0, false, false, true },
      [PM_YIELD_NODE] = { 0, 0, 0, false, false, true },
      [PM_FORWARDING_SUPER_NODE] = { 0, 0, 0, false, false, true },
      [PM_SUPER_NODE] = { 0, 0, 0, false, false, true },
      [PM_BREAK_NODE] = { 0, 0, 0, false, false, true },
      [PM_REDO_NODE] = { 0, 0, 0, false, false, true },
      [PM_BEGIN_NODE] = { 0, 0, 0, false, false, true },
      [PM_RESCUE_NODE] = { 0, 0, 0, false, false, true },
      [PM_RETRY_NODE] = { 0, 0, 1, false, false, true },
      [PM_ENSURE_NODE] = { 0, 0, -1, false, false, true },
      [PM_NEXT_NODE] = { 0, 0, 1, false, false, true },
      [PM_IF_NODE] = { 0, 0, 0, false, false, true },
      [PM_UNLESS_NODE] = { 0, 0, 0, false, false, true },
      [PM_ELSE_NODE] = { 0, 0, -1, false, false, true },
      [PM_REGULAR_EXPRESSION_NODE] = { .mass_adjustment = 0, .supported = true,
        .identity = FLEEK_DUPLICATION_IDENTITY_REGULAR_EXPRESSION,
        .identity_offset = offsetof(pm_regular_expression_node_t, unescaped) }
    };
    #undef FLEEK_NAMED_NODE_RULE
    #undef FLEEK_OPERATOR_NODE_RULE
    static const fleek_duplication_node_rule_t *fleek_duplication_node_rule(pm_node_type_t type) {
      return type <= PM_SCOPE_NODE && fleek_duplication_node_rules[type].supported ? &fleek_duplication_node_rules[type] : NULL;
    }
    typedef struct {
      bool supported;
      bool compares_name;
      bool optional_name;
      bool has_default;
      bool block_optional_mass;
      bool allow_integer_call_argument;
      size_t name_offset;
      size_t default_offset;
      int8_t mass_adjustment;
    } fleek_duplication_parameter_rule_t;
    // One Prism-indexed table owns method and block parameter support, identity, and mass.
    static const fleek_duplication_parameter_rule_t fleek_duplication_parameter_rules[PM_SCOPE_NODE + 1] = {
      [PM_BLOCK_PARAMETERS_NODE] = { .supported = true, .block_optional_mass = true, .mass_adjustment = 1 },
      [PM_REQUIRED_PARAMETER_NODE] = { .supported = true, .compares_name = true, .name_offset = offsetof(pm_required_parameter_node_t, name) },
      [PM_OPTIONAL_PARAMETER_NODE] = { .supported = true, .compares_name = true, .has_default = true,
        .allow_integer_call_argument = true, .name_offset = offsetof(pm_optional_parameter_node_t, name),
        .default_offset = offsetof(pm_optional_parameter_node_t, value), .mass_adjustment = 2 },
      [PM_REQUIRED_KEYWORD_PARAMETER_NODE] = { .supported = true, .compares_name = true,
        .name_offset = offsetof(pm_required_keyword_parameter_node_t, name), .mass_adjustment = 1 },
      [PM_OPTIONAL_KEYWORD_PARAMETER_NODE] = { .supported = true, .compares_name = true, .has_default = true,
        .name_offset = offsetof(pm_optional_keyword_parameter_node_t, name),
        .default_offset = offsetof(pm_optional_keyword_parameter_node_t, value), .mass_adjustment = 2 },
      [PM_REST_PARAMETER_NODE] = { .supported = true, .compares_name = true, .optional_name = true,
        .name_offset = offsetof(pm_rest_parameter_node_t, name) },
      [PM_KEYWORD_REST_PARAMETER_NODE] = { .supported = true, .compares_name = true, .optional_name = true,
        .name_offset = offsetof(pm_keyword_rest_parameter_node_t, name) },
      [PM_BLOCK_PARAMETER_NODE] = { .supported = true, .compares_name = true, .optional_name = true,
        .name_offset = offsetof(pm_block_parameter_node_t, name) }
    };
    static const fleek_duplication_parameter_rule_t *fleek_duplication_parameter_rule(pm_node_type_t type) {
      return type <= PM_SCOPE_NODE && fleek_duplication_parameter_rules[type].supported ? &fleek_duplication_parameter_rules[type] : NULL;
    }
    static int8_t fleek_duplication_parameter_mass_adjustment(const pm_node_t *node);
    static bool fleek_duplication_variable_node_equal(pm_parser_t *parser, const pm_node_t *left, const pm_node_t *right) {
      const fleek_duplication_node_rule_t *rule = fleek_duplication_node_rule(left->type);
      if (rule == NULL) return true;
      if (rule->compares_name) {
        const pm_constant_id_t left_name = *(const pm_constant_id_t *) ((const uint8_t *) left + rule->name_offset);
        const pm_constant_id_t right_name = *(const pm_constant_id_t *) ((const uint8_t *) right + rule->name_offset);
        if (!fleek_constants_equal(parser, left_name, right_name)) return false;
      }
      if (rule->compares_operator) {
        const pm_constant_id_t left_operator = *(const pm_constant_id_t *) ((const uint8_t *) left + rule->operator_offset);
        const pm_constant_id_t right_operator = *(const pm_constant_id_t *) ((const uint8_t *) right + rule->operator_offset);
        if (!fleek_constants_equal(parser, left_operator, right_operator)) return false;
      }
      return true;
    }
    static void fleek_duplication_collect_class_node(const pm_node_t *node, fleek_duplication_ast_t *ast);
    static bool fleek_duplication_collect_class_child(const pm_node_t *node, void *data) {
      fleek_duplication_collect_class_node(node, (fleek_duplication_ast_t *) data);
      return false;
    }
    static bool fleek_duplication_class_node_supported(const pm_node_t *node) {
      return fleek_duplication_node_rule(node->type) != NULL;
    }
    static void fleek_duplication_collect_class_node(const pm_node_t *node, fleek_duplication_ast_t *ast) {
      if (PM_NODE_TYPE_P(node, PM_ARGUMENTS_NODE)) {
        const pm_node_t *parent = ast->parent; ast->parent = node;
        pm_visit_child_nodes(node, fleek_duplication_collect_class_child, ast);
        ast->parent = parent; return;
      }
      if (PM_NODE_TYPE_P(node, PM_STATEMENTS_NODE) || PM_NODE_TYPE_P(node, PM_PARENTHESES_NODE)) {
        const pm_node_t *parent = ast->parent; ast->parent = node;
        pm_visit_child_nodes(node, fleek_duplication_collect_class_child, ast);
        ast->parent = parent; return;
      }
      bool when_node = PM_NODE_TYPE_P(node, PM_WHEN_NODE);
      if (!fleek_duplication_class_node_supported(node)) { ast->overflow = true; return; }
      size_t tree_required = ast->method->data.ast.tree_count + 2 + (when_node ? 1 : 0);
      if (tree_required < ast->method->data.ast.tree_count ||
          !fleek_duplication_reserve_candidate_nodes(ast->method, ast->method->shape_count + 1) ||
          !fleek_duplication_reserve_candidate_tree(ast->method, tree_required)) { ast->overflow = true; return; }
      size_t index = ast->method->shape_count++;
      ast->method->data.ast.nodes[index] = node;
      const fleek_duplication_node_rule_t *node_rule = fleek_duplication_node_rule(node->type);
      int8_t mass_adjustment = node_rule->mass_adjustment;
      if (fleek_duplication_parameter_rule(node->type) != NULL) mass_adjustment = fleek_duplication_parameter_mass_adjustment(node);
      if (PM_NODE_TYPE_P(node, PM_BLOCK_NODE) && ((const pm_block_node_t *) node)->parameters == NULL) mass_adjustment = 0;
      if (PM_NODE_TYPE_P(node, PM_ASSOC_NODE) && PM_NODE_TYPE_P(ast->parent, PM_HASH_NODE)) mass_adjustment = -1;
      ast->method->data.ast.mass_adjustments[index] = mass_adjustment;
      ast->method->data.ast.tree_starts[index] = ast->method->data.ast.tree_count;
      ast->method->data.ast.tree[ast->method->data.ast.tree_count++] = (int16_t) node->type;
      /* Flay's RubyParser translation wraps every when-condition list in an array node. */
      if (when_node) {
        /* Pinned Prism ends at PM_SCOPE_NODE (152); this cannot collide with node tags. */
        ast->method->data.ast.tree[ast->method->data.ast.tree_count++] = INT16_MIN;
      }
      const pm_node_t *parent = ast->parent; ast->parent = node;
      pm_visit_child_nodes(node, fleek_duplication_collect_class_child, ast);
      ast->parent = parent;
      if (ast->method->data.ast.tree_count == SIZE_MAX ||
          !fleek_duplication_reserve_candidate_tree(ast->method, ast->method->data.ast.tree_count + 1)) {
        ast->overflow = true; return;
      }
      ast->method->data.ast.tree[ast->method->data.ast.tree_count++] = (int16_t) (-(int) node->type - 1);
      ast->method->data.ast.tree_ends[index] = ast->method->data.ast.tree_count;
      ast->method->data.ast.node_ends[index] = ast->method->shape_count;
    }
    static bool fleek_duplication_optional_default_supported(const pm_node_t *node, bool allow_integer_call_argument) {
      if (PM_NODE_TYPE_P(node, PM_CALL_NODE)) {
        const pm_call_node_t *call = (const pm_call_node_t *) node;
        if (call->receiver != NULL || call->block != NULL) return false;
        if (call->arguments == NULL || call->arguments->arguments.size == 0) return true;
        return allow_integer_call_argument && call->arguments->arguments.size == 1 &&
          PM_NODE_TYPE_P(call->arguments->arguments.nodes[0], PM_INTEGER_NODE);
      }
      return PM_NODE_TYPE_P(node, PM_INTEGER_NODE) || PM_NODE_TYPE_P(node, PM_STRING_NODE) ||
        PM_NODE_TYPE_P(node, PM_SYMBOL_NODE) || PM_NODE_TYPE_P(node, PM_TRUE_NODE) ||
        PM_NODE_TYPE_P(node, PM_FALSE_NODE) || PM_NODE_TYPE_P(node, PM_NIL_NODE) ||
        PM_NODE_TYPE_P(node, PM_CONSTANT_READ_NODE);
    }
    static int8_t fleek_duplication_parameter_mass_adjustment(const pm_node_t *node) {
      const fleek_duplication_parameter_rule_t *rule = fleek_duplication_parameter_rule(node->type);
      if (rule == NULL) return 0;
      if (!rule->block_optional_mass) return 0;
      const pm_node_t *parameters = (const pm_node_t *) ((const pm_block_parameters_node_t *) node)->parameters;
      return PM_NODE_TYPE_P(parameters, PM_PARAMETERS_NODE) && ((const pm_parameters_node_t *) parameters)->optionals.size > 0 ? rule->mass_adjustment : 0;
    }
    static bool fleek_duplication_parameter_node_supported(const pm_node_t *node, fleek_duplication_method_t *result) {
      const fleek_duplication_parameter_rule_t *rule = fleek_duplication_parameter_rule(node->type);
      if (rule == NULL) return false;
      if (rule->has_default) {
        const pm_node_t *default_value = *(const pm_node_t *const *) ((const uint8_t *) node + rule->default_offset);
        if (!fleek_duplication_optional_default_supported(default_value, rule->allow_integer_call_argument)) return false;
        if (rule->allow_integer_call_argument && PM_NODE_TYPE_P(default_value, PM_CALL_NODE)) {
          const pm_call_node_t *default_call = (const pm_call_node_t *) default_value;
          if (default_call->arguments != NULL && default_call->arguments->arguments.size > 0 && result->parameter_mass == SIZE_MAX) return false;
          if (default_call->arguments != NULL && default_call->arguments->arguments.size > 0) result->parameter_mass++;
        }
      }
      if (rule->mass_adjustment > 0 && result->parameter_mass > SIZE_MAX - (size_t) rule->mass_adjustment) return false;
      result->parameter_mass += (size_t) rule->mass_adjustment;
      return true;
    }
    static bool fleek_duplication_parameter_array_supported(const pm_node_list_t *nodes, fleek_duplication_method_t *result) {
      for (size_t index = 0; index < nodes->size; index++) if (!fleek_duplication_parameter_node_supported(nodes->nodes[index], result)) return false;
      return true;
    }
    static bool fleek_duplication_method_parameters(const pm_node_t *node, fleek_duplication_method_t *result) {
      if (node == NULL) return true;
      if (!PM_NODE_TYPE_P(node, PM_PARAMETERS_NODE)) return false;
      const pm_parameters_node_t *parameters = (const pm_parameters_node_t *) node;
      return fleek_duplication_parameter_array_supported(&parameters->requireds, result) &&
        fleek_duplication_parameter_array_supported(&parameters->optionals, result) &&
        fleek_duplication_parameter_array_supported(&parameters->posts, result) &&
        fleek_duplication_parameter_array_supported(&parameters->keywords, result) &&
        (parameters->rest == NULL || fleek_duplication_parameter_node_supported(parameters->rest, result)) &&
        (parameters->keyword_rest == NULL || fleek_duplication_parameter_node_supported(parameters->keyword_rest, result)) &&
        (parameters->block == NULL || fleek_duplication_parameter_node_supported((const pm_node_t *) parameters->block, result));
    }
    static bool fleek_duplication_has_optional_method_parameters(const pm_node_t *node) {
      if (node == NULL || !PM_NODE_TYPE_P(node, PM_PARAMETERS_NODE)) return false;
      const pm_parameters_node_t *parameters = (const pm_parameters_node_t *) node;
      if (parameters->optionals.size > 0) return true;
      for (size_t index = 0; index < parameters->keywords.size; index++) {
        if (PM_NODE_TYPE_P(parameters->keywords.nodes[index], PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) return true;
      }
      return false;
    }
    static bool fleek_duplication_class_method(const pm_node_t *node, const uint8_t *source, fleek_duplication_method_t *result) {
      if (!PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      result->parameter_mass = 0;
      result->has_optional_method_parameters = false;
      if (method->receiver != NULL || !fleek_duplication_method_parameters((const pm_node_t *) method->parameters, result) || method->body == NULL || method->equal_loc.start != NULL || !PM_NODE_TYPE_P(method->body, PM_STATEMENTS_NODE)) return false;
      result->body_statement_count = ((const pm_statements_node_t *) method->body)->body.size;
      result->has_optional_method_parameters = fleek_duplication_has_optional_method_parameters((const pm_node_t *) method->parameters);
      fleek_duplication_ast_t ast = { result, false, NULL };
      fleek_duplication_collect_class_node(method->body, &ast);
      if (ast.overflow || result->shape_count == 0) { fleek_duplication_free_candidate_ast(result); return false; }
      result->line = 1;
      result->source_offset = (size_t) (method->def_keyword_loc.start - source);
      for (const uint8_t *cursor = source; cursor < method->def_keyword_loc.start; cursor++) if (*cursor == '\\n') result->line++;
      return true;
    }
    static bool fleek_duplication_constant_path_names(const pm_node_t *constant_path, size_t *count) {
      size_t found = 0;
      const pm_node_t *cursor = constant_path;
      while (cursor != NULL) {
        if (PM_NODE_TYPE_P(cursor, PM_CONSTANT_READ_NODE)) {
          if (found == SIZE_MAX || !fleek_duplication_reserve_names(&fleek_duplication_scope_scratch,
              &fleek_duplication_scope_scratch_capacity, found + 1) || !fleek_duplication_reserve_scope_types(found + 1)) return false;
          fleek_duplication_scope_scratch[found++] = ((const pm_constant_read_node_t *) cursor)->name;
          fleek_duplication_scope_type_scratch[found - 1] = FLEEK_DUPLICATION_MODULE_SCOPE;
          cursor = NULL;
        } else if (PM_NODE_TYPE_P(cursor, PM_CONSTANT_PATH_NODE)) {
          const pm_constant_path_node_t *path = (const pm_constant_path_node_t *) cursor;
          if (path->parent == NULL || found == SIZE_MAX || !fleek_duplication_reserve_names(&fleek_duplication_scope_scratch,
              &fleek_duplication_scope_scratch_capacity, found + 1) || !fleek_duplication_reserve_scope_types(found + 1)) return false;
          fleek_duplication_scope_scratch[found++] = path->name;
          fleek_duplication_scope_type_scratch[found - 1] = FLEEK_DUPLICATION_MODULE_SCOPE;
          cursor = path->parent;
        } else {
          return false;
        }
      }
      if (found == 0) return false;
      for (size_t index = 0; index < found / 2; index++) {
        pm_constant_id_t name = fleek_duplication_scope_scratch[index];
        fleek_duplication_scope_scratch[index] = fleek_duplication_scope_scratch[found - index - 1];
        fleek_duplication_scope_scratch[found - index - 1] = name;
        uint8_t type = fleek_duplication_scope_type_scratch[index];
        fleek_duplication_scope_type_scratch[index] = fleek_duplication_scope_type_scratch[found - index - 1];
        fleek_duplication_scope_type_scratch[found - index - 1] = type;
      }
      *count = found;
      return true;
    }
    static bool fleek_duplication_class_shapes_equal(const fleek_duplication_method_t *left, const fleek_duplication_method_t *right) {
      if (left->shape_count != right->shape_count || left->data.ast.tree_count != right->data.ast.tree_count) return false;
      for (size_t index = 0; index < left->data.ast.tree_count; index++) if (left->data.ast.tree[index] != right->data.ast.tree[index]) return false;
      return true;
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
      for (size_t index = node; index < method->data.ast.node_ends[node]; index++) {
        int8_t adjustment = method->data.ast.mass_adjustments[index];
        if (adjustment < 0) mass -= (size_t) (-adjustment);
        else mass += (size_t) adjustment;
      }
      return mass;
    }
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
    static bool fleek_constants_equal(pm_parser_t *parser, pm_constant_id_t left, pm_constant_id_t right);
    static bool fleek_duplication_scalar_identity_equal(pm_parser_t *parser, const pm_node_t *left, const pm_node_t *right);
    static bool fleek_duplication_optional_defaults_equal(pm_parser_t *parser, const pm_node_t *left, const pm_node_t *right) {
      if (left->type != right->type) return false;
      if (PM_NODE_TYPE_P(left, PM_CALL_NODE)) {
        const pm_call_node_t *left_call = (const pm_call_node_t *) left;
        const pm_call_node_t *right_call = (const pm_call_node_t *) right;
        if (!fleek_duplication_scalar_identity_equal(parser, left, right)) return false;
        size_t left_count = left_call->arguments == NULL ? 0 : left_call->arguments->arguments.size;
        size_t right_count = right_call->arguments == NULL ? 0 : right_call->arguments->arguments.size;
        if (left_count != right_count) return false;
        for (size_t index = 0; index < left_count; index++) {
          const pm_node_t *left_argument = left_call->arguments->arguments.nodes[index];
          const pm_node_t *right_argument = right_call->arguments->arguments.nodes[index];
          if (!PM_NODE_TYPE_P(left_argument, PM_INTEGER_NODE) || !PM_NODE_TYPE_P(right_argument, PM_INTEGER_NODE) ||
              !fleek_duplication_scalar_identity_equal(parser, left_argument, right_argument)) return false;
        }
        return true;
      }
      if (fleek_duplication_node_rule(left->type)->identity != FLEEK_DUPLICATION_IDENTITY_NONE) {
        return fleek_duplication_scalar_identity_equal(parser, left, right);
      }
      return PM_NODE_TYPE_P(left, PM_TRUE_NODE) || PM_NODE_TYPE_P(left, PM_FALSE_NODE) || PM_NODE_TYPE_P(left, PM_NIL_NODE);
    }
    static bool fleek_duplication_optional_parameter_name_equal(pm_parser_t *parser, pm_constant_id_t left, pm_constant_id_t right) {
      return (left == 0 || right == 0) ? left == right : fleek_constants_equal(parser, left, right);
    }
    static bool fleek_duplication_parameter_nodes_equal(pm_parser_t *parser, const pm_node_t *left, const pm_node_t *right, bool compare_default) {
      if (left->type != right->type) return false;
      const fleek_duplication_parameter_rule_t *rule = fleek_duplication_parameter_rule(left->type);
      if (rule == NULL) return true;
      if (rule->compares_name) {
        pm_constant_id_t left_name = *(const pm_constant_id_t *) ((const uint8_t *) left + rule->name_offset);
        pm_constant_id_t right_name = *(const pm_constant_id_t *) ((const uint8_t *) right + rule->name_offset);
        bool names_equal = rule->optional_name ? fleek_duplication_optional_parameter_name_equal(parser, left_name, right_name) : fleek_constants_equal(parser, left_name, right_name);
        if (!names_equal) return false;
      }
      if (compare_default && rule->has_default) {
        const pm_node_t *left_value = *(const pm_node_t *const *) ((const uint8_t *) left + rule->default_offset);
        const pm_node_t *right_value = *(const pm_node_t *const *) ((const uint8_t *) right + rule->default_offset);
        if (!fleek_duplication_optional_defaults_equal(parser, left_value, right_value)) return false;
      }
      return true;
    }
    static bool fleek_duplication_parameter_arrays_equal(pm_parser_t *parser, const pm_node_list_t *left, const pm_node_list_t *right, bool compare_default) {
      if (left->size != right->size) return false;
      for (size_t index = 0; index < left->size; index++) {
        if (!fleek_duplication_parameter_nodes_equal(parser, left->nodes[index], right->nodes[index], compare_default)) return false;
      }
      return true;
    }
    static bool fleek_duplication_parameter_node_shapes_equal(const pm_node_t *left, const pm_node_t *right) {
      if (left->type != right->type) return false;
      const fleek_duplication_parameter_rule_t *rule = fleek_duplication_parameter_rule(left->type);
      if (rule == NULL || !rule->has_default) return true;
      const pm_node_t *left_default = *(const pm_node_t *const *) ((const uint8_t *) left + rule->default_offset);
      const pm_node_t *right_default = *(const pm_node_t *const *) ((const uint8_t *) right + rule->default_offset);
      if (left_default->type != right_default->type) return false;
      if (PM_NODE_TYPE_P(left_default, PM_CALL_NODE)) {
        const pm_call_node_t *left_call = (const pm_call_node_t *) left_default;
        const pm_call_node_t *right_call = (const pm_call_node_t *) right_default;
        size_t left_count = left_call->arguments == NULL ? 0 : left_call->arguments->arguments.size;
        size_t right_count = right_call->arguments == NULL ? 0 : right_call->arguments->arguments.size;
        if (left_count != right_count) return false;
        for (size_t index = 0; index < left_count; index++) {
          if (left_call->arguments->arguments.nodes[index]->type != right_call->arguments->arguments.nodes[index]->type) return false;
        }
      }
      return true;
    }
    static bool fleek_duplication_parameter_array_shapes_equal(const pm_node_list_t *left, const pm_node_list_t *right) {
      if (left->size != right->size) return false;
      for (size_t index = 0; index < left->size; index++) {
        if (!fleek_duplication_parameter_node_shapes_equal(left->nodes[index], right->nodes[index])) return false;
      }
      return true;
    }
    static bool fleek_duplication_optional_keyword_shapes_equal(const pm_node_list_t *left, const pm_node_list_t *right) {
      size_t left_count = 0;
      size_t right_count = 0;
      for (size_t index = 0; index < left->size; index++) if (PM_NODE_TYPE_P(left->nodes[index], PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) left_count++;
      for (size_t index = 0; index < right->size; index++) if (PM_NODE_TYPE_P(right->nodes[index], PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) right_count++;
      if (left_count != right_count) return false;
      size_t left_index = 0;
      size_t right_index = 0;
      while (left_count > 0) {
        while (!PM_NODE_TYPE_P(left->nodes[left_index], PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) left_index++;
        while (!PM_NODE_TYPE_P(right->nodes[right_index], PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) right_index++;
        if (!fleek_duplication_parameter_node_shapes_equal(left->nodes[left_index], right->nodes[right_index])) return false;
        left_index++;
        right_index++;
        left_count--;
      }
      return true;
    }
    static bool fleek_duplication_method_parameter_shapes_equal(const pm_def_node_t *left, const pm_def_node_t *right) {
      if (left->parameters == NULL || right->parameters == NULL) return left->parameters == right->parameters;
      const pm_parameters_node_t *left_parameters = (const pm_parameters_node_t *) left->parameters;
      const pm_parameters_node_t *right_parameters = (const pm_parameters_node_t *) right->parameters;
      return fleek_duplication_parameter_array_shapes_equal(&left_parameters->optionals, &right_parameters->optionals) &&
        fleek_duplication_optional_keyword_shapes_equal(&left_parameters->keywords, &right_parameters->keywords);
    }
    static size_t fleek_duplication_optional_parameter_count(const pm_def_node_t *method) {
      if (method->parameters == NULL) return 0;
      const pm_parameters_node_t *parameters = (const pm_parameters_node_t *) method->parameters;
      size_t count = parameters->optionals.size;
      for (size_t index = 0; index < parameters->keywords.size; index++) {
        if (PM_NODE_TYPE_P(parameters->keywords.nodes[index], PM_OPTIONAL_KEYWORD_PARAMETER_NODE)) count++;
      }
      return count;
    }
    static bool fleek_duplication_method_parameters_equal(pm_parser_t *parser, const pm_def_node_t *left, const pm_def_node_t *right) {
      if (left->parameters == NULL || right->parameters == NULL) return left->parameters == right->parameters;
      const pm_parameters_node_t *left_parameters = (const pm_parameters_node_t *) left->parameters;
      const pm_parameters_node_t *right_parameters = (const pm_parameters_node_t *) right->parameters;
      if ((left_parameters->rest == NULL) != (right_parameters->rest == NULL) ||
          (left_parameters->keyword_rest == NULL) != (right_parameters->keyword_rest == NULL) ||
          (left_parameters->block == NULL) != (right_parameters->block == NULL)) return false;
      if (left_parameters->rest != NULL && !fleek_duplication_parameter_nodes_equal(parser, left_parameters->rest, right_parameters->rest, true)) return false;
      if (left_parameters->keyword_rest != NULL && !fleek_duplication_parameter_nodes_equal(parser, left_parameters->keyword_rest, right_parameters->keyword_rest, true)) return false;
      if (left_parameters->block != NULL && !fleek_duplication_parameter_nodes_equal(parser,
          (const pm_node_t *) left_parameters->block, (const pm_node_t *) right_parameters->block, true)) return false;
      return fleek_duplication_parameter_arrays_equal(parser, &left_parameters->requireds, &right_parameters->requireds, true) &&
        fleek_duplication_parameter_arrays_equal(parser, &left_parameters->optionals, &right_parameters->optionals, true) &&
        fleek_duplication_parameter_arrays_equal(parser, &left_parameters->posts, &right_parameters->posts, true) &&
        fleek_duplication_parameter_arrays_equal(parser, &left_parameters->keywords, &right_parameters->keywords, true);
    }
    static bool fleek_duplication_strings_equal(const pm_string_t *left, const pm_string_t *right) {
      size_t length = pm_string_length(left);
      return length == pm_string_length(right) &&
        (length == 0 || memcmp(pm_string_source(left), pm_string_source(right), length) == 0);
    }
    static bool fleek_duplication_scalar_identity_equal(pm_parser_t *parser, const pm_node_t *left, const pm_node_t *right) {
      const fleek_duplication_node_rule_t *rule = fleek_duplication_node_rule(left->type);
      if (rule->identity == FLEEK_DUPLICATION_IDENTITY_NONE) return true;
      const uint8_t *left_value = (const uint8_t *) left + rule->identity_offset;
      const uint8_t *right_value = (const uint8_t *) right + rule->identity_offset;
      if (rule->identity == FLEEK_DUPLICATION_IDENTITY_CONSTANT) {
        return fleek_constants_equal(parser, *(const pm_constant_id_t *) left_value, *(const pm_constant_id_t *) right_value);
      }
      if (rule->identity == FLEEK_DUPLICATION_IDENTITY_INTEGER) {
        return pm_integer_compare((const pm_integer_t *) left_value, (const pm_integer_t *) right_value) == 0;
      }
      if (rule->identity == FLEEK_DUPLICATION_IDENTITY_FLOAT) {
        return *(const double *) left_value == *(const double *) right_value;
      }
      if (rule->identity == FLEEK_DUPLICATION_IDENTITY_STRING || rule->identity == FLEEK_DUPLICATION_IDENTITY_SYMBOL) {
        const pm_string_t *left_string = (const pm_string_t *) left_value;
        const pm_string_t *right_string = (const pm_string_t *) right_value;
        return fleek_duplication_strings_equal(left_string, right_string);
      }
      if (rule->identity == FLEEK_DUPLICATION_IDENTITY_RANGE) {
        return PM_NODE_FLAG_P(left, PM_RANGE_FLAGS_EXCLUDE_END) == PM_NODE_FLAG_P(right, PM_RANGE_FLAGS_EXCLUDE_END);
      }
      if (rule->identity == FLEEK_DUPLICATION_IDENTITY_REGULAR_EXPRESSION) {
        const pm_string_t *left_string = (const pm_string_t *) left_value;
        const pm_string_t *right_string = (const pm_string_t *) right_value;
        return PM_NODE_FLAGS(left) == PM_NODE_FLAGS(right) && fleek_duplication_strings_equal(left_string, right_string);
      }
      if (rule->identity == FLEEK_DUPLICATION_IDENTITY_INTERPOLATED_REGULAR_EXPRESSION) {
        const pm_interpolated_regular_expression_node_t *left_regex = (const pm_interpolated_regular_expression_node_t *) left;
        const pm_interpolated_regular_expression_node_t *right_regex = (const pm_interpolated_regular_expression_node_t *) right;
        return PM_NODE_FLAGS(left) == PM_NODE_FLAGS(right) && left_regex->parts.size == right_regex->parts.size;
      }
      return true;
    }
    static bool fleek_duplication_class_node_values_equal(pm_parser_t *parser, const pm_node_t *left, const pm_node_t *right) {
      if (left->type != right->type || !fleek_duplication_variable_node_equal(parser, left, right) ||
          !fleek_duplication_parameter_nodes_equal(parser, left, right, false) ||
          !fleek_duplication_scalar_identity_equal(parser, left, right)) return false;
      return true;
    }
    static bool fleek_duplication_class_values_equal(pm_parser_t *parser, const fleek_duplication_method_t *left, const fleek_duplication_method_t *right) {
      for (size_t index = 0; index < left->shape_count; index++) {
        if (!fleek_duplication_class_node_values_equal(parser, left->data.ast.nodes[index], right->data.ast.nodes[index])) return false;
      }
      return true;
    }
    static bool fleek_duplication_class_subtree_values_equal(pm_parser_t *parser, const fleek_duplication_method_t *left,
        size_t left_node, const fleek_duplication_method_t *right, size_t right_node) {
      size_t left_count = left->data.ast.node_ends[left_node] - left_node;
      size_t right_count = right->data.ast.node_ends[right_node] - right_node;
      if (left_count != right_count) return false;
      for (size_t offset = 0; offset < left_count; offset++) {
        const pm_node_t *first = left->data.ast.nodes[left_node + offset];
        const pm_node_t *second = right->data.ast.nodes[right_node + offset];
        if (!fleek_duplication_class_node_values_equal(parser, first, second)) return false;
        if (fleek_duplication_parameter_rule(first->type) != NULL &&
            !fleek_duplication_parameter_nodes_equal(parser, first, second, true)) return false;
      }
      return true;
    }

    static bool fleek_duplication_method(const pm_node_t *node, const uint8_t *source, fleek_duplication_method_t *result) {
      if (!PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;
      const pm_def_node_t *method = (const pm_def_node_t *) node;
      result->parameter_mass = 0;
      result->has_optional_method_parameters = false;
      if (method->receiver != NULL || !fleek_duplication_method_parameters((const pm_node_t *) method->parameters, result) ||
          method->body == NULL || !PM_NODE_TYPE_P(method->body, PM_STATEMENTS_NODE)) return false;
      result->body_statement_count = ((const pm_statements_node_t *) method->body)->body.size;
      result->has_optional_method_parameters = fleek_duplication_has_optional_method_parameters((const pm_node_t *) method->parameters);
      fleek_duplication_ast_t ast = { result, false, NULL };
      fleek_duplication_collect_class_node(method->body, &ast);
      if (ast.overflow || result->shape_count == 0) { fleek_duplication_free_candidate_ast(result); return false; }
      result->line = 1;
      result->source_offset = (size_t) (method->def_keyword_loc.start - source);
      for (const uint8_t *cursor = source; cursor < method->def_keyword_loc.start; cursor++) if (*cursor == '\\n') result->line++;
      return true;
    }

    static bool fleek_duplication_scope_leaf_methods(const pm_node_t *root, const pm_statements_node_t **method_body, size_t *scope_depth) {
      const pm_node_t *current = root;
      *scope_depth = 0;
      while (true) {
        const pm_node_t *constant_path = NULL;
        const pm_node_t *scope_body = NULL;
        uint8_t scope_type = 0;
        if (PM_NODE_TYPE_P(current, PM_CLASS_NODE)) {
          const pm_class_node_t *class_node = (const pm_class_node_t *) current;
          constant_path = class_node->constant_path;
          scope_body = class_node->body;
          scope_type = FLEEK_DUPLICATION_CLASS_SCOPE;
        } else if (PM_NODE_TYPE_P(current, PM_MODULE_NODE)) {
          const pm_module_node_t *module_node = (const pm_module_node_t *) current;
          constant_path = module_node->constant_path;
          scope_body = module_node->body;
          scope_type = FLEEK_DUPLICATION_MODULE_SCOPE;
        }
        if (!PM_NODE_TYPE_P(constant_path, PM_CONSTANT_READ_NODE) || scope_body == NULL ||
            !PM_NODE_TYPE_P(scope_body, PM_STATEMENTS_NODE) || *scope_depth == SIZE_MAX ||
            !fleek_duplication_reserve_names(&fleek_duplication_scope_scratch,
              &fleek_duplication_scope_scratch_capacity, *scope_depth + 1) ||
            !fleek_duplication_reserve_scope_types(*scope_depth + 1)) return false;
        fleek_duplication_scope_scratch[*scope_depth] = ((const pm_constant_read_node_t *) constant_path)->name;
        fleek_duplication_scope_type_scratch[*scope_depth] = scope_type;
        (*scope_depth)++;
        const pm_statements_node_t *body = (const pm_statements_node_t *) scope_body;
        bool methods_only = body->body.size > 0;
        for (size_t index = 0; index < body->body.size; index++) if (!PM_NODE_TYPE_P(body->body.nodes[index], PM_DEF_NODE)) methods_only = false;
        if (methods_only) { *method_body = body; return true; }
        if (body->body.size != 1 || (!PM_NODE_TYPE_P(body->body.nodes[0], PM_CLASS_NODE) &&
            !PM_NODE_TYPE_P(body->body.nodes[0], PM_MODULE_NODE))) return false;
        current = body->body.nodes[0];
      }
    }

    static bool fleek_duplication_collect_class_methods(const pm_node_t *node, const uint8_t *source, fleek_duplication_class_candidates_t *set, bool collect_nested_sibling_scopes) {
      if (!PM_NODE_TYPE_P(node, PM_CLASS_NODE)) return false;
      const pm_class_node_t *class_node = (const pm_class_node_t *) node;
      if (class_node->constant_path == NULL || !PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE) ||
          (class_node->body != NULL && !PM_NODE_TYPE_P(class_node->body, PM_STATEMENTS_NODE))) return false;
      size_t scope_index = set->scope_count++;
      size_t first_candidate = set->count;
      size_t body_count = 0;
      if (class_node->body != NULL) {
        const pm_statements_node_t *body = (const pm_statements_node_t *) class_node->body;
        body_count = body->body.size;
        if (body->body.size == 1 && (PM_NODE_TYPE_P(body->body.nodes[0], PM_CLASS_NODE) ||
            PM_NODE_TYPE_P(body->body.nodes[0], PM_MODULE_NODE))) {
          const pm_statements_node_t *method_body = NULL;
          size_t scope_depth = 0;
          if (!fleek_duplication_scope_leaf_methods(node, &method_body, &scope_depth)) {
            const pm_node_t *nested_scope = body->body.nodes[0];
            if (!PM_NODE_TYPE_P(nested_scope, PM_CLASS_NODE) ||
                !fleek_duplication_collect_class_methods(nested_scope, source, set, false)) {
              fleek_duplication_partial = 1;
              return true;
            }
            for (size_t index = first_candidate; index < set->count; index++) {
              if (!fleek_duplication_prepend_scope_name(&set->candidates[index],
                  ((const pm_constant_read_node_t *) class_node->constant_path)->name, FLEEK_DUPLICATION_CLASS_SCOPE)) return false;
              set->candidates[index].scope_mass++;
              set->scope_lines[index] = fleek_source_line(source, class_node->base.location.start);
            }
            return true;
          }
          size_t first_method_candidate = set->count;
          for (size_t method = 0; method < method_body->body.size; method++) {
            const pm_node_t *method_node = method_body->body.nodes[method];
            if (!fleek_duplication_reserve_next_class_candidate(set) || !fleek_duplication_class_method(method_node, source, &set->candidates[set->count])) {
              fleek_duplication_partial = 1;
              continue;
            }
            if (!fleek_duplication_store_scope_path(&set->candidates[set->count], fleek_duplication_scope_scratch,
                fleek_duplication_scope_type_scratch, scope_depth, FLEEK_DUPLICATION_CLASS_SCOPE)) return false;
            size_t candidate = set->count++;
            set->methods[candidate] = (const pm_def_node_t *) method_node;
            set->scope_indices[candidate] = scope_index;
            set->scope_lines[candidate] = fleek_source_line(source, class_node->base.location.start);
            set->candidates[candidate].scope_kind = 1;
            set->candidates[candidate].scope_mass = scope_depth;
          }
          for (size_t candidate = first_method_candidate; candidate < set->count; candidate++) {
            set->scope_body_counts[candidate] = body_count;
            set->scope_candidate_counts[candidate] = set->count - first_method_candidate;
          }
          return true;
        }
        if (body->body.size > 1) {
          bool only_classes = true;
          size_t class_child_count = 0;
          bool class_siblings_supported = true;
          for (size_t index = 0; index < body->body.size; index++) {
            if (!PM_NODE_TYPE_P(body->body.nodes[index], PM_CLASS_NODE)) {
              only_classes = false;
              if (!PM_NODE_TYPE_P(body->body.nodes[index], PM_DEF_NODE)) fleek_duplication_partial = 1;
              continue;
            }
            class_child_count++;
            const pm_statements_node_t *method_body = NULL;
            size_t scope_depth = 0;
            if (!fleek_duplication_scope_leaf_methods(body->body.nodes[index], &method_body, &scope_depth) || scope_depth == 0) {
              class_siblings_supported = false;
            }
          }
          if (class_child_count > 1) {
            if (collect_nested_sibling_scopes) {
              if (!class_siblings_supported) fleek_duplication_partial = 1;
              for (size_t index = 0; index < body->body.size; index++) {
                if (!PM_NODE_TYPE_P(body->body.nodes[index], PM_CLASS_NODE)) continue;
                const pm_class_node_t *nested_class = (const pm_class_node_t *) body->body.nodes[index];
                const pm_statements_node_t *method_body = NULL;
                size_t scope_depth = 0;
                if (!fleek_duplication_scope_leaf_methods((const pm_node_t *) nested_class, &method_body, &scope_depth)) {
                  fleek_duplication_partial = 1;
                  continue;
                }
                size_t sibling_scope_index = set->scope_count++;
                size_t first_sibling_candidate = set->count;
                for (size_t method = 0; method < method_body->body.size; method++) {
                  const pm_node_t *method_node = method_body->body.nodes[method];
                  if (!fleek_duplication_reserve_next_class_candidate(set) || !fleek_duplication_class_method(method_node, source, &set->candidates[set->count])) {
                    fleek_duplication_partial = 1;
                    continue;
                  }
                  if (!fleek_duplication_store_scope_path(&set->candidates[set->count], fleek_duplication_scope_scratch,
                      fleek_duplication_scope_type_scratch, scope_depth, FLEEK_DUPLICATION_CLASS_SCOPE)) return false;
                  size_t candidate = set->count++;
                  set->methods[candidate] = (const pm_def_node_t *) method_node;
                  set->scope_indices[candidate] = sibling_scope_index;
                  set->scope_lines[candidate] = fleek_source_line(source, nested_class->base.location.start);
                  set->candidates[candidate].scope_kind = 1;
                  set->candidates[candidate].scope_mass = scope_depth;
                }
                size_t sibling_candidate_count = set->count - first_sibling_candidate;
                for (size_t candidate = first_sibling_candidate; candidate < set->count; candidate++) {
                  set->scope_body_counts[candidate] = method_body->body.size;
                  set->scope_candidate_counts[candidate] = sibling_candidate_count;
                }
              }
              size_t first_direct_candidate = set->count;
              for (size_t index = 0; index < body->body.size; index++) {
                const pm_node_t *method_node = body->body.nodes[index];
                if (!PM_NODE_TYPE_P(method_node, PM_DEF_NODE)) continue;
                if (!fleek_duplication_reserve_next_class_candidate(set) || !fleek_duplication_class_method(method_node, source, &set->candidates[set->count])) {
                  fleek_duplication_partial = 1;
                  continue;
                }
                size_t candidate = set->count++;
                set->methods[candidate] = (const pm_def_node_t *) method_node;
                set->scope_indices[candidate] = scope_index;
                set->scope_lines[candidate] = fleek_source_line(source, class_node->base.location.start);
                set->candidates[candidate].scope_kind = 1;
                set->candidates[candidate].scope_mass = 1;
                pm_constant_id_t class_name = ((const pm_constant_read_node_t *) class_node->constant_path)->name;
                if (!fleek_duplication_store_scope_names(&set->candidates[candidate], &class_name, 1,
                    FLEEK_DUPLICATION_CLASS_SCOPE)) return false;
              }
              for (size_t candidate = first_direct_candidate; candidate < set->count; candidate++) {
                set->scope_body_counts[candidate] = body_count;
                set->scope_candidate_counts[candidate] = set->count - first_direct_candidate;
              }
              return true;
            }
            if (only_classes) {
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
                if (!direct_methods && nested_body->body.size == 1 && PM_NODE_TYPE_P(nested_body->body.nodes[0], PM_CLASS_NODE)) {
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
                  if (!PM_NODE_TYPE_P(method_node, PM_DEF_NODE) || !fleek_duplication_reserve_next_class_candidate(set) ||
                      !fleek_duplication_class_method(method_node, source, &set->candidates[set->count])) {
                    fleek_duplication_partial = 1; siblings_complete = false; continue;
                  }
                  size_t candidate = set->count++;
                  set->methods[candidate] = (const pm_def_node_t *) method_node;
                  set->scope_indices[candidate] = scope_index;
                  set->candidates[candidate].scope_kind = 1;
                  pm_constant_id_t sibling_names[3] = { ((const pm_constant_read_node_t *) class_node->constant_path)->name,
                    ((const pm_constant_read_node_t *) nested_class->constant_path)->name, inner_name };
                  if (!fleek_duplication_store_scope_names(&set->candidates[candidate], sibling_names, inner_name == 0 ? 2 : 3,
                      FLEEK_DUPLICATION_CLASS_SCOPE)) return false;
                  set->candidates[candidate].scope_mass = inner_name == 0 ? 1 : 2;
                }
              }
              for (size_t index = sibling_first_candidate; index < set->count; index++) {
                set->candidates[index].scope_mass++;
                set->scope_lines[index] = fleek_source_line(source, class_node->base.location.start);
                set->scope_body_counts[index] = set->count - sibling_first_candidate + (siblings_complete ? 0 : 1);
                set->scope_candidate_counts[index] = set->count - sibling_first_candidate;
              }
              return true;
            }
          }
        }
        for (size_t index = 0; index < body->body.size; index++) {
          const pm_node_t *child = body->body.nodes[index];
          if (!PM_NODE_TYPE_P(child, PM_DEF_NODE)) { fleek_duplication_partial = 1; continue; }
          if (!fleek_duplication_reserve_next_class_candidate(set) ||
              !fleek_duplication_class_method(child, source, &set->candidates[set->count])) { fleek_duplication_partial = 1; continue; }
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
        pm_constant_id_t class_name = ((const pm_constant_read_node_t *) class_node->constant_path)->name;
        if (!fleek_duplication_store_scope_names(&set->candidates[index], &class_name, 1, FLEEK_DUPLICATION_CLASS_SCOPE)) return false;
        set->candidates[index].scope_mass = 1;
      }
      return true;
    }
    static bool fleek_duplication_collect_namespace_methods(const pm_module_node_t *scope_node, size_t scope_depth, const pm_statements_node_t *body, const uint8_t *source, fleek_duplication_class_candidates_t *set) {
      size_t scope_index = set->scope_count++;
      size_t first_candidate = set->count;
      size_t body_count = body->body.size;
      for (size_t index = 0; index < body->body.size; index++) {
        const pm_node_t *child = body->body.nodes[index];
        if (PM_NODE_TYPE_P(child, PM_NIL_NODE)) continue;
        if (!PM_NODE_TYPE_P(child, PM_DEF_NODE) || !fleek_duplication_reserve_next_class_candidate(set) ||
            !fleek_duplication_class_method(child, source, &set->candidates[set->count])) {
          fleek_duplication_partial = 1;
          continue;
        }
        if (!fleek_duplication_store_scope_path(&set->candidates[set->count], fleek_duplication_scope_scratch,
            fleek_duplication_scope_type_scratch, scope_depth, FLEEK_DUPLICATION_MODULE_SCOPE)) return false;
        set->methods[set->count] = (const pm_def_node_t *) child;
        set->scope_indices[set->count] = scope_index;
        set->scope_lines[set->count] = fleek_source_line(source, scope_node->base.location.start);
        set->candidates[set->count].scope_kind = 2;
        set->candidates[set->count].scope_mass = scope_depth;
        set->count++;
      }
      for (size_t index = first_candidate; index < set->count; index++) {
        set->scope_body_counts[index] = body_count;
        set->scope_candidate_counts[index] = set->count - first_candidate;
      }
      return true;
    }

    static bool fleek_duplication_collect_nested_module_methods(const pm_module_node_t *scope_node, const pm_module_node_t *current, size_t depth, const uint8_t *source, fleek_duplication_class_candidates_t *set) {
      while (true) {
        if (!PM_NODE_TYPE_P(current->constant_path, PM_CONSTANT_READ_NODE)) { fleek_duplication_partial = 1; return true; }
        if (depth == SIZE_MAX || !fleek_duplication_reserve_names(&fleek_duplication_scope_scratch,
            &fleek_duplication_scope_scratch_capacity, depth + 1) || !fleek_duplication_reserve_scope_types(depth + 1)) return false;
        fleek_duplication_scope_scratch[depth] = ((const pm_constant_read_node_t *) current->constant_path)->name;
        fleek_duplication_scope_type_scratch[depth] = FLEEK_DUPLICATION_MODULE_SCOPE;
        depth++;
        if (current->body == NULL) return true;
        if (!PM_NODE_TYPE_P(current->body, PM_STATEMENTS_NODE)) return false;
        const pm_statements_node_t *body = (const pm_statements_node_t *) current->body;
        bool has_method = false;
        for (size_t index = 0; index < body->body.size; index++) if (PM_NODE_TYPE_P(body->body.nodes[index], PM_DEF_NODE)) has_method = true;
        if (has_method) return fleek_duplication_collect_namespace_methods(scope_node, depth, body, source, set);
        if (body->body.size == 1 && PM_NODE_TYPE_P(body->body.nodes[0], PM_MODULE_NODE)) {
          current = (const pm_module_node_t *) body->body.nodes[0];
          continue;
        }
        if (body->body.size == 1 && PM_NODE_TYPE_P(body->body.nodes[0], PM_CLASS_NODE)) {
          const pm_class_node_t *class_node = (const pm_class_node_t *) body->body.nodes[0];
          if (!PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE)) { fleek_duplication_partial = 1; return true; }
          size_t first_candidate = set->count;
          if (!fleek_duplication_collect_class_methods((const pm_node_t *) class_node, source, set, true)) return false;
          for (size_t index = first_candidate; index < set->count; index++) {
            for (size_t name = depth; name > 0; name--) if (!fleek_duplication_prepend_scope_name(&set->candidates[index],
                fleek_duplication_scope_scratch[name - 1], FLEEK_DUPLICATION_MODULE_SCOPE)) return false;
            set->candidates[index].scope_kind = 2;
            set->candidates[index].scope_mass += depth;
            set->scope_lines[index] = fleek_source_line(source, scope_node->base.location.start);
          }
          return true;
        }
        if (body->body.size != 0) fleek_duplication_partial = 1;
        return true;
      }
    }

    static bool fleek_duplication_collect_qualified_namespace_classes(const pm_module_node_t *module_node, size_t module_name_count, const pm_statements_node_t *body, const uint8_t *source, fleek_duplication_class_candidates_t *set) {
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
            !fleek_duplication_collect_class_methods(child, source, set, true)) { fleek_duplication_partial = 1; module_complete = false; continue; }
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
          for (size_t name = module_name_count; name > 0; name--) {
            if (!fleek_duplication_prepend_scope_name(&set->candidates[candidate], fleek_duplication_scope_scratch[name - 1],
                FLEEK_DUPLICATION_MODULE_SCOPE)) return false;
          }
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
      size_t module_name_count = 0;
      if (!fleek_duplication_constant_path_names(module_node->constant_path, &module_name_count)) { fleek_duplication_partial = 1; return true; }
      set->namespace_count++;
      if (module_node->body == NULL) return true;
      if (!PM_NODE_TYPE_P(module_node->body, PM_STATEMENTS_NODE)) return false;
      const pm_statements_node_t *body = (const pm_statements_node_t *) module_node->body;
      if (module_name_count > 1) {
        if (body->body.size == 0) return true;
        if (body->body.size > 1) return fleek_duplication_collect_qualified_namespace_classes(module_node, module_name_count, body, source, set);
        if (!PM_NODE_TYPE_P(body->body.nodes[0], PM_CLASS_NODE)) { fleek_duplication_partial = 1; return true; }
        const pm_class_node_t *class_node = (const pm_class_node_t *) body->body.nodes[0];
        size_t first_candidate = set->count;
        if (class_node->body != NULL && !PM_NODE_TYPE_P(class_node->body, PM_STATEMENTS_NODE)) { fleek_duplication_partial = 1; return true; }
        if (!PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE)) { fleek_duplication_partial = 1; return true; }
        if (!fleek_duplication_collect_class_methods((const pm_node_t *) class_node, source, set, true)) return false;
        for (size_t index = first_candidate; index < set->count; index++) {
          set->candidates[index].scope_kind = 2;
          set->candidates[index].scope_mass = module_name_count + 2;
          for (size_t name = module_name_count; name > 0; name--) {
            if (!fleek_duplication_prepend_scope_name(&set->candidates[index], fleek_duplication_scope_scratch[name - 1],
                FLEEK_DUPLICATION_MODULE_SCOPE)) return false;
          }
          set->scope_lines[index] = fleek_source_line(source, module_node->base.location.start);
        }
        return true;
      }
      for (size_t index = 0; index < body->body.size; index++) {
        if (PM_NODE_TYPE_P(body->body.nodes[index], PM_DEF_NODE)) {
          return fleek_duplication_collect_namespace_methods(module_node, module_name_count, body, source, set);
        }
      }
      if (body->body.size == 1 && PM_NODE_TYPE_P(body->body.nodes[0], PM_MODULE_NODE)) {
        return fleek_duplication_collect_nested_module_methods(module_node,
          (const pm_module_node_t *) body->body.nodes[0], module_name_count, source, set);
      }
      if (body->body.size == 1 && PM_NODE_TYPE_P(body->body.nodes[0], PM_CLASS_NODE)) {
        const pm_node_t *class_node = body->body.nodes[0];
        const pm_statements_node_t *method_body = NULL;
        size_t scope_depth = 0;
        bool nested_module = false;
        if (fleek_duplication_scope_leaf_methods(class_node, &method_body, &scope_depth)) {
          for (size_t index = 0; index < scope_depth; index++) {
            if (fleek_duplication_scope_type_scratch[index] == FLEEK_DUPLICATION_MODULE_SCOPE) nested_module = true;
          }
        }
        if (nested_module) {
          size_t first_candidate = set->count;
          pm_constant_id_t module_name = ((const pm_constant_read_node_t *) module_node->constant_path)->name;
          if (!fleek_duplication_collect_class_methods(class_node, source, set, true)) return false;
          for (size_t index = first_candidate; index < set->count; index++) {
            if (!fleek_duplication_prepend_scope_name(&set->candidates[index], module_name,
                FLEEK_DUPLICATION_MODULE_SCOPE)) return false;
            set->candidates[index].scope_kind = 2;
            set->candidates[index].scope_mass += module_name_count;
            set->scope_lines[index] = fleek_source_line(source, module_node->base.location.start);
          }
          return true;
        }
      }
      for (size_t index = 0; index < body->body.size; index++) {
        const pm_node_t *child = body->body.nodes[index];
        if (PM_NODE_TYPE_P(child, PM_CLASS_NODE)) {
          if (!fleek_duplication_collect_class_methods(child, source, set, true)) return false;
        } else if (!PM_NODE_TYPE_P(child, PM_NIL_NODE)) {
          fleek_duplication_partial = 1;
        }
      }
      return true;
    }

    static size_t fleek_duplication_class_method_mass(const fleek_duplication_method_t *method) {
      size_t mass = 2 + method->shape_count + method->parameter_mass;
      for (size_t index = 0; index < method->shape_count; index++) {
        if (PM_NODE_TYPE_P(method->data.ast.nodes[index], PM_INTERPOLATED_STRING_NODE)) mass--;
      }
      for (size_t index = 0; index < method->shape_count; index++) {
        int8_t adjustment = method->data.ast.mass_adjustments[index];
        // Flay counts the optional block-list wrapper once across optional method and block defaults.
        if (method->has_optional_method_parameters && PM_NODE_TYPE_P(method->data.ast.nodes[index], PM_BLOCK_PARAMETERS_NODE) && adjustment > 0) adjustment--;
        if (adjustment < 0) mass -= (size_t) (-adjustment);
        else mass += (size_t) adjustment;
        if (PM_NODE_TYPE_P(method->data.ast.nodes[index], PM_BEGIN_NODE)) {
          const pm_begin_node_t *begin_node = (const pm_begin_node_t *) method->data.ast.nodes[index];
          if (begin_node->rescue_clause != NULL && begin_node->ensure_clause != NULL) {
            // RubyParser's composed wrapper weight is shared across method candidates.
            mass += 2;
            if (begin_node->rescue_clause->reference != NULL) mass += 1;
          }
        }
      }
      return mass;
    }
    static bool fleek_duplication_composed_exception(const fleek_duplication_method_t *method, size_t node) {
      if (!PM_NODE_TYPE_P(method->data.ast.nodes[node], PM_BEGIN_NODE)) return false;
      const pm_begin_node_t *begin_node = (const pm_begin_node_t *) method->data.ast.nodes[node];
      return begin_node->rescue_clause != NULL && begin_node->ensure_clause != NULL;
    }
    static size_t fleek_duplication_source_file(const char *file_offsets, size_t offset) {
      size_t file = 0;
      const char *cursor = file_offsets;
      while (*cursor != 0) {
        char *end = NULL;
        unsigned long long boundary = strtoull(cursor, &end, 10);
        if (end == cursor || (boundary > offset)) break;
        file++;
        if (*end == 0) break;
        cursor = end + 1;
      }
      return file;
    }
    static int fleek_duplication_emit_composed_exception_group(pm_parser_t *parser, const uint8_t *source,
        const fleek_duplication_method_t *left, const fleek_duplication_method_t *right, int mass_threshold) {
      size_t selected_left = SIZE_MAX;
      size_t selected_right = SIZE_MAX;
      size_t selected_mass = 0;
      for (size_t left_node = 0; left_node < left->shape_count; left_node++) {
        if (!fleek_duplication_composed_exception(left, left_node)) continue;
        size_t mass = fleek_duplication_class_subtree_mass(left, left_node);
        if (mass < (size_t) mass_threshold) continue;
        for (size_t right_node = 0; right_node < right->shape_count; right_node++) {
          if (!fleek_duplication_composed_exception(right, right_node) ||
              fleek_duplication_class_subtree_mass(right, right_node) != mass ||
              !fleek_duplication_class_subtrees_equal(left, left_node, right, right_node)) continue;
          if (mass <= selected_mass) continue;
          selected_left = left_node;
          selected_right = right_node;
          selected_mass = mass;
        }
      }
      if (selected_left == SIZE_MAX) return 0;
      const pm_begin_node_t *begin_node = (const pm_begin_node_t *) left->data.ast.nodes[selected_left];
      const pm_begin_node_t *right_begin_node = (const pm_begin_node_t *) right->data.ast.nodes[selected_right];
      if (begin_node->statements == NULL || begin_node->statements->body.size == 0 ||
          right_begin_node->statements == NULL || right_begin_node->statements->body.size == 0) return 0;
      int lines[2] = {
        fleek_source_line(source, begin_node->statements->body.nodes[0]->location.start),
        fleek_source_line(source, right_begin_node->statements->body.nodes[0]->location.start)
      };
      bool identical = fleek_duplication_class_subtree_values_equal(parser, left, selected_left, right, selected_right);
      // Flay counts three wrapper nodes per :ensure member that Prism does not expose in this subtree.
      return fleek_duplication_append_group("ensure", identical, selected_mass + 3, lines, 2,
        FLEEK_DUPLICATION_GROUP_METHOD, NULL) ? 1 : -1;
    }
    static size_t fleek_duplication_class_block_mass(const fleek_duplication_method_t *method, size_t node) {
      size_t mass = fleek_duplication_class_subtree_mass(method, node);
      if (!method->has_optional_method_parameters) return mass;
      for (size_t index = node; index < method->data.ast.node_ends[node]; index++) {
        if (PM_NODE_TYPE_P(method->data.ast.nodes[index], PM_BLOCK_PARAMETERS_NODE) &&
            method->data.ast.mass_adjustments[index] > 0) return mass + 1;
      }
      return mass;
    }
    typedef struct { bool identical; size_t mass; size_t count; int *lines; } fleek_duplication_iter_group_t;
    static int fleek_duplication_emit_matching_iter_group(pm_parser_t *parser, const uint8_t *source,
        const fleek_duplication_method_t *const *methods, size_t count, int mass_threshold) {
      size_t *offsets = malloc((count + 1) * sizeof(size_t));
      if (offsets == NULL) return -1;
      offsets[0] = 0;
      for (size_t method = 0; method < count; method++) {
        if (methods[method]->shape_count > SIZE_MAX - offsets[method]) { free(offsets); return -1; }
        offsets[method + 1] = offsets[method] + methods[method]->shape_count;
      }
      size_t capacity = offsets[count];
      int *lines = malloc(capacity * sizeof(int));
      size_t *member_methods = malloc(capacity * sizeof(size_t));
      size_t *member_nodes = malloc(capacity * sizeof(size_t));
      bool *grouped = calloc(capacity, sizeof(bool));
      fleek_duplication_iter_group_t *iter_groups = calloc(capacity, sizeof(*iter_groups));
      if (lines == NULL || member_methods == NULL || member_nodes == NULL || grouped == NULL || iter_groups == NULL) {
        free(offsets); free(lines); free(member_methods); free(member_nodes); free(grouped); free(iter_groups); return -1;
      }
      size_t groups = 0;
      for (size_t first_member = 0; first_member < count; first_member++) {
        const fleek_duplication_method_t *first = methods[first_member];
        for (size_t first_node = 0; first_node < first->shape_count; first_node++) {
          if (grouped[offsets[first_member] + first_node]) continue;
          if (!PM_NODE_TYPE_P(first->data.ast.nodes[first_node], PM_BLOCK_NODE)) continue;
          size_t first_mass = fleek_duplication_class_block_mass(first, first_node);
          if (first_mass < (size_t) mass_threshold) continue;
          size_t member_count = 0;
          bool identical = true;
          for (size_t candidate_index = 0; candidate_index < count; candidate_index++) {
            const fleek_duplication_method_t *candidate = methods[candidate_index];
            size_t candidate_node = candidate_index == first_member ? first_node : 0;
            for (; candidate_node < candidate->shape_count; candidate_node++) {
              if (grouped[offsets[candidate_index] + candidate_node] ||
                  !PM_NODE_TYPE_P(candidate->data.ast.nodes[candidate_node], PM_BLOCK_NODE) ||
                  !fleek_duplication_class_subtrees_equal(first, first_node, candidate, candidate_node) ||
                  fleek_duplication_class_block_mass(candidate, candidate_node) != first_mass) continue;
              member_methods[member_count] = candidate_index;
              member_nodes[member_count] = candidate_node;
              lines[member_count++] = fleek_source_line(source, candidate->data.ast.nodes[candidate_node]->location.start);
              if (!fleek_duplication_class_subtree_values_equal(parser, first, first_node, candidate, candidate_node)) identical = false;
            }
          }
          if (member_count < 2) continue;
          iter_groups[groups].lines = malloc(member_count * sizeof(int));
          if (iter_groups[groups].lines == NULL) { groups = SIZE_MAX; break; }
          memcpy(iter_groups[groups].lines, lines, member_count * sizeof(int));
          iter_groups[groups].identical = identical;
          iter_groups[groups].mass = first_mass;
          iter_groups[groups].count = member_count;
          for (size_t member = 0; member < member_count; member++) grouped[offsets[member_methods[member]] + member_nodes[member]] = true;
          groups++;
        }
        if (groups == SIZE_MAX) break;
      }
      if (groups != SIZE_MAX) {
        for (size_t index = 1; index < groups; index++) {
          fleek_duplication_iter_group_t current = iter_groups[index];
          size_t prior = index;
          while (prior > 0 && iter_groups[prior - 1].mass < current.mass) {
            iter_groups[prior] = iter_groups[prior - 1];
            prior--;
          }
          iter_groups[prior] = current;
        }
        for (size_t index = 0; index < groups; index++) {
          if (!fleek_duplication_append_group("iter", iter_groups[index].identical, iter_groups[index].mass,
              iter_groups[index].lines, iter_groups[index].count, FLEEK_DUPLICATION_GROUP_ITER, NULL)) { groups = SIZE_MAX; break; }
        }
      }
      size_t allocated_groups = groups == SIZE_MAX ? capacity : groups;
      if (allocated_groups > capacity) allocated_groups = capacity;
      for (size_t index = 0; index < allocated_groups; index++) free(iter_groups[index].lines);
      free(offsets);
      free(lines);
      free(member_methods);
      free(member_nodes);
      free(grouped);
      free(iter_groups);
      return groups == SIZE_MAX ? -1 : (int) groups;
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
          while (name < set->candidates[candidate].scope_depth &&
              fleek_duplication_scope_path_element_equal(parser, set, prior, candidate, name)) name++;
          if (name == set->candidates[candidate].scope_depth) { duplicate_path = true; break; }
        }
        if (duplicate_path) continue;
        mass += set->candidates[candidate].scope_mass;
        size_t name = 0;
        while (name < common_prefix && fleek_duplication_scope_path_element_equal(parser, set, index, candidate, name)) name++;
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
    static bool fleek_duplication_scope_candidates_match(const fleek_duplication_class_candidates_t *set, size_t left, size_t right, size_t mass_threshold, const char *file_offsets, bool cross_file) {
      if (cross_file && fleek_duplication_source_file(file_offsets, set->candidates[left].source_offset) !=
          fleek_duplication_source_file(file_offsets, set->candidates[right].source_offset)) {
        for (size_t offset = 0; offset < set->scope_candidate_counts[left]; offset++) {
          const fleek_duplication_method_t *candidate = &set->candidates[left + offset];
          for (size_t node = 0; node < candidate->shape_count; node++) {
            if (fleek_duplication_composed_exception(candidate, node)) return false;
          }
        }
      }
      return set->scope_indices[left] != set->scope_indices[right] &&
        fleek_duplication_scope_candidate_first(set, left) && fleek_duplication_scope_candidate_first(set, right) &&
        fleek_duplication_scope_candidate_complete(set, left) && fleek_duplication_scope_candidate_complete(set, right) &&
        set->candidates[left].scope_kind == set->candidates[right].scope_kind &&
        fleek_duplication_scope_types_equal(set, left, right) &&
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
          if (!fleek_duplication_scope_path_element_equal(parser, set, left, right, name)) return false;
        }
      }
      return fleek_constants_equal(parser, first->name, second->name) &&
        fleek_duplication_method_parameters_equal(parser, first, second) &&
        fleek_duplication_class_values_equal(parser, &set->candidates[left], &set->candidates[right]);
    }
    static bool fleek_duplication_has_partial_subtree(const fleek_duplication_class_candidates_t *set, int mass_threshold, const char *file_offsets, bool cross_file) {
      for (size_t left = 0; left < set->count; left++) {
        for (size_t right = left + 1; right < set->count; right++) {
          bool same_shape = fleek_duplication_candidate_shapes_equal(set, left, right);
          size_t mass = fleek_duplication_class_method_mass(&set->candidates[left]);
          if (same_shape && fleek_duplication_scope_candidates_match(set, left, right, (size_t) mass_threshold, file_offsets, cross_file)) continue;
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
    static bool fleek_duplication_emit_scope_groups(pm_parser_t *parser, const fleek_duplication_class_candidates_t *set, int mass_threshold, const char *file_offsets, bool cross_file, bool *covered) {
      bool *grouped = calloc(set->count, sizeof(bool));
      size_t *members = malloc(set->count * sizeof(size_t));
      int *lines = malloc(set->count * sizeof(int));
      if (grouped == NULL || members == NULL || lines == NULL) { free(grouped); free(members); free(lines); return false; }
      bool complete = true;
      for (size_t first = 0; first < set->count; first++) {
        if (grouped[first] || !fleek_duplication_scope_candidate_first(set, first) || !fleek_duplication_scope_candidate_complete(set, first)) continue;
        members[0] = first;
        size_t count = 1;
        for (size_t candidate = first + 1; candidate < set->count; candidate++) {
          if (grouped[candidate] || !fleek_duplication_scope_candidate_first(set, candidate) || !fleek_duplication_scope_candidate_complete(set, candidate) ||
              !fleek_duplication_scope_candidates_match(set, first, candidate, (size_t) mass_threshold, file_offsets, cross_file)) continue;
          members[count++] = candidate;
        }
        if (count < 2) continue;
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
        if (!fleek_duplication_append_group(node, identical, node_mass, lines, count,
            FLEEK_DUPLICATION_GROUP_METHOD, NULL)) { complete = false; break; }
      }
      free(grouped);
      free(members);
      free(lines);
      return complete;
    }
    static int fleek_duplication_emit_fuzzy_pair(pm_parser_t *parser, const uint8_t *source,
        const pm_def_node_t *left_node, const pm_def_node_t *right_node,
        const fleek_duplication_method_t *left, const fleek_duplication_method_t *right, int mass_threshold, int fuzzy);
    static bool fleek_duplication_emit_method_groups(pm_parser_t *parser, const uint8_t *source,
        const fleek_duplication_class_candidates_t *set, int mass_threshold, const bool *covered, bool liberal, int fuzzy) {
      bool *grouped = calloc(set->count, sizeof(bool));
      size_t *members = malloc(set->count * sizeof(size_t));
      int *lines = malloc(set->count * sizeof(int));
      if (grouped == NULL || members == NULL || lines == NULL) { free(grouped); free(members); free(lines); return false; }
      bool complete = true;
      for (size_t first = 0; first < set->count; first++) {
        if (grouped[first]) continue;
        members[0] = first;
        size_t count = 1;
        for (size_t candidate = first + 1; candidate < set->count; candidate++) {
          if (!grouped[candidate] && fleek_duplication_candidate_shapes_equal(set, first, candidate)) members[count++] = candidate;
        }
        if (count < 2) continue;
        bool parameter_shapes_equal = true;
        for (size_t index = 1; index < count; index++) {
          if (!fleek_duplication_method_parameter_shapes_equal(set->methods[members[0]], set->methods[members[index]])) parameter_shapes_equal = false;
        }
        if (!parameter_shapes_equal) {
          for (size_t index = 0; index < count; index++) grouped[members[index]] = true;
          const fleek_duplication_method_t **iter_methods = malloc(count * sizeof(*iter_methods));
          if (iter_methods == NULL) { complete = false; break; }
          for (size_t index = 0; index < count; index++) iter_methods[index] = &set->candidates[members[index]];
          int iter_group = fleek_duplication_emit_matching_iter_group(parser, source, iter_methods, count, mass_threshold);
          free(iter_methods);
          if (iter_group < 0) { complete = false; break; }
          continue;
        }
        for (size_t index = 0; index < count; index++) grouped[members[index]] = true;
        bool pruned = false;
        bool identical = true;
        for (size_t index = 0; index < count; index++) {
          size_t candidate = members[index];
          if (covered[candidate] && !liberal) pruned = true;
          lines[index] = set->candidates[candidate].line;
          if (!fleek_duplication_candidate_values_equal(parser, set, members[0], candidate, false)) identical = false;
        }
        size_t node_mass = fleek_duplication_class_method_mass(&set->candidates[first]);
        if (!pruned && node_mass >= (size_t) mass_threshold &&
            !fleek_duplication_append_group("defn", identical, node_mass, lines, count,
              FLEEK_DUPLICATION_GROUP_METHOD, NULL)) { complete = false; break; }
      }
      if (complete && fuzzy > 0) {
        for (size_t first = 0; first < set->count; first++) {
          if (covered[first] && !liberal) continue;
          for (size_t second = first + 1; second < set->count; second++) {
            if (covered[second] && !liberal) continue;
            int emitted = fleek_duplication_emit_fuzzy_pair(parser, source, set->methods[first], set->methods[second],
              &set->candidates[first], &set->candidates[second], mass_threshold, fuzzy);
            if (emitted < 0) { complete = false; break; }
          }
          if (!complete) break;
        }
      }
      free(grouped);
      free(members);
      free(lines);
      return complete;
    }
    static void fleek_duplication_free_candidate_scope_names(fleek_duplication_class_candidates_t *set) {
      for (size_t candidate = 0; candidate < set->count; candidate++) {
        fleek_duplication_free_candidate_ast(&set->candidates[candidate]);
        free(set->candidates[candidate].scope_names);
        free(set->candidates[candidate].scope_types);
        set->candidates[candidate].scope_names = NULL;
        set->candidates[candidate].scope_types = NULL;
      }
      free(set->methods);
      free(set->candidates);
      free(set->scope_indices);
      free(set->scope_body_counts);
      free(set->scope_candidate_counts);
      free(set->scope_lines);
      set->methods = NULL;
      set->candidates = NULL;
      set->scope_indices = NULL;
      set->scope_body_counts = NULL;
      set->scope_candidate_counts = NULL;
      set->scope_lines = NULL;
      set->capacity = 0;
    }
    static bool fleek_duplication_analyze_scoped_candidates(pm_parser_t *parser, const uint8_t *source,
        const fleek_duplication_class_candidates_t *set, int mass_threshold, bool liberal, int fuzzy, const char *file_offsets, bool cross_file) {
      if (fleek_duplication_has_partial_subtree(set, mass_threshold, file_offsets, cross_file)) return false;
      bool *covered = calloc(set->count, sizeof(bool));
      if (covered == NULL) return false;
      bool complete = fleek_duplication_emit_scope_groups(parser, set, mass_threshold, file_offsets, cross_file, covered) &&
        fleek_duplication_emit_method_groups(parser, source, set, mass_threshold, covered, liberal, fuzzy);
      free(covered);
      return complete;
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

    static bool fleek_duplication_methods_identical(pm_parser_t *parser, const pm_def_node_t *left, const pm_def_node_t *right,
        const fleek_duplication_method_t *left_method, const fleek_duplication_method_t *right_method) {
      return fleek_constants_equal(parser, left->name, right->name) &&
        fleek_duplication_method_parameters_equal(parser, left, right) &&
        fleek_duplication_class_values_equal(parser, left_method, right_method);
    }

    static bool fleek_duplication_tree_without_nodes_equal(const fleek_duplication_method_t *left,
        const size_t *removed, size_t removed_count, const fleek_duplication_method_t *right) {
      size_t removed_nodes = 0;
      for (size_t index = 0; index < removed_count; index++) {
        removed_nodes += left->data.ast.tree_ends[removed[index]] - left->data.ast.tree_starts[removed[index]];
      }
      if (left->data.ast.tree_count - removed_nodes != right->data.ast.tree_count) return false;
      size_t right_index = 0;
      size_t removed_index = 0;
      for (size_t left_index = 0; left_index < left->data.ast.tree_count; left_index++) {
        if (removed_index < removed_count && left_index == left->data.ast.tree_starts[removed[removed_index]]) {
          left_index = left->data.ast.tree_ends[removed[removed_index]] - 1;
          removed_index++;
          continue;
        }
        if (left->data.ast.tree[left_index] != right->data.ast.tree[right_index++]) return false;
      }
      return true;
    }

    static bool fleek_duplication_tree_without_node_equal(const fleek_duplication_method_t *left, size_t removed,
        const fleek_duplication_method_t *right) {
      return fleek_duplication_tree_without_nodes_equal(left, &removed, 1, right);
    }

    static bool fleek_duplication_fuzzy_method_shapes_equal(const pm_def_node_t *left, const pm_def_node_t *right) {
      if (left->parameters == NULL || right->parameters == NULL) return left->parameters == right->parameters;
      const pm_parameters_node_t *left_parameters = (const pm_parameters_node_t *) left->parameters;
      const pm_parameters_node_t *right_parameters = (const pm_parameters_node_t *) right->parameters;
      return fleek_duplication_method_parameter_shapes_equal(left, right) &&
        left_parameters->requireds.size == right_parameters->requireds.size &&
        left_parameters->posts.size == right_parameters->posts.size &&
        left_parameters->keywords.size == right_parameters->keywords.size &&
        (left_parameters->rest == NULL) == (right_parameters->rest == NULL) &&
        (left_parameters->keyword_rest == NULL) == (right_parameters->keyword_rest == NULL) &&
        (left_parameters->block == NULL) == (right_parameters->block == NULL);
    }

    static int fleek_duplication_emit_fuzzy_pair(pm_parser_t *parser, const uint8_t *source,
        const pm_def_node_t *left_node, const pm_def_node_t *right_node,
        const fleek_duplication_method_t *left, const fleek_duplication_method_t *right, int mass_threshold, int fuzzy) {
      if (!fleek_duplication_fuzzy_method_shapes_equal(left_node, right_node)) return 0;
      size_t right_mass = fleek_duplication_class_method_mass(right);
      size_t left_mass = fleek_duplication_class_method_mass(left);
      size_t left_size = 3 + left->body_statement_count;
      size_t right_size = 3 + right->body_statement_count;
      if (left_size > 10 || right_size > 10 || left_mass / left_size > 12 || right_mass / right_size > 12) return 0;
      const fleek_duplication_method_t *methods[2] = { left, right };
      const fleek_duplication_method_t *targets[2] = { right, left };
      size_t masses[2] = { left_mass, right_mass };
      for (size_t side = 0; side < 2; side++) {
        const fleek_duplication_method_t *method = methods[side];
        size_t roots[16];
        size_t root_count = 0;
        for (size_t root = 0; root < method->shape_count && root_count < 16; root = method->data.ast.node_ends[root]) roots[root_count++] = root;
        size_t limit = (size_t) fuzzy < root_count ? (size_t) fuzzy : root_count;
        size_t combinations = (size_t) 1 << root_count;
        for (size_t mask = 1; mask < combinations; mask++) {
          size_t removed[16], removed_count = 0, removed_mass = 0;
          for (size_t index = 0; index < root_count; index++) {
            if ((mask & ((size_t) 1 << index)) == 0) continue;
            removed[removed_count++] = roots[index];
            removed_mass += fleek_duplication_class_subtree_mass(method, roots[index]);
          }
          if (removed_count > limit || masses[side] < removed_mass || masses[side] - removed_mass != masses[1 - side] ||
              masses[1 - side] < (size_t) mass_threshold ||
              !fleek_duplication_tree_without_nodes_equal(method, removed, removed_count, targets[side])) continue;
          int lines[2] = { left->line, right->line };
          int fuzzy_lines[2] = { side == 0 ? left->line : 0, side == 1 ? right->line : 0 };
          return fleek_duplication_append_group("defn", false, masses[1 - side], lines, 2,
            FLEEK_DUPLICATION_GROUP_METHOD, fuzzy_lines) ? 1 : -1;
        }
      }
      return 0;
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

    int fleek_structural_duplication(const char *source, size_t length, int mass_threshold, int liberal, int fuzzy, int cross_file, int legacy, const char *file_offsets) {
      if (fleek_duplication_buffer != NULL) fleek_duplication_buffer[0] = 0;
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
      if (legacy) {
        fleek_legacy_parser_state_t state = { false };
        pm_visit_node(root, fleek_legacy_parser_syntax_supported, &state);
        if (state.unsupported) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_LEGACY_PARSE_ERROR;
        }
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
      size_t top_level_class_count = 0;
      for (size_t index = 0; index < program->statements->body.size; index++) {
        if (PM_NODE_TYPE_P(program->statements->body.nodes[index], PM_CLASS_NODE)) top_level_class_count++;
      }
      bool collect_nested_sibling_scopes = top_level_class_count == 1;
      for (size_t index = 0; index < program->statements->body.size; index++) {
        pm_node_t *statement = program->statements->body.nodes[index];
        if (PM_NODE_TYPE_P(statement, PM_CLASS_NODE)) {
          if (method_count != 0 || ffi_module_count != 0 || !fleek_duplication_collect_class_methods(statement, (const uint8_t *) source, &class_candidates, collect_nested_sibling_scopes)) {
            fleek_duplication_free_candidate_ast(&first_method);
            fleek_duplication_free_candidate_ast(&second_method);
            fleek_duplication_free_candidate_scope_names(&class_candidates);
            pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
          }
          scope_count++;
          continue;
        }
        if (PM_NODE_TYPE_P(statement, PM_MODULE_NODE)) {
          if (method_count != 0 || ffi_module_count != 0) {
            fleek_duplication_free_candidate_ast(&first_method);
            fleek_duplication_free_candidate_ast(&second_method);
            fleek_duplication_free_candidate_scope_names(&class_candidates);
            pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
          }
          if (fleek_ffi_declaration_module(statement, &parser)) {
            if (scope_count != 0 || class_candidates.count != 0) {
              fleek_duplication_free_candidate_scope_names(&class_candidates);
              pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
            }
            ffi_module_count++;
          } else if (!fleek_duplication_collect_namespace_classes(statement, (const uint8_t *) source, &class_candidates)) {
            fleek_duplication_free_candidate_scope_names(&class_candidates);
            pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
          } else {
            scope_count = class_candidates.scope_count;
          }
          continue;
        }
        if (!PM_NODE_TYPE_P(statement, PM_DEF_NODE) || scope_count != 0) {
          if (!PM_NODE_TYPE_P(statement, PM_NIL_NODE)) {
            fleek_duplication_free_candidate_ast(&first_method);
            fleek_duplication_free_candidate_ast(&second_method);
            fleek_duplication_free_candidate_scope_names(&class_candidates);
            pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
          }
          continue;
        }
        if (method_count == 2 || !fleek_duplication_method(statement, (const uint8_t *) source, method_count == 0 ? &first_method : &second_method)) {
          fleek_duplication_free_candidate_ast(&first_method);
          fleek_duplication_free_candidate_ast(&second_method);
          fleek_duplication_free_candidate_scope_names(&class_candidates);
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
        }
        methods[method_count++] = (const pm_def_node_t *) statement;
      }
      if (scope_count != 0) {
        if (method_count != 0) {
          fleek_duplication_free_candidate_scope_names(&class_candidates);
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
        }
        if (class_candidates.count < 2) {
          fleek_duplication_free_candidate_scope_names(&class_candidates);
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
        }
        if (!fleek_duplication_analyze_scoped_candidates(&parser, (const uint8_t *) source, &class_candidates, mass_threshold, liberal, fuzzy, file_offsets, cross_file != 0)) {
          fleek_duplication_free_candidate_scope_names(&class_candidates);
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
        }
        int score = fleek_duplication_total_score;
        fleek_duplication_free_candidate_scope_names(&class_candidates);
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options);
        return score;
      }
      if (class_candidates.namespace_count != 0 && scope_count == 0 && method_count == 0) {
        fleek_duplication_free_candidate_scope_names(&class_candidates);
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
      }
      if (method_count != 2) {
        fleek_duplication_free_candidate_ast(&first_method);
        fleek_duplication_free_candidate_ast(&second_method);
        fleek_duplication_free_candidate_scope_names(&class_candidates);
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
      }
      const pm_def_node_t *first = methods[0];
      const pm_def_node_t *second = methods[1];
      size_t mass = fleek_duplication_class_method_mass(&first_method);
      bool same_shape = fleek_duplication_class_shapes_equal(&first_method, &second_method) &&
        fleek_duplication_optional_parameter_count(first) == fleek_duplication_optional_parameter_count(second) &&
        fleek_duplication_method_parameter_shapes_equal(first, second);
      bool identical = same_shape && fleek_duplication_methods_identical(&parser, first, second, &first_method, &second_method);
      bool methods_cross_file = cross_file && fleek_duplication_source_file(file_offsets, first_method.source_offset) !=
        fleek_duplication_source_file(file_offsets, second_method.source_offset);
      int composed_group = same_shape && methods_cross_file ? fleek_duplication_emit_composed_exception_group(&parser,
        (const uint8_t *) source, &first_method, &second_method, mass_threshold) : 0;
      if (composed_group < 0) {
        fleek_duplication_free_candidate_ast(&first_method);
        fleek_duplication_free_candidate_ast(&second_method);
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
      }
      const fleek_duplication_method_t *iter_methods[2] = { &first_method, &second_method };
      int iter_group = same_shape ? 0 :
        fleek_duplication_emit_matching_iter_group(&parser, (const uint8_t *) source,
          iter_methods, 2, mass_threshold);
      if (iter_group < 0) {
        fleek_duplication_free_candidate_ast(&first_method);
        fleek_duplication_free_candidate_ast(&second_method);
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
      }
      if (fuzzy > 0 && !same_shape && iter_group == 0) {
        int fuzzy_group = fleek_duplication_emit_fuzzy_pair(&parser, (const uint8_t *) source,
          first, second, &first_method, &second_method, mass_threshold, fuzzy);
        if (fuzzy_group < 0) {
          fleek_duplication_free_candidate_ast(&first_method);
          fleek_duplication_free_candidate_ast(&second_method);
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
        }
      }
      if (iter_group == 0 && composed_group == 0 && same_shape && mass >= (size_t) mass_threshold) {
        int lines[2] = { first_method.line, second_method.line };
        if (!fleek_duplication_append_group("defn", identical, mass, lines, 2,
            FLEEK_DUPLICATION_GROUP_METHOD, NULL)) {
          fleek_duplication_free_candidate_ast(&first_method);
          fleek_duplication_free_candidate_ast(&second_method);
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
        }
      }
      int score = fleek_duplication_total_score;
      fleek_duplication_free_candidate_ast(&first_method);
      fleek_duplication_free_candidate_ast(&second_method);
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return score;
    }

    const char *fleek_structural_duplication_finding(void) { return fleek_duplication_buffer == NULL ? "" : fleek_duplication_buffer; }
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
    ffi_func :fleek_unused_private_method, [:str, :size_t], :int
    ffi_func :fleek_unused_private_method_finding, [], :str
    ffi_func :fleek_utility_function, [:str, :size_t, :size_t], :int
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
    ffi_func :fleek_structural_duplication, [:str, :size_t, :int, :int, :int, :int, :int, :str], :int
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
    puts "       fleek --checks flay:StructuralDuplication,reek:ClassVariable [--mass MASS] [--liberal] [--fuzzy [DIFF]] [--legacy] [--reek-config FILE] SOURCE..."
    puts "       fleek --checks reek:ClassVariable [--reek-config FILE] --stdin SOURCE [PATH...]"
    puts "       fleek --checks flay:StructuralDuplication [--mass MASS] [--liberal] [--fuzzy [DIFF]] [--legacy] [--only NODE] SOURCE"
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
    warn "Use long options: --checks, --mass, --liberal, --fuzzy, --legacy, and --reek-config."
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
    files = files.map { |path| normalize_duplication_source_path(path) }.uniq
    included, excluded = partition_flay_sources(files, ignore_patterns)
    DuplicationReport.new(included, errors.sort_by(&:path), [], duplication_mass_threshold(inputs), excluded, nil, nil, false, [], "included", duplication_only_node(inputs), inputs.include?("--liberal"), duplication_fuzzy_distance(inputs), inputs.include?("--legacy"))
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

  def self.duplication_source_input_error(inputs)
    unsupported_option = inputs.find { |input| input.start_with?("-") && input != "--mass" && input != "--only" && input != "--liberal" && input != "--fuzzy" && input != "--legacy" && !input.start_with?("--fuzzy=") }
    return "Unsupported Flay option: #{quote_text(unsupported_option)}" if unsupported_option
    return "flay:StructuralDuplication requires at least one Ruby source path." if duplication_source_paths(inputs).empty?
    ""
  end

  def self.duplication_source_paths(inputs)
    paths = without_option(without_optional_integer_option(without_option(without_option_pairs(without_option_pairs(inputs, "--mass"), "--only"), "--liberal"), "--fuzzy"), "--legacy")
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

  # :reek:TooManyStatements
  def self.run_native_duplication(report)
    source = report.source
    report.result = NativePrism.fleek_structural_duplication(source, source.bytesize, report.mass_threshold, report.liberal ? 1 : 0, report.fuzzy, report.paths.length > 1 ? 1 : 0, report.legacy ? 1 : 0, duplication_file_offsets(report.source_map))
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
    warn "ERROR: unsupported Flay candidate syntax; selected sources must use exactly two top-level methods, bounded methods in simple classes or one-level namespaces, direct methods or one direct class under a sole nested-module chain, nested class chains through parser-supported depth with supported direct-sibling and wrapper forms, or direct classes with supported methods under relative qualified module paths; methods accept positional parameters with supported literal, constant, or bare-call defaults, required post parameters, optional keyword parameters with supported literal or constant defaults, required keyword parameters, and named rest, keyword-rest, and block parameters; block parameter lists accept required and optional parameters with supported defaults; method bodies support bounded case/when/if/else/unless branches, while/until/for loops, boolean AND/OR expressions, yield, return, super, next, break, redo, begin/rescue/retry, and ensure expressions with supported values, static and interpolated regular expression literals, local-variable reads and writes, local-variable operator and logical writes, instance-variable reads, writes, and operator writes, class-variable reads, writes, operator writes, and logical writes, multiple assignments, and splat arguments, using supported call, literal, local-variable-read, and keyword-hash AST forms; unsupported or partial subtree matches are incomplete."
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
    puts "Scope limits: top-level methods, class methods in simple classes and one-level namespaces, direct methods or one direct class under a sole nested-module chain, nested class chains through parser-supported depth with supported direct-sibling and wrapper forms, or direct classes with supported methods under relative qualified module paths; methods accept positional parameters with supported literal, constant, or bare-call defaults, required post parameters, optional keyword parameters with supported literal or constant defaults, required keyword parameters, and named rest, keyword-rest, and block parameters; block parameter lists accept required and optional parameters with supported defaults; method bodies support bounded case/when/if/else/unless branches, while/until/for loops, boolean AND/OR expressions, yield, return, super, next, break, redo, begin/rescue/retry, and ensure expressions with supported values, static and interpolated regular expression literals, local-variable reads and writes, local-variable operator and logical writes, instance-variable reads, writes, and operator writes, class-variable reads, writes, operator writes, and logical writes, multiple assignments, and splat arguments; partial results are marked incomplete; partial subtree groups fail; Flay mass #{mass_threshold}."
  end

  # :reek:BooleanParameter
  def self.print_duplication_report(report, score, combined_report = false)
    print_duplication_header(report, combined_report)
    warn_partial_duplication_results(report)
    groups = print_duplication_results(report, score)
    print_duplication_status(report, groups.empty? ? 0 : score, combined_report)
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
    "IrresponsibleModule" => ["one simple class or module, or one direct Class.new assignment", "%s has no descriptive comment"],
    "LongParameterList" => ["one simple class or module with direct instance methods and supported parameter lists", "%s has %s parameters"],
    "BooleanParameter" => ["one simple class or module with direct instance methods and supported parameter lists", "%s has boolean parameter '%s'"],
    "LongYieldList" => ["one simple class or module with direct instance methods", "%s yields %s parameters"],
    "ControlParameter" => ["simple methods with direct conditionals and one iterator block", "%s is controlled by argument '%s'"],
    "UnusedParameters" => ["simple method parameter lists and supported method bodies with one iterator block", "%s has unused parameter '%s'"],
    "UnusedPrivateMethod" => ["one simple class with direct instance methods and bare private/public/protected visibility", "%s has the unused private instance method '%s'"],
    "UtilityFunction" => ["direct instance methods without inherited overrides", "%s doesn't depend on instance state (maybe move it to another class?)"],
    "DuplicateMethodCall" => ["direct method calls with identical source form", "%s calls '%s' %s times"],
    "ManualDispatch" => ["simple method bodies containing respond_to?", "%s manually dispatches method call"],
    "NilCheck" => ["simple method bodies with nil? or nil comparisons", "%s performs a nil-check"],
    "MissingSafeMethod" => ["direct bang methods without matching non-bang methods", "%s has missing safe method '%s'"],
    "RepeatedConditional" => ["simple method conditions compared within direct top-level classes", "%s tests '%s' at least %s times"],
    "NestedIterators" => ["simple method bodies with block iterators", "%s contains iterators nested %s deep"],
    "FeatureEnvy" => ["simple methods with local-variable receiver calls and self references", "%s refers to '%s' more than self (maybe move it to another class?)"],
    "DataClump" => ["direct instance methods and class << self methods with matching parameter names", "%s takes parameters %s to %s methods"],
    "TooManyConstants" => ["direct constant assignments in one simple class or module, or in a direct nested module within one top-level module", "%s has %s constants"],
    "TooManyInstanceVariables" => ["one simple class, or two direct nested classes within one top-level class", "%s has at least %s instance variables"],
    "TooManyMethods" => ["direct instance methods in one simple class, or in one class with a single direct nested class", "%s has at least %s methods"],
    "TooManyStatements" => ["simple direct and singleton-class method bodies with statement counting", "%s has approx %s statements"],
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
    utility_function = detector == "UtilityFunction"
    visibility_setting = utility_function && configuration.detector_setting(detector, "public_methods_only", path) == "true"
    settings << visibility_setting if utility_function
    result = run_native_reek_detector(detector, source, settings)
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
    when "UnusedPrivateMethod" then NativePrism.fleek_unused_private_method(source, length)
    when "UtilityFunction" then NativePrism.fleek_utility_function(source, length, settings[3] ? 1 : 0)
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
    when "UnusedPrivateMethod" then NativePrism.fleek_unused_private_method_finding
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
    flay_inputs = without_option_pairs(inputs, "--reek-config")
    reek_inputs = without_option(without_option_pairs(without_option_pairs(without_option(without_optional_integer_option(inputs, "--fuzzy"), "--liberal"), "--mass"), "--only"), "--legacy")
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
    warn "Use long options: --checks, --mass, --liberal, and --reek-config."
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
    source_paths = default_profile_source_paths(source_inputs)
    [CheckProfiles.default(configuration, source_paths), ""]
  end

  def self.default_profile_source_paths(source_inputs)
    discover_sources(without_flay_options(source_inputs), ReekConfiguration.new)[0]
  end

  def self.without_flay_options(inputs)
    without_option(without_option_pairs(without_option_pairs(without_option(without_optional_integer_option(inputs, "--fuzzy"), "--liberal"), "--mass"), "--only"), "--legacy")
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

  def self.selected_check_option_error(check, inputs)
    reek_option = inputs.find { |argument| ["--mass", "--only", "--liberal", "--fuzzy", "--legacy"].include?(argument) || argument.start_with?("--fuzzy=") } if check.start_with?("reek:") && !check.include?(FLAY_CHECK)
    return "#{reek_option} applies only to flay:StructuralDuplication." if reek_option
    check == FLAY_CHECK && inputs.include?("--reek-config") ? "--reek-config applies only to Reek checks." : ""
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
