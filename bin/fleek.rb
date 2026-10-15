# Fleek exposes native CLI usage and reference identities.
class Fleek
  VERSION = "0.1.0"
  # Retains source identity alongside its diagnostic for the text report.
  SourceFailure = Struct.new(:path, :message, :kind)
  # Carries inputs and locations through structural duplication reporting.
  DuplicationReport = Struct.new(:paths, :errors, :source_map, :mass_threshold, :excluded_paths, :source, :result, :partial, :partial_paths, :source_scope)
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

    static char fleek_parse_message_buffer[512];
    static char fleek_finding_buffer[4096];
    static char fleek_duplication_buffer[128];
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
    } fleek_duplication_method_t;

    typedef struct {
      const pm_def_node_t *methods[24];
      fleek_duplication_method_t candidates[24];
      size_t class_indices[24];
      size_t class_body_counts[24];
      size_t class_candidate_counts[24];
      size_t class_count;
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

    static bool fleek_duplication_collect_class_methods(const pm_node_t *node, const uint8_t *source, fleek_duplication_class_candidates_t *set) {
      if (!PM_NODE_TYPE_P(node, PM_CLASS_NODE)) return false;
      const pm_class_node_t *class_node = (const pm_class_node_t *) node;
      if (class_node->constant_path == NULL || !PM_NODE_TYPE_P(class_node->constant_path, PM_CONSTANT_READ_NODE) ||
          (class_node->body != NULL && !PM_NODE_TYPE_P(class_node->body, PM_STATEMENTS_NODE))) return false;
      size_t class_index = set->class_count++;
      size_t first_candidate = set->count;
      size_t body_count = 0;
      if (class_node->body != NULL) {
        const pm_statements_node_t *body = (const pm_statements_node_t *) class_node->body;
        if (body->body.size > 32) return false;
        body_count = body->body.size;
        for (size_t index = 0; index < body->body.size; index++) {
          const pm_node_t *child = body->body.nodes[index];
          if (!PM_NODE_TYPE_P(child, PM_DEF_NODE)) { fleek_duplication_partial = 1; continue; }
          if (set->count == 24 || !fleek_duplication_class_method(child, source, &set->candidates[set->count])) { fleek_duplication_partial = 1; continue; }
          set->methods[set->count] = (const pm_def_node_t *) child;
          set->class_indices[set->count] = class_index;
          set->count++;
        }
      }
      for (size_t index = first_candidate; index < set->count; index++) {
        set->class_body_counts[index] = body_count;
        set->class_candidate_counts[index] = set->count - first_candidate;
      }
      return true;
    }

    static bool fleek_duplication_collect_namespace_classes(const pm_node_t *node, const uint8_t *source, fleek_duplication_class_candidates_t *set) {
      if (!PM_NODE_TYPE_P(node, PM_MODULE_NODE)) return false;
      const pm_module_node_t *module_node = (const pm_module_node_t *) node;
      if (!PM_NODE_TYPE_P(module_node->constant_path, PM_CONSTANT_READ_NODE)) return false;
      set->namespace_count++;
      if (module_node->body == NULL) return true;
      if (!PM_NODE_TYPE_P(module_node->body, PM_STATEMENTS_NODE)) return false;
      const pm_statements_node_t *body = (const pm_statements_node_t *) module_node->body;
      if (body->body.size > 32) return false;
      for (size_t index = 0; index < body->body.size; index++) {
        const pm_node_t *child = body->body.nodes[index];
        if (PM_NODE_TYPE_P(child, PM_CLASS_NODE)) {
          if (!fleek_duplication_collect_class_methods(child, source, set)) return false;
        } else if (!PM_NODE_TYPE_P(child, PM_NIL_NODE)) {
          fleek_duplication_partial = 1;
        }
      }
      return true;
    }

    static bool fleek_duplication_select_class_pair(const fleek_duplication_class_candidates_t *set, const pm_def_node_t **selected_methods, fleek_duplication_method_t *selected_first, fleek_duplication_method_t *selected_second, int mass_threshold) {
      if (set->count < 2) return false;
      size_t matching_pairs = 0;
      bool possible_class_group = false;
      for (size_t left = 0; left < set->count; left++) {
        for (size_t right = left + 1; right < set->count; right++) {
          bool same_shape = fleek_duplication_class_shapes_equal(&set->candidates[left], &set->candidates[right]) &&
            fleek_duplication_optional_parameter_count(set->methods[left]) == fleek_duplication_optional_parameter_count(set->methods[right]);
          size_t mass = 2 + set->candidates[left].shape_count + set->candidates[left].parameter_mass;
          for (size_t node_index = 0; node_index < set->candidates[left].shape_count; node_index++) if (fleek_duplication_class_node_massless(set->candidates[left].data.ast.nodes[node_index])) mass--;
          if (set->class_indices[left] != set->class_indices[right]) {
            if (same_shape && set->class_body_counts[left] == set->class_body_counts[right] &&
                set->class_body_counts[left] == set->class_candidate_counts[left] &&
                set->class_body_counts[right] == set->class_candidate_counts[right] &&
                mass + 2 >= (size_t) mass_threshold) {
              possible_class_group = true;
              fleek_duplication_partial = 1;
              continue;
            }
          }
          if (!same_shape || mass < (size_t) mass_threshold) {
            for (size_t left_node = 0; left_node < set->candidates[left].shape_count; left_node++) {
              for (size_t right_node = 0; right_node < set->candidates[right].shape_count; right_node++) {
                if (fleek_duplication_class_subtree_mass(&set->candidates[left], left_node) >= (size_t) mass_threshold &&
                    fleek_duplication_class_subtree_mass(&set->candidates[left], left_node) == fleek_duplication_class_subtree_mass(&set->candidates[right], right_node) &&
                    fleek_duplication_class_subtrees_equal(&set->candidates[left], left_node, &set->candidates[right], right_node)) return false;
              }
            }
            continue;
          }
          matching_pairs++;
          *selected_first = set->candidates[left];
          *selected_second = set->candidates[right];
          selected_methods[0] = set->methods[left];
          selected_methods[1] = set->methods[right];
        }
      }
      if (matching_pairs > 1) return false;
      if (matching_pairs == 0) {
        if (possible_class_group) return false;
        *selected_first = set->candidates[0];
        *selected_second = set->candidates[1];
        selected_methods[0] = set->methods[0];
        selected_methods[1] = set->methods[1];
      }
      return true;
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
      size_t class_count = 0;
      size_t ffi_module_count = 0;
      for (size_t index = 0; index < program->statements->body.size; index++) {
        pm_node_t *statement = program->statements->body.nodes[index];
        if (PM_NODE_TYPE_P(statement, PM_CLASS_NODE)) {
          if (method_count != 0 || ffi_module_count != 0 || !fleek_duplication_collect_class_methods(statement, (const uint8_t *) source, &class_candidates)) {
            pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
          }
          class_count++;
          continue;
        }
        if (PM_NODE_TYPE_P(statement, PM_MODULE_NODE)) {
          if (method_count != 0 || ffi_module_count != 0) {
            pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
          }
          if (fleek_ffi_declaration_module(statement, &parser)) {
            if (class_count != 0 || class_candidates.count != 0) {
              pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
            }
            ffi_module_count++;
          } else if (!fleek_duplication_collect_namespace_classes(statement, (const uint8_t *) source, &class_candidates)) {
            pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
          } else {
            class_count = class_candidates.class_count;
          }
          continue;
        }
        if (!PM_NODE_TYPE_P(statement, PM_DEF_NODE) || class_count != 0) {
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
      if (class_count != 0) {
        if (method_count != 0) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
        }
        if (class_candidates.count < 2) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
        }
        if (!fleek_duplication_select_class_pair(&class_candidates, methods, &first_method, &second_method, mass_threshold)) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
        }
        if (fleek_duplication_optional_parameter_count(methods[0]) != fleek_duplication_optional_parameter_count(methods[1])) {
          pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
        }
        method_count = 2;
      }
      if (class_candidates.namespace_count != 0 && class_count == 0 && method_count == 0) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return 0;
      }
      if (method_count != 2) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
      }
      const pm_def_node_t *first = methods[0];
      const pm_def_node_t *second = methods[1];
      size_t mass = 2 + first_method.shape_count + first_method.parameter_mass;
      if (class_count != 0) {
        for (size_t index = 0; index < first_method.shape_count; index++) if (fleek_duplication_class_node_massless(first_method.data.ast.nodes[index])) mass--;
      } else {
        for (size_t index = 0; index < first_method.shape_count; index++) {
          if (first_method.data.shapes[index] == FLEEK_DUPLICATION_RUBY4_AND_STATEMENT) mass += 2;
        }
      }
      bool same_shape = class_count == 0 ? first_method.shape_count == second_method.shape_count : fleek_duplication_class_shapes_equal(&first_method, &second_method);
      for (size_t index = 0; class_count == 0 && same_shape && index < first_method.shape_count; index++) same_shape = first_method.data.shapes[index] == second_method.data.shapes[index];
      bool identical = same_shape && (class_count == 0 ? fleek_duplication_methods_identical(&parser, first, second) : fleek_constants_equal(&parser, first->name, second->name) && fleek_duplication_class_parameters_equal(&parser, first, second) && fleek_duplication_class_values_equal(&parser, &first_method, &second_method));
      int score = same_shape && mass >= (size_t) mass_threshold ? (int) mass * 2 * (identical ? 2 : 1) : 0;
      if (score > 0) snprintf(fleek_duplication_buffer, sizeof(fleek_duplication_buffer), "%d\t%d\t%zu\t%d\t%s", first_method.line, second_method.line, mass * 2, score, identical ? "identical" : "similar");
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
    def initialize
      @error = ""
      @enabled = true
      @excludes = []
      @exclude_paths = []
      @scope_paths = []
      @scope_enabled = []
      @scope_excludes = []
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
      @global_detector = false
      @scope_detector = false
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
      if indentation == 2 && key == "ClassVariable" && value.empty?
        @global_detector = true
        @list_target = ""
      elsif indentation == 2
        fail_config(number, "unsupported enabled detector #{key}")
      elsif @global_detector && indentation == 4
        parse_options(key, value, number, false)
      elsif @global_detector && indentation == 6 && @list_target == "global_excludes"
        append_list_item(value, number)
      else
        fail_config(number, "unsupported detector setting #{key}")
      end
    end

    def parse_directory_field(key, value, number)
      indentation = line_indentation
      if indentation == 2
        return fail_config(number, "directory scope must use a mapping") unless value.empty?
        @scope_paths << scalar(key, number)
        @scope_enabled << ""
      @scope_excludes << ""
        @scope_index = @scope_paths.length - 1
        @scope_detector = false
      elsif indentation == 4 && key == "ClassVariable" && value.empty? && @scope_index >= 0
        @scope_detector = true
      elsif indentation == 4
        fail_config(number, "unsupported enabled directory detector #{key}")
      elsif indentation == 6 && @scope_detector
        parse_options(key, value, number, true)
      elsif indentation == 8 && @scope_detector && @list_target == "scope_excludes"
        append_list_item(value, number)
      else
        fail_config(number, "unsupported directory setting #{key}")
      end
    end

    def parse_exclude_path(key, value, indentation, number)
      fail_config(number, "exclude_paths accepts a YAML list; unexpected key #{key}")
    end

    def parse_options(key, value, number, scoped)
      if key == "enabled" && ["true", "false"].include?(value)
        if scoped
          @scope_enabled[@scope_index] = value
        else
          @enabled = value == "true"
        end
      elsif key == "exclude" && value.empty?
        if scoped
          @scope_excludes[@scope_index] = ""
        else
          @excludes = []
        end
        @list_target = scoped ? "scope_excludes" : "global_excludes"
      elsif key == "exclude" && value == "[]"
        if scoped
          @scope_excludes[@scope_index] = ""
        else
          @excludes = []
        end
      else
        fail_config(number, "unsupported ClassVariable setting #{key}")
      end
    end

    def parse_list_item(content, indentation, number)
      expected = if @list_target == "exclude_paths"
                   2
                 elsif @list_target == "global_excludes"
                   6
                 elsif @list_target == "scope_excludes"
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
        @excludes << item
      elsif @list_target == "scope_excludes"
        @scope_excludes[@scope_index] = "#{@scope_excludes[@scope_index]}#{item}\n"
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
      elsif value.empty? || value.include?("[") || value.include?(",") || value.include?("{") || value.include?("}") || value.include?(": ") || value.end_with?(":")
        fail_config(number, "unsupported YAML scalar")
        ""
      else
        value
      end
    end

    def line_indentation
      @current_indentation
    end

    def fail_config(number, message)
      @error = "#{Fleek.quote_text(@path)}:#{number}: #{message}" if @error.empty?
    end

    def disabled_for?(path)
      index = best_scope(path)
      index >= 0 ? @scope_enabled[index] == "false" : @enabled == false
    end

    def excluded_context?(path, context)
      index = best_scope(path)
      exclusions = index >= 0 ? @scope_excludes[index].split("\n") : @excludes
      exclusions.any? { |excluded| context.include?(excluded) }
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
    puts "Supported checks: reek:ClassVariable and flay:StructuralDuplication; other checks and machine formats are unsupported."
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
    puts "Fleek #{VERSION} (Flay #{FLAY_REFERENCE}; Reek #{REEK_REFERENCE}; Spinel #{SPINEL_RELEASE}; supported checks: reek:ClassVariable, flay:StructuralDuplication; report: text v1)"
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
    return report_duplication_analysis_failure(report, combined_analysis) if result < 0
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
    warn "ERROR: unsupported Flay candidate syntax; selected sources must use exactly two top-level parameterless methods or simple classes with at most 32 direct body entries each and 24 supported class-method candidates total; class methods accept up to 8 required or literal-default optional positional parameters, bounded if/else/unless branches, boolean OR expressions, return statements with supported values, and local-variable assignments (no rest, keyword, or block parameters), using supported call, literal, local-variable-read, and keyword-hash AST forms; unsupported or partial subtree matches are incomplete."
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
    puts "Scope limits: parameterless top-level methods or class methods in simple classes and one-level namespaces with up to 8 required or literal-default optional positional parameters, bounded if/else/unless branches, boolean OR expressions, return statements with supported values, and local-variable assignments; partial results are marked incomplete; partial subtree groups fail; Flay mass #{mass_threshold}."
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
    locations = print_duplication_group(source_map) if score > 0
    puts "Total duplication score: #{score}"
    paths.each { |path| puts "File duplication score: #{quote_text(path)} score=#{duplication_file_score(path, locations, score)}" }
  end

  def self.duplication_file_score(path, locations, score)
    return 0 unless locations
    locations.count { |location| location.start_with?("#{path}:") } * score / 2
  end

  def self.print_duplication_group(source_map)
    first_line, second_line, node_mass, group_score, kind = NativePrism.fleek_structural_duplication_finding.split("\t")
    locations = [duplication_source_location(first_line.to_i, source_map), duplication_source_location(second_line.to_i, source_map)]
    location_text = locations.join(",")
    puts "  Group: check=\"flay:StructuralDuplication\" node=\"defn\" kind=#{quote_text(kind)} locations=#{quote_text(location_text)} mass=#{node_mass} score=#{group_score}"
    locations
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

    raw_files, = combined_run ? discover_sources(source_inputs, ReekConfiguration.new) : [[], []]
    excluded_paths = combined_run ? raw_files.select { |path| configuration.excluded_path?(path) } : []
    files, errors = discover_sources(source_inputs, configuration)
    return report_disabled_check(files + errors, configuration) if disabled_input?(files, configuration)

    print_text_report_header(files, configuration, "", errors, combined_run, excluded_paths)
    report_input_errors(errors)
    summary = ClassVariableSummary.new(files, errors, configuration, combined_run, excluded_paths)
    summarize_class_variable_inputs(summary)
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
  def self.run_combined_checks(inputs)
    analysis = prepare_combined_analysis(inputs)
    error = analysis.error
    return report_combined_input_error(error) unless error.empty?
    disabled_paths = analysis.disabled_paths
    return report_disabled_check(disabled_paths, analysis.configuration) unless disabled_paths.empty?
    print_combined_header
    run_combined_sections(analysis)
  end

  def self.print_combined_header
    print_report_identity
    puts "Checks selected: flay:StructuralDuplication,reek:ClassVariable"
    puts "Checks run: flay:StructuralDuplication,reek:ClassVariable"
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
    config_path, sources, option_error = extract_reek_configuration(inputs)
    return [nil, [], option_error] unless option_error.empty?
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

  def self.run_combined_sections(analysis)
    puts "Duplication section:"
    duplication_status = run_structural_duplication(analysis.flay_inputs, true)
    puts "Smell section:"
    smell_status = run_class_variable(analysis.reek_inputs, true)
    finish_combined_analysis(duplication_status, smell_status)
  end

  def self.finish_combined_analysis(duplication_status, smell_status)
    combined_status = combined_analysis_status(CheckResults.new(duplication_status, smell_status))
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

  def self.run_without_unsupported_format(arguments)
    return parse_ruby4_file(arguments[1]) if parse_ruby4_requested?(arguments)
    return run_selected_checks(arguments) if arguments.length >= 3 && arguments[0] == "--checks"
    return 0 if print_help_if_requested(arguments)
    return 0 if print_version_if_requested(arguments)

    print_usage_error(input_error(arguments))
  end

  # :reek:TooManyStatements
  def self.run_selected_checks(arguments)
    inputs = arguments[2..]
    check = arguments[1]
    return run_class_variable(inputs) if check == "reek:ClassVariable"
    return run_structural_duplication(inputs) if check == "flay:StructuralDuplication"
    return run_combined_checks(inputs) if check == "flay:StructuralDuplication,reek:ClassVariable" || check == "reek:ClassVariable,flay:StructuralDuplication"
    print_usage_error(input_error(arguments))
  end
end

exit Fleek.run(ARGV)
