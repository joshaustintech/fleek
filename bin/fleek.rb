# Fleek exposes native CLI usage and reference identities.
class Fleek
  VERSION = "0.1.0"
  # Retains source identity alongside its diagnostic for the text report.
  SourceFailure = Struct.new(:path, :message, :kind)
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
    static int fleek_class_count;
    static int fleek_module_count;
    static int fleek_finding_count;
    static int fleek_unsupported;
    static int fleek_suppressed;
    static int fleek_bad_suppression;
    static const pm_class_node_t *fleek_only_class;
    static const uint8_t *fleek_source_start;

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

    typedef struct { int shapes[128]; size_t shape_count; int line; } fleek_duplication_method_t;

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
      fleek_suppressed = fleek_bad_suppression = 0;
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
      pm_list_node_t *comment_node = parser.comment_list.head;
      while (comment_node != NULL) {
        pm_comment_t *comment = (pm_comment_t *) comment_node;
        int suppression = fleek_comment_suppression(comment);
        if (comment->location.end <= class_node->class_keyword_loc.start && suppression != 0) {
          if (fleek_only_comments_between(comment->location.end, class_node->class_keyword_loc.start)) {
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

    enum { FLEEK_DUPLICATION_UNSUPPORTED_STATEMENT = 0, FLEEK_DUPLICATION_CALL_STATEMENT = 1, FLEEK_DUPLICATION_INTEGER_STATEMENT = 2 };

    static int fleek_duplication_statement_tag(const pm_node_t *node) {
      if (PM_NODE_TYPE_P(node, PM_CALL_NODE)) {
        const pm_call_node_t *call = (const pm_call_node_t *) node;
        if (call->receiver != NULL || call->block != NULL || (call->arguments != NULL && call->arguments->arguments.size != 0)) return FLEEK_DUPLICATION_UNSUPPORTED_STATEMENT;
        return FLEEK_DUPLICATION_CALL_STATEMENT;
      }
      if (PM_NODE_TYPE_P(node, PM_INTEGER_NODE)) return FLEEK_DUPLICATION_INTEGER_STATEMENT;
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
        result->shapes[statement] = tag;
      }
      return true;
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
        } else {
          return false;
        }
      }
      return true;
    }

    int fleek_structural_duplication(const char *source, size_t length, int mass_threshold) {
      fleek_duplication_buffer[0] = 0;
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
      if (program->statements == NULL || program->statements->body.size != 2) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
      }
      fleek_duplication_method_t first_method = {0}, second_method = {0};
      if (!fleek_duplication_method(program->statements->body.nodes[0], (const uint8_t *) source, &first_method) || !fleek_duplication_method(program->statements->body.nodes[1], (const uint8_t *) source, &second_method)) {
        pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return FLEEK_DUPLICATION_UNSUPPORTED_SOURCE;
      }
      const pm_def_node_t *first = (const pm_def_node_t *) program->statements->body.nodes[0];
      const pm_def_node_t *second = (const pm_def_node_t *) program->statements->body.nodes[1];
      size_t mass = 2 + first_method.shape_count;
      bool same_shape = first_method.shape_count == second_method.shape_count;
      for (size_t index = 0; same_shape && index < first_method.shape_count; index++) same_shape = first_method.shapes[index] == second_method.shapes[index];
      bool identical = same_shape && fleek_duplication_methods_identical(&parser, first, second);
      int score = same_shape && mass >= (size_t) mass_threshold ? (int) mass * 2 * (identical ? 2 : 1) : 0;
      if (score > 0) snprintf(fleek_duplication_buffer, sizeof(fleek_duplication_buffer), "%d\t%d\t%zu\t%d\t%s", first_method.line, second_method.line, mass, score, identical ? "identical" : "similar");
      pm_node_destroy(&parser, root);
      pm_parser_free(&parser);
      pm_options_free(&options);
      return score;
    }

    const char *fleek_structural_duplication_finding(void) { return fleek_duplication_buffer; }

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
    puts "Report: stable text v1; diagnostics on stderr; uncovered checks are reported as not run."
  end

  def self.print_analysis_usage
    puts "       fleek --parse-ruby4 SOURCE (parser prototype; runs no checks)"
    puts "       fleek --checks reek:ClassVariable [--reek-config FILE] SOURCE"
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
    warn "Usage: fleek [--help | --version]"
    1
  end

  def self.parse_ruby4_requested?(arguments)
    arguments.length == 2 && arguments[0] == "--parse-ruby4"
  end

  def self.run_structural_duplication(inputs)
    input_error = structural_duplication_input_error(inputs)
    return report_duplication_input_failure(input_error) unless input_error.empty?
    read_and_analyze_duplication(duplication_source_path(inputs), duplication_mass_threshold(inputs))
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
    duplication_path_input_error(duplication_source_paths(inputs))
  end

  def self.duplication_path_input_error(paths)
    return "flay:StructuralDuplication requires exactly one Ruby source file." unless paths.length == 1
    duplication_path_error(paths[0])
  end

  def self.duplication_source_paths(inputs)
    mass_index = duplication_mass_index(inputs)
    inputs.take(mass_index) + inputs.drop([mass_index + 2, inputs.length].min)
  end

  def self.duplication_source_path(inputs)
    duplication_source_paths(inputs)[0]
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

  def self.read_and_analyze_duplication(path, mass_threshold)
    analyze_structural_duplication(path, File.binread(path), mass_threshold)
  rescue SystemCallError
    report_duplication_input_failure("Cannot read source file: #{quote_text(path)}")
  end

  def self.analyze_structural_duplication(path, source, mass_threshold)
    result = NativePrism.fleek_structural_duplication(source, source.bytesize, mass_threshold)
    if result < 0
      print_duplication_header(path, mass_threshold)
      return report_invalid_duplication_source(path, source, result)
    end
    print_duplication_report(path, result, mass_threshold)
  end

  def self.report_invalid_duplication_source(path, source, result)
    return report_unsupported_duplication_source(path) if result == NativePrism::DUPLICATION_UNSUPPORTED_SOURCE

    report_parse_failure(path, source, result)
    report_input_summary(1, 0, 1, 0, "incomplete")
    1
  end

  def self.report_duplication_input_failure(message)
    warn "ERROR: #{message}"
    1
  end

  def self.report_unsupported_duplication_source(path)
    warn "ERROR: #{quote_text(path)}: unsupported Flay candidate syntax; only two parameterless top-level methods with bare calls or integer literal statements are supported."
    report_input_summary(1, 0, 1, 0, "incomplete")
    1
  end

  def self.print_duplication_header(path, mass_threshold)
    print_duplication_metadata(mass_threshold)
    puts "Sources:"
    puts "  Source: #{quote_text(path)} scope=included"
    puts "Duplication:"
  end

  def self.print_duplication_metadata(mass_threshold)
    puts "Fleek report v1"
    puts "References: Flay #{FLAY_REFERENCE}; Reek #{REEK_REFERENCE}; Spinel #{SPINEL_RELEASE}"
    puts "Checks selected: flay:StructuralDuplication"
    puts "Checks run: flay:StructuralDuplication"
    puts "Scope limits: one Ruby file; two parameterless methods; bare calls and integer literals; Flay mass #{mass_threshold}."
  end

  def self.print_duplication_report(path, score, mass_threshold)
    print_duplication_header(path, mass_threshold)
    print_duplication_results(path, score)
    print_duplication_status(score)
  end

  # :reek:ControlParameter
  def self.print_duplication_status(score)
    status = score == 0 ? 0 : 2
    report_input_summary(1, 1, 0, 0, report_state(status))
    status
  end

  def self.print_duplication_results(path, score)
    print_duplication_group(path) if score > 0
    puts "Total duplication score: #{score}"
    puts "File duplication score: #{quote_text(path)} score=#{score}"
  end

  def self.print_duplication_group(path)
    first_line, second_line, _node_mass, group_score, kind = NativePrism.fleek_structural_duplication_finding.split("\t")
    locations = "#{path}:#{first_line},#{path}:#{second_line}"
    puts "  Group: check=\"flay:StructuralDuplication\" node=\"defn\" kind=#{quote_text(kind)} locations=#{quote_text(locations)} mass=#{group_score} score=#{group_score}"
  end

  # :reek:TooManyStatements
  def self.run_class_variable(inputs)
    config_path, source_inputs, option_error = extract_reek_configuration(inputs)
    return report_configuration_error(option_error) unless option_error.empty?
    configuration = ReekConfiguration.load(config_path)
    configuration_error = configuration.error
    return report_configuration_error(configuration_error) unless configuration_error.empty?
    return run_class_variable_with_stdin(source_inputs, configuration) if source_inputs[0] == "--stdin"

    files, errors = discover_sources(source_inputs, configuration)
    return report_disabled_check(files + errors, configuration) if disabled_input?(files, configuration)

    print_text_report_header(files, configuration, "", errors)
    report_input_errors(errors)
    summarize_class_variable_inputs(files, errors, configuration)
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
  def self.print_text_report_header(files, configuration, origin = "", errors = [])
    print_report_identity
    print_selected_check(files, configuration, origin)
    print_report_scope
    print_report_sources(report_sources(files, origin), configuration, errors)
    puts "Findings:"
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

  def self.print_report_sources(selected_files, configuration, errors)
    failed_sources = errors.select { |error| error.kind == :source }
    puts "Sources:"
    print_source_rows(selected_files, configuration, failed_sources)
  end

  def self.print_source_rows(selected_files, configuration, failed_sources)
    if selected_files.empty? && failed_sources.empty?
      puts "  none"
      return
    end
    selected_files.each { |path| print_report_source(path, configuration) }
    print_failed_sources(failed_sources)
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

  def self.summarize_class_variable_inputs(files, errors, configuration)
    excluded = excluded_input_count(files, configuration)
    summarize_class_variable_results(class_variable_input_results(files, errors, configuration), files.length - excluded, excluded)
  end

  # :reek:LongParameterList
  def self.summarize_class_variable_inputs_with_stdin(files, errors, origin, configuration)
    results = class_variable_input_results(files, errors, configuration).unshift(stdin_input_result(origin, configuration))
    excluded = excluded_input_count(files, configuration) + (configuration.excluded_path?(origin) ? 1 : 0)
    summarize_class_variable_results(results, files.length + 1 - excluded, excluded)
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
  def self.summarize_class_variable_results(results, analyzed, excluded)
    status = class_variable_input_status(results)
    if status == 0 && analyzed == 0 && excluded > 0
      warn "ERROR: Reek exclusions removed every selected source; no analysis ran."
      status = 1
    end
    failures = results.count(1)
    analyzed = results.count(0) + results.count(2) - excluded
    selected = analyzed + failures + excluded
    report_input_summary(selected, analyzed, failures, excluded, report_state(status))
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
    warn "ERROR: #{quote_text(path)}: ClassVariable supports one simple class without inheritance or nested classes or modules."
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

  def self.run_selected_checks(arguments)
    inputs = arguments[2..]
    check = arguments[1]
    return run_class_variable(inputs) if check == "reek:ClassVariable"
    return run_structural_duplication(inputs) if check == "flay:StructuralDuplication"
    print_usage_error(input_error(arguments))
  end
end

exit Fleek.run(ARGV)
