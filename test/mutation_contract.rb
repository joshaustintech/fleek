# Proves public checks reject deliberately broken parser, CLI, and analyzer behaviors.
MUTATION_SHARD = nil
MUTATION_SHARDS = nil

# Runs one configured source mutation and requires its public contract to fail.
class MutationCase
  # Carries one behavior mutation and its expected contract failure.
  Configuration = Struct.new(:source, :target, :replacement, :label, :expected_failure)
  CONTRACTS = {
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
    "missing Attribute finding" => "test/default_object_scope_contract.rb",
    "missing InstanceVariableAssumption finding" => "test/default_object_scope_contract.rb",
    "missing SubclassedFromCoreClass finding" => "test/default_object_scope_contract.rb",
    "missing ModuleInitialize finding" => "test/default_object_scope_contract.rb",
    "missing IrresponsibleModule finding" => "test/default_object_scope_contract.rb",
    "missing Attribute aliased finding" => "test/default_object_scope_contract.rb",
    "unsupported Class.new assignment" => "test/default_object_scope_contract.rb",
    "comment overflow appeared clean" => "test/default_object_scope_contract.rb",
    "missing LongParameterList finding" => "test/default_argument_api_contract.rb",
    "missing BooleanParameter finding" => "test/default_argument_api_contract.rb",
    "missing LongYieldList finding" => "test/default_argument_api_contract.rb",
    "missing ControlParameter finding" => "test/default_argument_api_contract.rb",
    "wrong ControlParameter lines" => "test/default_argument_api_contract.rb",
    "missing UnusedParameters finding" => "test/default_argument_api_contract.rb",
    "missing UtilityFunction finding" => "test/default_argument_api_contract.rb",
    "missing DuplicateMethodCall finding" => "test/default_argument_api_contract.rb",
    "ignored DuplicateMethodCall list entry" => "test/default_argument_api_contract.rb",
    "missing NilCheck finding" => "test/default_argument_api_contract.rb",
    "missing MissingSafeMethod finding" => "test/default_argument_api_contract.rb",
    "ignored MissingSafeMethod exclusion entry" => "test/default_argument_api_contract.rb",
    "missing RepeatedConditional finding" => "test/default_argument_api_contract.rb",
    "missing NestedIterators finding" => "test/default_argument_api_contract.rb",
    "ignored NestedIterators list entry" => "test/default_argument_api_contract.rb",
    "missing DataClump finding" => "test/default_argument_api_contract.rb",
    "DataClump first-method dependence" => "test/default_argument_api_contract.rb",
    "DataClump first clump only" => "test/default_argument_api_contract.rb",
    "DataClump drops findings on incomplete syntax" => "test/default_argument_api_contract.rb",
    "missing TooManyConstants finding" => "test/default_argument_api_contract.rb",
    "missing TooManyInstanceVariables finding" => "test/default_argument_api_contract.rb",
    "missing &&= instance variable writes" => "test/default_argument_api_contract.rb",
    "missing TooManyMethods finding" => "test/default_argument_api_contract.rb",
    "missing TooManyStatements finding" => "test/default_argument_api_contract.rb",
    "missing UncommunicativeMethodName finding" => "test/default_argument_api_contract.rb",
    "missing UncommunicativeModuleName finding" => "test/default_argument_api_contract.rb",
    "missing UncommunicativeParameterName finding" => "test/default_argument_api_contract.rb",
    "missing UncommunicativeVariableName finding" => "test/default_argument_api_contract.rb",
    "TooManyStatements drops mixed-scope findings" => "test/default_argument_api_contract.rb",
    "TooManyStatements drops findings before unsupported body" => "test/default_argument_api_contract.rb",
    "TooManyMethods partial scope loses incomplete status" => "test/default_argument_api_contract.rb",
    "missing ManualDispatch finding" => "test/default_argument_api_contract.rb",
    "missing FeatureEnvy finding" => "test/default_argument_api_contract.rb",
    "missing LongYieldList block finding" => "test/default_argument_api_contract.rb",
    "Reek directive comment parity" => "test/default_object_scope_contract.rb",
    "Reek directive option parity" => "test/default_object_scope_contract.rb",
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
    "Flay module method candidate collection" => "test/duplication_contract.rb",
    "Flay nested module candidate collection" => "test/duplication_contract.rb",
    "Flay deep nested module candidate collection" => "test/duplication_contract.rb",
    "Flay nested module depth boundary" => "test/duplication_contract.rb",
    "Flay nested namespace class collection" => "test/duplication_contract.rb",
    "Flay nested class scope mass" => "test/duplication_contract.rb",
    "Flay nested class depth boundary" => "test/duplication_contract.rb",
    "Flay nested class sibling mass" => "test/duplication_contract.rb",
    "Flay nested wrapped class siblings" => "test/duplication_contract.rb",
    "Flay nested sibling multi-methods" => "test/duplication_contract.rb",
    "Flay nested sibling path mass" => "test/duplication_contract.rb",
    "Flay qualified namespace class collection" => "test/duplication_contract.rb",
    "Flay qualified namespace multiple classes" => "test/duplication_contract.rb",
    "Flay qualified namespace multiple class mass" => "test/duplication_contract.rb",
    "Flay qualified namespace multi-method boundary" => "test/duplication_contract.rb",
    "Flay qualified namespace class mass" => "test/duplication_contract.rb",
    "Flay qualified namespace class depth" => "test/duplication_contract.rb",
    "Flay outer scope identity" => "test/duplication_contract.rb",
    "Flay module group kind" => "test/duplication_contract.rb",
    "Flay multiple class method candidates" => "test/duplication_contract.rb",
    "Flay preserves independent candidate groups" => "test/duplication_contract.rb",
    "Flay group ordering" => "test/duplication_contract.rb",
    "Flay grouped file score" => "test/duplication_contract.rb",
    "Flay required parameter candidates" => "test/duplication_contract.rb",
    "Flay required parameter arity" => "test/duplication_contract.rb",
    "Flay required parameter identity" => "test/duplication_contract.rb",
    "Flay optional parameter candidates" => "test/duplication_contract.rb",
    "Flay optional default boundary" => "test/duplication_contract.rb",
    "Flay optional symbol default acceptance" => "test/duplication_contract.rb",
    "Flay optional parameter mass" => "test/duplication_contract.rb",
    "Flay optional default identity" => "test/duplication_contract.rb",
    "Flay optional parameter count" => "test/duplication_contract.rb",
    "Flay class method conditional candidates" => "test/duplication_contract.rb",
    "Flay class method unless candidates" => "test/duplication_contract.rb",
    "Flay class method return candidates" => "test/duplication_contract.rb",
    "Flay class method false literal candidates" => "test/duplication_contract.rb",
    "Flay class method OR candidates" => "test/duplication_contract.rb",
    "Flay class method local write candidates" => "test/duplication_contract.rb",
    "Flay class method local write identity" => "test/duplication_contract.rb",
    "Flay class method conditional mass" => "test/duplication_contract.rb",
    "Flay class method candidate capacity" => "test/duplication_contract.rb",
    "Flay multiple class declarations" => "test/duplication_contract.rb",
    "Flay cross-class class-group collection" => "test/duplication_contract.rb",
    "Flay namespace class method collection" => "test/duplication_contract.rb",
    "Flay additional class method rejection" => "test/duplication_contract.rb",
    "Flay class method tree topology" => "test/duplication_contract.rb",
    "Flay class method partial subtree" => "test/duplication_contract.rb",
    "Flay class method score" => "test/duplication_contract.rb",
    "Flay outer scope mass" => "test/duplication_contract.rb",
    "Flay class method original locations" => "test/duplication_contract.rb",
    "Flay class method pair ordering" => "test/duplication_contract.rb",
    "Flay class method partial status" => "test/duplication_contract.rb",
    "Flay partial source label" => "test/duplication_contract.rb",
    "Flay partial coverage count" => "test/duplication_contract.rb",
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
    "text report completion state" => "test/text_report_contract.rb",
    "default check selection" => "test/default_invocation_contract.rb",
    "default runnable selection" => "test/default_invocation_contract.rb",
    "unsupported opt-in incomplete status" => "test/default_invocation_contract.rb",
    "implicit current directory" => "test/default_invocation_contract.rb"
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

  # :reek:TooManyStatements
  def selected_mutation?
    return selected_shard_mutation? if MUTATION_SHARD
    return true unless @selected_labels && !@selected_labels.empty?

    labels = @selected_labels.split(",")
    unknown_labels = labels - CONTRACTS.keys
    raise "unknown mutation labels: #{unknown_labels.join(', ')}" unless unknown_labels.empty?
    labels.include?(@configuration.label)
  end

  def selected_shard_mutation?
    shard = MUTATION_SHARD
    shard_count = MUTATION_SHARDS
    raise "invalid mutation shard" unless shard_count.positive? && shard >= 0 && shard < shard_count

    index = CONTRACTS.keys.index(@configuration.label)
    index && index % shard_count == shard
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
  'bool writer = attr_writer || fleek_name_is(scope->parser, call->name, "attr_accessor") || fleek_name_is(scope->parser, call->name, "attr_writer");',
  "bool writer = false;",
  "missing Attribute finding",
  "Attribute findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_READ_NODE)",
  "false",
  "missing InstanceVariableAssumption finding",
  "InstanceVariableAssumption findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'memcmp(superclass_name->start, "Array", 5) == 0',
  "false",
  "missing SubclassedFromCoreClass finding",
  "SubclassedFromCoreClass findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'fleek_name_is(state->parser, method->name, "initialize")',
  "false",
  "missing ModuleInitialize finding",
  "ModuleInitialize findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return words >= 2 ? 1 : 0;",
  "return words >= 20 ? 1 : 0;",
  "missing IrresponsibleModule finding",
  "IrresponsibleModule clean syntax became unsupported")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (count <= method_maximum) return 0;",
  "if (count > method_maximum) return 0;",
  "missing LongParameterList finding",
  "LongParameterList findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!PM_NODE_TYPE_P(value, PM_TRUE_NODE) && !PM_NODE_TYPE_P(value, PM_FALSE_NODE)) continue;",
  "if (true) continue;",
  "missing BooleanParameter finding",
  "BooleanParameter findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (count <= state->maximum) return false;",
  "if (true) return false;",
  "missing LongYieldList finding",
  "LongYieldList findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return conditional && fleek_constants_equal(parser, ((const pm_local_variable_read_node_t *) node)->name, name);",
  "return false && fleek_constants_equal(parser, ((const pm_local_variable_read_node_t *) node)->name, name);",
  "missing ControlParameter finding",
  "ControlParameter findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "int line = fleek_source_line(source, node->location.start);",
  "int line = fleek_source_line(source, source);",
  "wrong ControlParameter lines",
  "ControlParameter findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!unused || fleek_body_has_implicit_super(method->body)) continue;",
  "if (true || fleek_body_has_implicit_super(method->body)) continue;",
  "missing UnusedParameters finding",
  "UnusedParameters findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!state.has_send || state.uses_self) return 0;",
  "if (true || state.uses_self) return 0;",
  "missing UtilityFunction finding",
  "UtilityFunction findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (count <= maximum) continue;",
  "if (true) continue;",
  "missing DuplicateMethodCall finding",
  "DuplicateMethodCall findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'configuration.detector_setting("DuplicateMethodCall", "allow_calls", path) || ""',
  '""',
  "ignored DuplicateMethodCall list entry",
  "DuplicateMethodCall findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (nil_call || (comparison && has_nil)) return fleek_nil_check_add(state, call->base.location.start);",
  "if (false) return fleek_nil_check_add(state, call->base.location.start);",
  "missing NilCheck finding",
  "NilCheck findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!fleek_missing_safe_version_exists(parser, method, name)) {",
  "if (fleek_missing_safe_version_exists(parser, method, name)) {",
  "missing MissingSafeMethod finding",
  "MissingSafeMethod findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  '(detector_setting("MissingSafeMethod", "exclude", path) || "").split("\\n").include?(name)',
  'false',
  "ignored MissingSafeMethod exclusion entry",
  "MissingSafeMethod findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (entry->count <= state->maximum) continue;",
  "if (true) continue;",
  "missing RepeatedConditional finding",
  "RepeatedConditional findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (block->depth != depth || depth <= state->maximum) continue;",
  "if (true) continue;",
  "missing NestedIterators finding",
  "NestedIterators findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'ignored = configuration.detector_setting("NestedIterators", "ignore_iterators", path) || "Tempfile.create\\ntap"',
  'ignored = ""',
  "ignored NestedIterators list entry",
  "NestedIterators findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!fleek_name_is(state->parser, call->name, \"respond_to?\")) return true;",
  "if (true) return true;",
  "missing ManualDispatch finding",
  "ManualDispatch findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (maximum <= state.self_count) return 0;",
  "if (true) return 0;",
  "missing FeatureEnvy finding",
  "FeatureEnvy findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'when "DataClump" then NativePrism.fleek_data_clump(source, length, maximum, minimum)',
  'when "DataClump" then 0',
  "missing DataClump finding",
  "DataClump findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "for (size_t method = 0; method < state.methods; method++) for (size_t parameter = 0; parameter < state.counts[method]; parameter++) {",
  "for (size_t method = 0; method < state.methods; method++) if (method == 0) for (size_t parameter = 0; parameter < state.counts[method]; parameter++) {",
  "DataClump first-method dependence",
  "DataClump findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (method != matching[0]) continue;",
  "if (method != matching[0] || findings > 0) continue;",
  "DataClump first clump only",
  "DataClump findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return state.unsupported ? (findings > 0 ? -5 : -4) : (int) findings;",
  "return state.unsupported ? -4 : (int) findings;",
  "DataClump drops findings on incomplete syntax",
  "DataClump findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'when "TooManyConstants" then NativePrism.fleek_too_many_constants(source, length, maximum)',
  'when "TooManyConstants" then 0',
  "missing TooManyConstants finding",
  "TooManyConstants findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'when "TooManyInstanceVariables" then NativePrism.fleek_too_many_instance_variables(source, length, maximum)',
  'when "TooManyInstanceVariables" then 0',
  "missing TooManyInstanceVariables finding",
  "TooManyInstanceVariables findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "else if (PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_AND_WRITE_NODE)) name = ((const pm_instance_variable_and_write_node_t *) node)->name;\n      else if (PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_OR_WRITE_NODE)) name = ((const pm_instance_variable_or_write_node_t *) node)->name;",
  "else if (PM_NODE_TYPE_P(node, PM_INSTANCE_VARIABLE_OR_WRITE_NODE)) name = ((const pm_instance_variable_or_write_node_t *) node)->name;",
  "missing &&= instance variable writes",
  "TooManyInstanceVariables findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'when "TooManyMethods" then NativePrism.fleek_too_many_methods(source, length, maximum)',
  'when "TooManyMethods" then 0',
  "missing TooManyMethods finding",
  "TooManyMethods findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'when "TooManyStatements" then NativePrism.fleek_too_many_statements(source, length, maximum)',
  'when "TooManyStatements" then 0',
  "missing TooManyStatements finding",
  "TooManyStatements findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (found && result > 0) return -5;",
  "if (found && result > 0) return -4;",
  "TooManyStatements drops mixed-scope findings",
  "Fleek dropped supported finding beside singleton-class syntax")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (result == -4 && fleek_too_many_statements_used > 0) return -5;",
  "if (result == -4 && fleek_too_many_statements_used > 0) return -4;",
  "TooManyStatements drops findings before unsupported body",
  "Fleek dropped supported finding beside unsupported method body")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'status = partial ? -5 : 1;',
  'status = 1;',
  "TooManyMethods partial scope loses incomplete status",
  "TooManyMethods nested method unsupported shape appeared clean")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (PM_NODE_TYPE_P(node, PM_DEF_NODE)) return false;",
  "if (PM_NODE_TYPE_P(node, PM_DEF_NODE) || PM_NODE_TYPE_P(node, PM_BLOCK_NODE)) return false;",
  "missing LongYieldList block finding",
  "LongYieldList findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "attr_writer = true;",
  "attr_writer = false;",
  "missing Attribute aliased finding",
  "Attribute findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'if (fleek_has_class_new(&parser, root)) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }',
  'if (false) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }',
  "unsupported Class.new assignment",
  "SubclassedFromCoreClass unsupported shape appeared clean")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (overflow) return -1;",
  "if (false) return -1;",
  "comment overflow appeared clean",
  "comment overflow appeared clean")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "while (cursor < comment->location.end && !isspace(*cursor)) cursor++;",
  "while (cursor < comment->location.end) cursor++;",
  "Reek directive comment parity",
  "IrresponsibleModule findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (options < comment->location.end && *options == '{') {",
  "if (false) {",
  "Reek directive option parity",
  "IrresponsibleModule findings differ from Reek")).run
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
  '!effective_detector_enabled("ClassVariable", index)',
  'false',
  "disabled selected check handling",
  "discovered disabled check implied success")).run
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
  "bool same_shape = first_method.shape_count == second_method.shape_count;",
  "bool same_shape = false;",
  "Flay structural equality",
  "similar method group report differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (same_shape && mass >= (size_t) mass_threshold) {",
  "if (same_shape && mass > (size_t) mass_threshold) {",
  "Flay mass boundary",
  "similar method group report differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "(identical ? count : 1)",
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
  "if (PM_NODE_TYPE_P(statement, PM_CLASS_NODE)) {",
  "if (false) {",
  "Flay class method candidate collection",
  "unsupported syntax implied complete analysis")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "method->receiver != NULL || !fleek_duplication_class_parameters((const pm_node_t *) method->parameters, result)",
  "method->receiver != NULL || method->parameters != NULL || !fleek_duplication_class_parameters((const pm_node_t *) method->parameters, result)",
  "Flay required parameter candidates",
  "required-parameter class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return fleek_duplication_collect_namespace_methods(module_node, module_names, module_name_count, body, source, set);",
  "return true;",
  "Flay module method candidate collection",
  "multi-method Flay module group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (body->body.size == 1 && PM_NODE_TYPE_P(body->body.nodes[0], PM_MODULE_NODE)) {",
  "if (false) {",
  "Flay nested module candidate collection",
  "nested Flay module group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return fleek_duplication_collect_nested_module_methods(scope_node, (const pm_module_node_t *) body->body.nodes[0], scope_names, depth + 1, source, set);",
  "return true;",
  "Flay deep nested module candidate collection",
  "deep nested Flay module candidates differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (depth == 8 || !PM_NODE_TYPE_P(current->constant_path, PM_CONSTANT_READ_NODE))",
  "if (depth == 7 || !PM_NODE_TYPE_P(current->constant_path, PM_CONSTANT_READ_NODE))",
  "Flay nested module depth boundary",
  "eight-level Flay module candidates differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!fleek_duplication_collect_class_methods((const pm_node_t *) class_node, 1, source, set)) return false;",
  "return true;",
  "Flay nested namespace class collection",
  "nested-namespace class group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "set->candidates[index].scope_mass++;",
  "set->candidates[index].scope_mass--;",
  "Flay nested class scope mass",
  "nested-class group was not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (class_depth >= 3)",
  "if (false)",
  "Flay nested class depth boundary",
  "four-level nested-class boundary was treated as complete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "set->candidates[candidate].scope_mass = inner_name == 0 ? 1 : 2;",
  "set->candidates[candidate].scope_mass = 0;",
  "Flay nested class sibling mass",
  "nested-class siblings group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!direct_methods && nested_body->body.size == 1 && class_depth < 3 && PM_NODE_TYPE_P(nested_body->body.nodes[0], PM_CLASS_NODE))",
  "if (false)",
  "Flay nested wrapped class siblings",
  "nested wrapped class siblings group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "bool direct_methods = nested_body->body.size > 0;",
  "bool direct_methods = nested_body->body.size == 1;",
  "Flay nested sibling multi-methods",
  "multi-method nested class siblings group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (name == set->candidates[candidate].scope_depth) { duplicate_path = true; break; }",
  "if (false) { duplicate_path = true; break; }",
  "Flay nested sibling path mass",
  "multi-method nested class siblings group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (module_name_count > 1) {",
  "if (false) {",
  "Flay qualified namespace class collection",
  "qualified-namespace class group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return fleek_duplication_collect_qualified_namespace_classes(module_node, module_names, module_name_count, body, source, set);",
  "return true;",
  "Flay qualified namespace multiple classes",
  "multiple qualified-namespace class group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "set->candidates[index].scope_mass = module_name_count + module_class_count + 1;",
  "set->candidates[index].scope_mass = module_name_count + module_class_count;",
  "Flay qualified namespace multiple class mass",
  "multiple qualified-namespace class group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "((const pm_statements_node_t *) class_node->body)->body.size > 1",
  "false",
  "Flay qualified namespace multi-method boundary",
  "multi-method qualified class was treated as complete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "set->candidates[index].scope_mass = module_name_count + 2;",
  "set->candidates[index].scope_mass = module_name_count + 1;",
  "Flay qualified namespace class mass",
  "qualified-namespace class group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "module_name_count >= 8",
  "module_name_count >= 7",
  "Flay qualified namespace class depth",
  "qualified-namespace depth boundary differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!fleek_constants_equal(parser, set->candidates[left].scope_names[name], set->candidates[right].scope_names[name])) return false;",
  "if (false) return false;",
  "Flay outer scope identity",
  "multi-method Flay class group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "const char *node = set->candidates[first].scope_kind == 1 ? \"class\" : \"module\";",
  "const char *node = \"defn\";",
  "Flay module group kind",
  "cross-class Flay group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!grouped[candidate] && fleek_duplication_candidate_shapes_equal(set, first, candidate)) members[count++] = candidate;",
  "if (!grouped[candidate] && fleek_duplication_candidate_shapes_equal(set, first, candidate) && count < 2) members[count++] = candidate;",
  "Flay multiple class method candidates",
  "multiple Flay method candidates were not grouped")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "covered[candidate_method] = true;",
  "covered[candidate_method] = false;",
  "Flay preserves independent candidate groups",
  "cross-class Flay group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[-group.score, duplication_location_sort_key(group.locations[0]), group.node]",
  "[duplication_location_sort_key(group.locations[0]), group.node, -group.score]",
  "Flay group ordering",
  "Flay group ordering differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "count * group.score / locations.length",
  "count * group.score / 2",
  "Flay grouped file score",
  "multiple Flay method candidates were not grouped")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "parameters->requireds.size + parameters->optionals.size > 8",
  "parameters->requireds.size + parameters->optionals.size > 1",
  "Flay required parameter arity",
  "parameter-arity class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!PM_NODE_TYPE_P(optional, PM_OPTIONAL_PARAMETER_NODE) ||",
  "if (true ||",
  "Flay optional parameter candidates",
  "optional-parameter class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "!fleek_duplication_optional_default_supported(((const pm_optional_parameter_node_t *) optional)->value)",
  "false && !fleek_duplication_optional_default_supported(((const pm_optional_parameter_node_t *) optional)->value)",
  "Flay optional default boundary",
  "unsupported syntax implied complete analysis")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_SYMBOL_NODE) || PM_NODE_TYPE_P(node, PM_TRUE_NODE)",
  "PM_NODE_TYPE_P(node, PM_TRUE_NODE)",
  "Flay optional symbol default acceptance",
  "optional literal default parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "result->parameter_mass += 2;",
  "result->parameter_mass += 0;",
  "Flay optional parameter mass",
  "optional-parameter class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "!fleek_duplication_optional_defaults_equal(left_parameter->value, right_parameter->value)",
  "false",
  "Flay optional default identity",
  "optional-parameter default parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return method->parameters == NULL ? 0 : ((const pm_parameters_node_t *) method->parameters)->optionals.size;",
  "return 0;",
  "Flay optional parameter count",
  "optional-parameter count mismatch was grouped")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_duplication_class_parameters_equal(parser, first, second) &&",
  "true &&",
  "Flay required parameter identity",
  "parameter-name class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_IF_NODE) ||",
  "",
  "Flay class method conditional candidates",
  "conditional class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_IF_NODE) || PM_NODE_TYPE_P(node, PM_UNLESS_NODE) || PM_NODE_TYPE_P(node, PM_ELSE_NODE);",
  "PM_NODE_TYPE_P(node, PM_IF_NODE) || PM_NODE_TYPE_P(node, PM_ELSE_NODE);",
  "Flay class method unless candidates",
  "unless class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_RETURN_NODE) || PM_NODE_TYPE_P(node, PM_IF_NODE) || PM_NODE_TYPE_P(node, PM_UNLESS_NODE) || PM_NODE_TYPE_P(node, PM_ELSE_NODE);",
  "PM_NODE_TYPE_P(node, PM_IF_NODE) || PM_NODE_TYPE_P(node, PM_UNLESS_NODE) || PM_NODE_TYPE_P(node, PM_ELSE_NODE);",
  "Flay class method return candidates",
  "conditional return class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_TRUE_NODE) || PM_NODE_TYPE_P(node, PM_FALSE_NODE) || PM_NODE_TYPE_P(node, PM_AND_NODE)",
  "PM_NODE_TYPE_P(node, PM_TRUE_NODE) || PM_NODE_TYPE_P(node, PM_AND_NODE)",
  "Flay class method false literal candidates",
  "conditional return class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_OR_NODE) ||",
  "",
  "Flay class method OR candidates",
  "class-method OR expression parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_WRITE_NODE) ||",
  "false ||",
  "Flay class method local write candidates",
  "local-write class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (PM_NODE_TYPE_P(first, PM_LOCAL_VARIABLE_WRITE_NODE) && !fleek_constants_equal(parser, ((const pm_local_variable_write_node_t *) first)->name, ((const pm_local_variable_write_node_t *) second)->name)) return false;",
  "if (false) return false;",
  "Flay class method local write identity",
  "local-write identity parity differed")).run
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
  "if (set->count == 24 || !fleek_duplication_class_method(child, source, &set->candidates[set->count])) { fleek_duplication_partial = 1; continue; }",
  "if (set->count == 1 || !fleek_duplication_class_method(child, source, &set->candidates[set->count])) { fleek_duplication_partial = 1; continue; }",
  "Flay additional class method rejection",
  "Rails-shaped class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (method_count != 0 || ffi_module_count != 0 || !fleek_duplication_collect_class_methods(statement, 1, (const uint8_t *) source, &class_candidates)) {",
  "if (scope_count != 0 || method_count != 0 || ffi_module_count != 0 || !fleek_duplication_collect_class_methods(statement, 1, (const uint8_t *) source, &class_candidates)) {",
  "Flay multiple class declarations",
  "class methods across classes were not compared")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (count < 2) continue;\n        int lines[24] = { 0 };",
  "if (count < 3) continue;\n        int lines[24] = { 0 };",
  "Flay cross-class class-group collection",
  "cross-class Flay group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return set->candidates[index].scope_kind != 0 && set->scope_candidate_counts[index] > 0 &&\n        set->scope_body_counts[index] == set->scope_candidate_counts[index];",
  "return set->candidates[index].scope_kind != 0;",
  "Flay partial class candidates",
  "supported class methods were hidden by unsupported callbacks")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "else if (!fleek_duplication_collect_namespace_classes(statement, (const uint8_t *) source, &class_candidates)) {",
  "else if (true) {",
  "Flay namespace class method collection",
  "nested cross-scope class group differed")).run
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
  "left_mass >= (size_t) mass_threshold && left_mass == right_mass &&\n                  fleek_duplication_class_subtrees_equal(&set->candidates[left], left_node, &set->candidates[right], right_node)",
  "false",
  "Flay class method partial subtree",
  "partial class-method duplicate was silently skipped")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "size_t mass = 2 + method->shape_count + method->parameter_mass;\n      for (size_t index = 0; index < method->shape_count; index++) if (fleek_duplication_class_node_massless(method->data.ast.nodes[index])) mass--;",
  "size_t mass = 2 + method->shape_count + method->parameter_mass;\n      for (size_t index = 0; index < method->shape_count; index++) if (fleek_duplication_class_node_massless(method->data.ast.nodes[index])) mass++;",
  "Flay class method score",
  "Rails-shaped class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_duplication_scope_method_mass(set, first) + fleek_duplication_scope_mass(parser, set, first)",
  "fleek_duplication_scope_method_mass(set, first) + fleek_duplication_scope_mass(parser, set, first) - 1",
  "Flay outer scope mass",
  "cross-class Flay group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "result->line = 1;\n      for (const uint8_t *cursor = source; cursor < method->def_keyword_loc.start; cursor++) if (*cursor == '\\\\n') result->line++;\n      return true;\n    }\n    static bool fleek_duplication_constant_path_names",
  "result->line = 1;\n      return true;\n    }\n    static bool fleek_duplication_constant_path_names",
  "Flay class method original locations",
  "Rails-shaped class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "lines[index] = set->candidates[candidate].line;",
  "lines[index] = set->candidates[first].line;",
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
  "ninth module level partial source scope was not reported")).run
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
  'locations.sort_by { |location| duplication_location_sort_key(location) }',
  'locations.reverse',
  "Flay cross-file ordering",
  "similar method group report differed")).run
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
  "report_all && !unsupported.empty? ? 1 : status",
  "report_all && !unsupported.empty? ? status : status",
  "unsupported opt-in incomplete status",
  "unsupported opt-in check did not keep the default run incomplete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'inputs = arguments.empty? ? [Dir.pwd] : arguments',
  'inputs = arguments',
  "implicit current directory",
  "default enabled check list differs")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "RUNNABLE_DEFAULT_CHECKS = DEFAULT_CHECKS",
  "RUNNABLE_DEFAULT_CHECKS = []",
  "default runnable selection",
  "supported check diagnostic was lost")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'enabled = DEFAULT_CHECKS.select { |check| configuration.detector_enabled_anywhere?(check.delete_prefix("reek:"), source_paths) }',
  'enabled = DEFAULT_CHECKS',
  "configured default detector selection",
  "disabled default detector remained selected")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'opt_in = configuration.enabled_opt_in_detectors(source_paths).map { |name| "reek:#{name}" }',
  'opt_in = []',
  "configured opt-in detector selection",
  "configured Reek opt-in detector was not selected")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'paths.any? { |path| effective_detector_enabled(name, best_scope(path)) }',
  'paths.any? { |_path| effective_detector_enabled(name, -1) }',
  "Reek directory detector precedence",
  "Fleek ignored the parent directory disablement")).run
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
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!fleek_matches_any_pattern((const uint8_t *) name->start, name->length, patterns->reject)) return 0;",
  "if (fleek_matches_any_pattern((const uint8_t *) name->start, name->length, patterns->reject)) return 0;",
  "missing UncommunicativeMethodName finding",
  "UncommunicativeMethodName findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!fleek_matches_any_pattern((const uint8_t *) name->start, name->length, state->patterns->reject)) return true;",
  "if (fleek_matches_any_pattern((const uint8_t *) name->start, name->length, state->patterns->reject)) return true;",
  "missing UncommunicativeModuleName finding",
  "UncommunicativeModuleName findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "!fleek_matches_any_pattern((const uint8_t *) name->start, name->length, patterns->reject)) continue;",
  "fleek_matches_any_pattern((const uint8_t *) name->start, name->length, patterns->reject)) continue;",
  "missing UncommunicativeParameterName finding",
  "UncommunicativeParameterName findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "!fleek_matches_any_pattern((const uint8_t *) name->start, name->length, state->patterns->reject)) return true;",
  "fleek_matches_any_pattern((const uint8_t *) name->start, name->length, state->patterns->reject)) return true;",
  "missing UncommunicativeVariableName finding",
  "UncommunicativeModuleName findings differ from Reek")).run

process_id = Process.spawn("make", "build/fleek", out: "/tmp/fleek-mutation-restore-out", err: "/tmp/fleek-mutation-restore-err")
_, status = Process.waitpid2(process_id)
raise "mutation restore failed" unless status.success?
