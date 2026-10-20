# Proves public checks reject deliberately broken parser, CLI, and analyzer behaviors.
require_relative "mutation_contract_cache"

MUTATION_SHARD = nil
MUTATION_SHARDS = nil

# Runs one configured source mutation and requires its public contract to fail.
class MutationCase
  # :reek:DuplicateMethodCall
  # :reek:TooManyStatements
  # Carries one behavior mutation and its expected contract failure.
  Configuration = Struct.new(:source, :target, :replacement, :label, :expected_failure)
  COMPILED_CONTRACTS = {}
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
    "Flay top-level method argument calls" => "test/duplication_contract.rb",
    "Flay top-level required parameters" => "test/duplication_method_parameter_contract.rb",
    "Flay class method candidate collection" => "test/duplication_method_cross_file_contract.rb",
    "Flay composed cross-file subtree selection" => "test/duplication_composed_cross_file_contract.rb",
    "Flay composed cross-file class pruning" => "test/duplication_composed_cross_file_contract.rb",
    "Flay method array expression" => "test/duplication_method_collection_contract.rb",
    "Flay method hash expression" => "test/duplication_method_collection_contract.rb",
    "Flay method hash-rocket expression" => "test/duplication_method_hash_rocket_contract.rb",
    "Flay method while loop candidates" => "test/duplication_method_loop_contract.rb",
    "Flay method until loop candidates" => "test/duplication_method_loop_contract.rb",
    "Flay method for loop candidates" => "test/duplication_method_for_contract.rb",
    "Flay method rest parameter identity" => "test/duplication_method_anonymous_parameter_contract.rb",
    "Flay required keyword parameter candidates" => "test/duplication_method_parameter_contract.rb",
    "Flay required keyword parameter identity" => "test/duplication_method_parameter_contract.rb",
    "Flay required keyword parameter mass" => "test/duplication_method_parameter_contract.rb",
    "Flay optional keyword parameter candidates" => "test/duplication_method_parameter_contract.rb",
    "Flay optional keyword parameter identity" => "test/duplication_method_parameter_contract.rb",
    "Flay optional keyword parameter mass" => "test/duplication_method_parameter_contract.rb",
    "Flay optional keyword constant defaults" => "test/duplication_method_parameter_contract.rb",
    "Flay optional keyword constant default identity" => "test/duplication_method_parameter_contract.rb",
    "Flay post parameter candidates" => "test/duplication_method_parameter_contract.rb",
    "Flay post parameter identity" => "test/duplication_method_parameter_contract.rb",
    "Flay post parameter mass" => "test/duplication_method_parameter_contract.rb",
    "Flay keyword-rest parameter candidates" => "test/duplication_method_parameter_contract.rb",
    "Flay keyword-rest parameter identity" => "test/duplication_method_anonymous_parameter_contract.rb",
    "Flay anonymous variadic parameter candidates" => "test/duplication_method_anonymous_parameter_contract.rb",
    "Flay anonymous variadic parameter identity" => "test/duplication_method_anonymous_parameter_contract.rb",
    "Flay method block parameter candidates" => "test/duplication_method_block_parameter_contract.rb",
    "Flay method block parameter identity" => "test/duplication_method_block_parameter_contract.rb",
    "Flay anonymous method block parameter identity" => "test/duplication_method_block_parameter_contract.rb",
    "Flay yield expression candidates" => "test/duplication_method_exception_flow_contract.rb",
    "Flay bare super candidates" => "test/duplication_method_parameter_contract.rb",
    "Flay explicit super candidates" => "test/duplication_method_parameter_contract.rb",
    "Flay next expression candidates" => "test/duplication_method_exception_flow_contract.rb",
    "Flay next expression mass" => "test/duplication_method_exception_flow_contract.rb",
    "Flay break expression candidates" => "test/duplication_method_exception_flow_contract.rb",
    "Flay redo expression candidates" => "test/duplication_method_exception_flow_contract.rb",
    "Flay begin expression candidates" => "test/duplication_method_exception_flow_contract.rb",
    "Flay rescue expression candidates" => "test/duplication_method_exception_flow_contract.rb",
    "Flay retry expression candidates" => "test/duplication_method_exception_flow_contract.rb",
    "Flay retry expression mass" => "test/duplication_method_exception_flow_contract.rb",
    "Flay ensure expression candidates" => "test/duplication_method_exception_flow_contract.rb",
    "Flay ensure expression mass" => "test/duplication_method_exception_flow_contract.rb",
    "Flay composed exception wrapper mass" => "test/duplication_composed_exception_contract.rb",
    "Flay composed exception binding mass" => "test/duplication_composed_exception_contract.rb",
    "Flay regular expression candidates" => "test/duplication_method_regexp_contract.rb",
    "Flay regular expression content identity" => "test/duplication_method_regexp_contract.rb",
    "Flay regular expression flags identity" => "test/duplication_method_regexp_contract.rb",
    "Flay range descriptor identity" => "test/duplication_generated_descriptor_contract.rb",
    "Flay regular expression descriptor identity" => "test/duplication_generated_descriptor_contract.rb",
    "Flay interpolated regular expression descriptor identity" => "test/duplication_generated_descriptor_contract.rb",
    "Flay interpolated regular expression candidates" => "test/duplication_method_regexp_contract.rb",
    "Flay interpolated regular expression mass" => "test/duplication_method_regexp_contract.rb",
    "Flay interpolated regular expression flags identity" => "test/duplication_method_regexp_contract.rb",
    "Flay method hash association mass" => "test/duplication_method_collection_contract.rb",
    "Flay mass check applicability" => "test/cli_contract.rb",
    "Flay only node filtering" => "test/duplication_only_node_contract.rb",
    "Flay only total score preservation" => "test/duplication_only_node_contract.rb",
    "Flay only repeated option precedence" => "test/duplication_only_node_contract.rb",
    "Flay only missing repeated value" => "test/duplication_only_node_contract.rb",
    "Flay only check applicability" => "test/cli_contract.rb",
    "Flay liberal option recognition" => "test/duplication_contract.rb",
    "Flay liberal candidate retention" => "test/duplication_contract.rb",
    "Flay liberal check applicability" => "test/cli_contract.rb",
    "Flay liberal combined routing" => "test/cli_contract.rb",
    "Flay fuzzy option recognition" => "test/duplication_fuzzy_contract.rb",
    "Flay fuzzy candidate collection" => "test/duplication_fuzzy_contract.rb",
    "Flay fuzzy location attribution" => "test/duplication_fuzzy_contract.rb",
    "Flay fuzzy candidate bounds" => "test/duplication_fuzzy_contract.rb",
    "Flay fuzzy explicit distance parsing" => "test/duplication_fuzzy_distance_contract.rb",
    "Flay fuzzy multiple statement matching" => "test/duplication_fuzzy_distance_contract.rb",
    "Flay repeated mass precedence" => "test/duplication_control_interactions_contract.rb",
    "Flay fuzzy liberal source routing" => "test/duplication_control_interactions_contract.rb",
    "Flay legacy parser boundary" => "test/legacy_parser_contract.rb",
    "Flay legacy check applicability" => "test/legacy_parser_contract.rb",
    "Flay unreadable ignore file" => "test/flayignore_contract.rb",
    "Flay basename ignore matching" => "test/flayignore_contract.rb",
    "Flay path deduplication" => "test/flay_paths_contract.rb",
    "Flay lexical path normalization" => "test/flay_paths_contract.rb",
    "Flay empty path safety" => "test/flay_paths_contract.rb",
    "Reek config check applicability" => "test/cli_contract.rb",
    "Flay module method candidate collection" => "test/duplication_contract.rb",
    "Flay nested module candidate collection" => "test/duplication_contract.rb",
    "Flay module scopes inside classes" => "test/duplication_contract.rb",
    "Flay mixed sibling scope preservation" => "test/duplication_contract.rb",
    "Flay direct sibling method collection" => "test/duplication_contract.rb",
    "Flay supported siblings beside unsupported class" => "test/duplication_unsupported_sibling_contract.rb",
    "Flay mixed scope kind identity" => "test/duplication_contract.rb",
    "Flay namespace class module scope kind" => "test/duplication_contract.rb",
    "Flay deep nested module candidate collection" => "test/duplication_contract.rb",
    "Flay arbitrary-depth nested module traversal" => "test/duplication_contract.rb",
    "Flay nested namespace class collection" => "test/duplication_contract.rb",
    "Flay nested class scope mass" => "test/duplication_contract.rb",
    "Flay nested class chain traversal" => "test/duplication_contract.rb",
    "Flay nested class sibling mass" => "test/duplication_contract.rb",
    "Flay nested wrapped class siblings" => "test/duplication_contract.rb",
    "Flay nested wrapped sibling scopes" => "test/duplication_contract.rb",
    "Flay nested sibling multi-methods" => "test/duplication_contract.rb",
    "Flay nested sibling path mass" => "test/duplication_contract.rb",
    "Flay qualified namespace class collection" => "test/duplication_contract.rb",
    "Flay qualified namespace multiple classes" => "test/duplication_contract.rb",
    "Flay qualified namespace multiple class mass" => "test/duplication_contract.rb",
    "Flay qualified namespace multi-method classes" => "test/duplication_contract.rb",
    "Flay multiple qualified multi-method classes" => "test/duplication_contract.rb",
    "Flay qualified namespace class mass" => "test/duplication_contract.rb",
    "Flay outer scope identity" => "test/duplication_contract.rb",
    "Flay module group kind" => "test/duplication_contract.rb",
    "Flay multiple class method candidates" => "test/duplication_contract.rb",
    "Flay preserves independent candidate groups" => "test/duplication_contract.rb",
    "Flay group ordering" => "test/duplication_group_order_contract.rb",
    "Flay grouped file score" => "test/duplication_contract.rb",
    "Flay required parameter candidates" => "test/duplication_method_parameter_contract.rb",
    "Flay required parameter identity" => "test/duplication_method_parameter_contract.rb",
    "Flay optional parameter candidates" => "test/duplication_method_parameter_contract.rb",
    "Flay optional default boundary" => "test/duplication_method_parameter_boundary_contract.rb",
    "Flay optional symbol default acceptance" => "test/duplication_method_parameter_contract.rb",
    "Flay optional parameter mass" => "test/duplication_method_parameter_contract.rb",
    "Flay optional default identity" => "test/duplication_method_parameter_contract.rb",
    "Flay optional positional constant defaults" => "test/duplication_method_optional_positional_constant_contract.rb",
    "Flay optional positional constant default identity" => "test/duplication_method_optional_positional_constant_contract.rb",
    "Flay optional positional bare-call defaults" => "test/duplication_method_optional_positional_call_contract.rb",
    "Flay optional positional bare-call default mass" => "test/duplication_method_optional_positional_call_contract.rb",
    "Flay optional positional bare-call default identity" => "test/duplication_method_optional_positional_call_contract.rb",
    "Flay optional positional call argument candidates" => "test/duplication_method_optional_positional_call_argument_contract.rb",
    "Flay optional positional call argument mass" => "test/duplication_method_optional_positional_call_argument_contract.rb",
    "Flay optional positional call argument identity" => "test/duplication_method_optional_positional_call_argument_contract.rb",
    "Flay optional keyword call argument boundary" => "test/duplication_method_optional_keyword_call_argument_contract.rb",
    "Flay optional keyword bare-call defaults" => "test/duplication_method_parameter_contract.rb",
    "Flay node-rule candidate support" => "test/duplication_method_collection_contract.rb",
    "Flay node-rule mass adjustments" => "test/duplication_method_multiple_assignment_contract.rb",
    "Flay generated descriptor support" => "test/duplication_method_range_contract.rb",
    "Flay generated descriptor mass" => "test/duplication_generated_descriptor_contract.rb",
    "Flay variable-rule name identity" => "test/duplication_method_multiple_assignment_contract.rb",
    "Flay variable-rule operator identity" => "test/duplication_method_variable_rule_contract.rb",
    "Flay class method conditional candidates" => "test/duplication_method_branch_contract.rb",
    "Flay method return candidates" => "test/duplication_method_branch_contract.rb",
    "Flay method false literal candidates" => "test/duplication_method_branch_contract.rb",
    "Flay method OR candidates" => "test/duplication_method_branch_contract.rb",
    "Flay method AND candidates" => "test/duplication_method_branch_contract.rb",
    "Flay method CASE candidates" => "test/duplication_method_branch_contract.rb",
    "Flay method WHEN candidates" => "test/duplication_method_branch_contract.rb",
    "Flay method float candidates" => "test/duplication_contract.rb",
    "Flay method nil candidates" => "test/duplication_contract.rb",
    "Flay method unless candidates" => "test/duplication_method_branch_contract.rb",
    "Flay method range candidates" => "test/duplication_method_range_contract.rb",
    "Flay method range mass" => "test/duplication_method_range_contract.rb",
    "Flay method range identity" => "test/duplication_method_range_contract.rb",
    "Flay method dynamic node capacity" => "test/duplication_method_capacity_contract.rb",
    "Flay method dynamic tree capacity" => "test/duplication_method_capacity_contract.rb",
    "Flay nested tree closing capacity" => "test/duplication_contract.rb",
    "Flay block expression candidates" => "test/duplication_method_block_contract.rb",
    "Flay block expression mass" => "test/duplication_method_block_contract.rb",
    "Flay block parameter identity" => "test/duplication_method_block_contract.rb",
    "Flay method self receiver" => "test/duplication_method_self_contract.rb",
    "Flay parenthesized method expression" => "test/duplication_method_self_contract.rb",
    "Flay dynamic class method candidates" => "test/duplication_method_candidate_capacity_contract.rb",
    "Flay dynamic class method body" => "test/duplication_method_candidate_capacity_contract.rb",
    "Flay dynamic duplication report buffer" => "test/duplication_method_candidate_capacity_contract.rb",
    "Flay method parameter count capacity" => "test/duplication_method_parameter_capacity_contract.rb",
    "Flay method constant path candidates" => "test/duplication_method_constant_path_contract.rb",
    "Flay method constant path identity" => "test/duplication_method_scalar_value_contract.rb",
    "Flay scalar integer identity" => "test/duplication_method_scalar_value_contract.rb",
    "Flay scalar float identity" => "test/duplication_method_scalar_value_contract.rb",
    "Flay scalar string identity" => "test/duplication_method_scalar_value_contract.rb",
    "Flay scalar symbol identity" => "test/duplication_method_scalar_value_contract.rb",
    "Flay scalar constant identity" => "test/duplication_method_scalar_value_contract.rb",
    "Flay method call candidates" => "test/duplication_method_call_contract.rb",
    "Flay method call identity" => "test/duplication_method_call_contract.rb",
    "Flay method call splat candidates" => "test/duplication_method_call_contract.rb",
    "Flay method call block mass" => "test/duplication_method_call_contract.rb",
    "Flay method splat candidates" => "test/duplication_method_splat_contract.rb",
    "Flay method interpolated string candidates" => "test/duplication_method_interpolated_string_contract.rb",
    "Flay method local write candidates" => "test/duplication_contract.rb",
    "Flay method local write identity" => "test/duplication_method_variable_rule_contract.rb",
    "Flay block optional parameter candidates" => "test/duplication_method_block_optional_parameter_contract.rb",
    "Flay block optional parameter mass" => "test/duplication_method_block_optional_parameter_contract.rb",
    "Flay composed parameter block mass" => "test/duplication_composed_parameter_block_contract.rb",
    "Flay composed block subtree selection" => "test/duplication_similar_composed_block_contract.rb",
    "Flay method parameter shape selection" => "test/duplication_similar_composed_block_contract.rb",
    "Flay class method parameter shape selection" => "test/duplication_generated_descriptor_contract.rb",
    "Flay multiple composed block groups" => "test/duplication_generated_descriptor_contract.rb",
    "Flay block optional parameter name identity" => "test/duplication_method_block_optional_parameter_contract.rb",
    "Flay block optional parameter expression identity" => "test/duplication_method_block_optional_parameter_contract.rb",
    "Flay class method conditional mass" => "test/duplication_contract.rb",
    "Flay class method candidate capacity" => "test/duplication_contract.rb",
    "Flay multiple class declarations" => "test/duplication_contract.rb",
    "Flay cross-class class-group collection" => "test/duplication_contract.rb",
    "Flay namespace class method collection" => "test/duplication_contract.rb",
    "Flay additional class method rejection" => "test/duplication_contract.rb",
    "Flay class method tree topology" => "test/duplication_contract.rb",
    "Flay class method partial subtree" => "test/duplication_contract.rb",
    "Flay method case condition mass" => "test/duplication_method_branch_contract.rb",
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
    "Spinel FFI module ordering" => "test/language_extensions_contract.rb",
    "text report newline escaping" => "test/text_report_contract.rb",
    "text report source ordering" => "test/text_report_contract.rb",
    "text report section ordering" => "test/text_report_contract.rb",
    "text report check execution" => "test/text_report_contract.rb",
    "text report failed source identity" => "test/text_report_contract.rb",
    "text report completion state" => "test/text_report_contract.rb",
    "default check selection" => "test/default_invocation_contract.rb",
    "default runnable selection" => "test/default_invocation_contract.rb",
    "UnusedPrivateMethod private visibility" => "test/default_argument_api_contract.rb",
    "UnusedPrivateMethod named visibility" => "test/default_argument_api_contract.rb",
    "UnusedPrivateMethod public visibility" => "test/default_argument_api_contract.rb",
    "UnusedPrivateMethod direct call tracking" => "test/default_argument_api_contract.rb",
    "UnusedPrivateMethod dynamic call boundary" => "test/default_argument_api_contract.rb",
    "implicit current directory" => "test/default_invocation_contract.rb"
  }
  CONTRACT_DEPENDENCIES = {
    "test/duplication_method_scalar_value_contract.rb" => %w[test/duplication_method_pair_contract.rb],
    "test/duplication_method_call_contract.rb" => %w[test/duplication_method_pair_contract.rb],
    "test/duplication_method_variable_rule_contract.rb" => %w[
      test/duplication_method_multiple_assignment_contract.rb
      test/duplication_method_local_operator_write_contract.rb
      test/duplication_method_local_logical_write_contract.rb
      test/duplication_method_class_variable_contract.rb
      test/duplication_method_class_variable_operator_write_contract.rb
      test/duplication_method_class_variable_logical_write_contract.rb
      test/duplication_method_class_variable_write_contract.rb
      test/duplication_method_instance_variable_operator_write_contract.rb
    ]
  }.freeze

  def initialize(configuration)
    @configuration = configuration
    @selected_labels = ENV["FLEEK_MUTATIONS"]
    @source = configuration.source
  end

  def run
    return unless self.class::CONTRACTS.key?(@configuration.label)
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
    labels = self.class.selected_labels(@selected_labels)
    return false if labels && !labels.include?(@configuration.label)
    MUTATION_SHARD ? selected_shard_mutation? : true
  end

  # :reek:TooManyStatements
  def self.selected_labels(selection)
    return nil unless selection && !selection.empty?
    labels = selection.split(",")
    registry = CONTRACTS.keys
    unknown_labels = labels - registry
    raise "unknown mutation labels: #{unknown_labels.join(', ')}" unless unknown_labels.empty?
    registry.select { |label| labels.include?(label) }
  end

  # :reek:TooManyStatements
  def selected_shard_mutation?
    shard = MUTATION_SHARD
    shard_count = MUTATION_SHARDS
    raise "invalid mutation shard" unless shard_count.positive? && shard >= 0 && shard < shard_count

    label = @configuration.label
    selection = @selected_labels
    labels = self.class.selected_labels(selection)
    index = labels ? labels.index(label) : CONTRACTS.keys.index(label)
    index && index % shard_count == shard
  end

  def verify_mutation
    verify_build
    verify_contract
  end

  def verify_build
    File.delete("build/fleek") if File.file?("build/fleek")
    raise "#{@configuration.label} mutant failed to compile" unless MutationProcess.build_mutant
  end

  # :reek:TooManyStatements
  def verify_contract
    contract = CONTRACTS.fetch(@configuration.label)
    executable = compile_contract(contract)
    contract_directory = ENV["FLEEK_MUTATION_CONTRACT_DIRECTORY"]
    verify_shared_contract(executable, contract, contract_directory) if contract_directory
    Dir.mkdir("build/mutation-reference-cache") unless Dir.exist?("build/mutation-reference-cache")
    status = MutationProcess.run_contract(executable)
    verify_contract_temp_root if contract_directory
    verify_failure(status)
  end

  def verify_shared_contract(executable, contract, directory)
    verify_shared_binary(executable, contract, directory)
    verify_worker_directory
  end

  def verify_shared_binary(executable, contract, directory)
    expected_directory = File.realpath(directory)
    expected_executable = File.realpath("#{expected_directory}/#{File.basename(contract, ".rb")}")
    raise "mutation contract did not reuse shared binary" unless File.realpath(executable) == expected_executable
    verify_no_shared_duplication_output_paths(expected_directory) if contract == "test/duplication_contract.rb"
  end

  def verify_worker_directory
    expected_working_directory = File.realpath(ENV.fetch("FLEEK_EXPECTED_WORKING_DIRECTORY"))
    raise "mutation contract worker directory was not isolated" unless Dir.pwd == expected_working_directory
  end

  # :reek:FeatureEnvy
  def verify_no_shared_duplication_output_paths(directory)
    source = File.read("#{directory}/test/duplication_contract.rb")
    root_helper = source.include?('def self.temporary_path(name)') && source.include?('ENV["FLEEK_TEMP_ROOT"] || "/tmp"')
    capture_helper = source.include?('def self.capture_paths(tool)') && source.include?('temporary_path("#{tool}-duplication-out")')
    capture_users = source.include?('capture_paths("fleek")') && source.include?('capture_paths("flay")')
    raise "shared duplication contract does not isolate capture paths by worker" unless root_helper && capture_helper && capture_users
  end

  def verify_contract_temp_root
    expected_root = File.realpath(ENV.fetch("FLEEK_EXPECTED_TEMP_ROOT"))
    actual_root = ENV.fetch("FLEEK_TEMP_ROOT")
    raise "mutation contract worker temp root was not isolated" unless File.realpath(actual_root) == expected_root
    raise "mutation contract did not use worker temp root" unless Dir.children(expected_root).any? { |name| !name.start_with?("fleek-mutation-") }
  end

  # :reek:TooManyStatements
  def compile_contract(contract)
    return COMPILED_CONTRACTS.fetch(contract) if COMPILED_CONTRACTS.key?(contract)

    directory = ENV["FLEEK_MUTATION_CONTRACT_DIRECTORY"]
    contract_name = File.basename(contract, ".rb")
    executable = if directory
                   File.expand_path("#{directory}/#{contract_name}")
                 else
                   File.expand_path("build/mutation-#{Process.pid}-#{contract_name}")
                 end
    existing_binary = File.file?(executable)
    if directory
      raise "shared mutation contract missing: #{contract}" unless existing_binary
    else
      File.delete(executable) if existing_binary
      self.class.compile_contract_binary(contract, executable)
    end

    COMPILED_CONTRACTS[contract] = executable
  end

  # :reek:TooManyStatements
  def self.prepare_contracts
    directory = ENV.fetch("FLEEK_MUTATION_CONTRACT_DIRECTORY")
    Dir.mkdir(directory)
    source_directory = "#{directory}/test"
    Dir.mkdir(source_directory)
    selected_labels = self.selected_labels(ENV["FLEEK_MUTATIONS"])
    contracts = selected_labels ? selected_labels.map { |label| CONTRACTS.fetch(label) }.uniq : CONTRACTS.values.uniq
    dependency_paths = contracts.flat_map { |path| CONTRACT_DEPENDENCIES.fetch(path, []) }
    source_paths = (contracts + dependency_paths + ["test/analysis_runner.rb"]).uniq
    source_paths.each do |path|
      source = File.read(path)
      mapped_contract = contracts.include?(path) || dependency_paths.include?(path)
      source = source.gsub('"/tmp/', '"#{ENV["FLEEK_TEMP_ROOT"] || "/tmp"}/') if mapped_contract || path == "test/analysis_runner.rb"
      source = source.gsub("__dir__", 'File.expand_path("test", Dir.pwd)') if mapped_contract
      File.write("#{source_directory}/#{File.basename(path)}", source)
    end
    contract_count = contracts.length
    jobs = [Integer(ENV.fetch("JOBS", "1"), 10), contract_count].min
    cache_result = prepare_cached_public_contract(contracts, dependency_paths, directory, source_directory, jobs)
    if cache_result
      report_cache_result(cache_result)
    else
      puts "Mutation contract cache: disabled" if ENV["FLEEK_DISABLE_MUTATION_CONTRACT_CACHE"] == "true"
      contracts.each_slice(jobs) { |batch| compile_contract_batch(batch, directory, source_directory) }
      puts "Mutation contracts: #{contract_count} shared binaries compiled"
    end
    if ENV["FLEEK_PRECOMPILE_BUDGET_REPORT"] == "true"
      puts "Mutation precompile budget: JOBS=#{jobs}; max batch=#{[jobs, contract_count].min}; contracts=#{contracts.join(',')}; dependencies=#{dependency_paths.join(',')}"
    end
  end

  def self.report_cache_result(cache_result)
    hits = cache_result[:hits]
    misses = cache_result[:misses]
    puts "Mutation contract cache: #{hits} hits, #{misses} misses"
    puts "Mutation contracts: #{hits} shared binaries restored, #{misses} compiled"
  end

  # :reek:LongParameterList
  # :reek:TooManyStatements
  def self.prepare_cached_public_contract(contracts, dependencies, directory, source_directory, jobs)
    return if ENV["FLEEK_DISABLE_MUTATION_CONTRACT_CACHE"] == "true"
    return unless MutationContractCache.supports_contract_set?(contracts, dependencies, CONTRACTS.values.uniq, CONTRACT_DEPENDENCIES)

    spinel = ENV["SPINEL"] || "spinel"
    root = ENV["SPINEL_ROOT"] || "#{File.dirname(spinel)}/.."
    cache_root = ENV.fetch("FLEEK_MUTATION_CONTRACT_CACHE_ROOT", "build/mutation-contract-cache")
    cache = MutationContractCache.new(cache_root)
    cache.prepare_many(source_directory, contracts, directory, spinel, root, ["-O", "1"]) do |misses|
      compile_missing_contracts(misses, directory, source_directory, jobs)
    end
  end

  # :reek:LongParameterList
  def self.compile_missing_contracts(contracts, directory, source_directory, jobs)
    contracts.each_slice(jobs) { |batch| compile_contract_batch(batch, directory, source_directory) }
  end

  # :reek:TooManyStatements
  def self.compile_contract_batch(contracts, directory, source_directory)
    processes = contracts.map do |contract|
      name = File.basename(contract, ".rb")
      executable = File.expand_path("#{directory}/#{name}")
      temporary_directory = "#{ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")}/spinel-contract-#{name}"
      mkdir_process = Process.spawn("mkdir", "-p", temporary_directory, out: "/dev/null", err: "/dev/null")
      _, mkdir_status = Process.waitpid2(mkdir_process)
      raise "could not create isolated Spinel contract temp directory" unless mkdir_status.success?
      output = MutationProcess.temporary_path("fleek-mutation-contract-#{name}-out")
      error = MutationProcess.temporary_path("fleek-mutation-contract-#{name}-err")
      source = "#{source_directory}/#{File.basename(contract)}"
      process_id = Process.spawn("env", "TMPDIR=#{temporary_directory}", ENV["SPINEL"] || "spinel", "-O", "1", source, "-o", executable,
        out: output, err: error)
      [contract, process_id, output, error]
    end
    processes.each do |contract, process_id, output, error|
      _, status = MutationProcess.wait(process_id)
      verify_contract_compilation(contract, status, error)
    ensure
      delete_file(output)
      delete_file(error)
    end
  end

  def self.verify_contract_compilation(contract, status, error)
    return if status.exitstatus == 0

    warn File.read(error) if File.file?(error)
    raise "#{contract} contract failed to compile"
  end

  def self.delete_file(path)
    File.delete(path) if File.file?(path)
  end

  def self.compile_contract_binary(contract, executable)
    process_id = Process.spawn(ENV["SPINEL"] || "spinel", "-O", "1", contract, "-o", executable,
      out: MutationProcess.temporary_path("fleek-mutation-contract-build-out"), err: MutationProcess.temporary_path("fleek-mutation-contract-build-err"))
    _, status = MutationProcess.wait(process_id)
    raise "#{contract} contract failed to compile" unless status.exitstatus == 0
  end

  def verify_failure(status)
    label = @configuration.label
    raise "#{label} mutant survived" if status.success?
    message = File.read(MutationProcess.temporary_path("fleek-mutation-err"))
    raise "unexpected #{label} failure: #{message}" unless message.include?(@configuration.expected_failure)
    puts "Mutation contract: caught #{label}"
  end
end

# Waits for isolated mutation build and contract subprocesses.
class MutationProcess
  def self.temporary_path(name)
    "#{ENV["FLEEK_TEMP_ROOT"] || "/tmp"}/#{name}"
  end

  # :reek:TooManyStatements
  def self.run_contract(executable)
    process_id = Process.spawn("env", "FLEEK_REFERENCE_CACHE=build/mutation-reference-cache", executable,
      out: temporary_path("fleek-mutation-out"), err: temporary_path("fleek-mutation-err"))
    _, status = wait(process_id)
    status
  end

  def self.build_mutant
    process_id = Process.spawn("make", mutation_compiler_argument, mutation_root_argument, "build/fleek",
      out: temporary_path("fleek-mutation-build-out"), err: temporary_path("fleek-mutation-build-err"))
    _, status = wait(process_id)
    status.success?
  end

  def self.mutation_compiler_argument
    spinel = ENV["SPINEL"] || "spinel"
    "SPINEL=#{spinel} -O 0"
  end

  def self.mutation_root_argument
    spinel = ENV["SPINEL"] || "spinel"
    root = ENV["SPINEL_ROOT"] || "#{File.dirname(spinel)}/.."
    "SPINEL_ROOT=#{root}"
  end

  def self.wait(process_id)
    Process.waitpid2(process_id)
  end
end

if ENV["FLEEK_PRECOMPILE_MUTATION_CONTRACTS"]
  MutationCase.prepare_contracts
  exit 0
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
  "bool same_shape = fleek_duplication_class_shapes_equal(&first_method, &second_method) &&\n        fleek_duplication_optional_parameter_count(first) == fleek_duplication_optional_parameter_count(second) &&\n        fleek_duplication_method_parameter_shapes_equal(first, second);",
  "bool same_shape = false;",
  "Flay structural equality",
  "similar method group report differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (iter_group == 0 && composed_group == 0 && same_shape && mass >= (size_t) mass_threshold) {",
  "if (iter_group == 0 && composed_group == 0 && same_shape && mass > (size_t) mass_threshold) {",
  "Flay mass boundary",
  "similar method group report differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "group_mass = node_mass * count;\n        multiplier = identical ? count : 1;",
  "group_mass = node_mass * count;\n        multiplier = 1;",
  "Flay identical multiplier",
  "top-level array-expression methods differed from Flay: missing node=\"defn\" kind=\"identical\" locations=\"test/fixtures/duplication_methods_array_expression.rb:1,test/fixtures/duplication_methods_array_expression.rb:5\" mass=38 score=76")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "for (size_t index = 0; index < nodes->size; index++) if (!fleek_duplication_parameter_node_supported(nodes->nodes[index], result)) return false;",
  "if (nodes->size > 8) return false;\n      for (size_t index = 0; index < nodes->size; index++) if (!fleek_duplication_parameter_node_supported(nodes->nodes[index], result)) return false;",
  "Flay method parameter count capacity",
  "40-parameter methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_CONSTANT_PATH_NODE] = { 0, 0, 0, false, false, true, FLEEK_DUPLICATION_IDENTITY_CONSTANT, offsetof(pm_constant_path_node_t, name) },",
  "[PM_CONSTANT_PATH_NODE] = { 0, 0, 0, false, false, false, FLEEK_DUPLICATION_IDENTITY_CONSTANT, offsetof(pm_constant_path_node_t, name) },",
  "Flay method constant path candidates",
  "identical constant-path methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "FLEEK_DUPLICATION_IDENTITY_CONSTANT, offsetof(pm_constant_path_node_t, name)",
  "FLEEK_DUPLICATION_IDENTITY_NONE, offsetof(pm_constant_path_node_t, name)",
  "Flay method constant path identity",
  "Fleek scalar-constant_path kind differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "FLEEK_DUPLICATION_IDENTITY_INTEGER, offsetof(pm_integer_node_t, value)",
  "FLEEK_DUPLICATION_IDENTITY_NONE, offsetof(pm_integer_node_t, value)",
  "Flay scalar integer identity",
  "Fleek scalar-integer kind differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "FLEEK_DUPLICATION_IDENTITY_FLOAT, offsetof(pm_float_node_t, value)",
  "FLEEK_DUPLICATION_IDENTITY_NONE, offsetof(pm_float_node_t, value)",
  "Flay scalar float identity",
  "Fleek scalar-float kind differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "FLEEK_DUPLICATION_IDENTITY_STRING, offsetof(pm_string_node_t, unescaped)",
  "FLEEK_DUPLICATION_IDENTITY_NONE, offsetof(pm_string_node_t, unescaped)",
  "Flay scalar string identity",
  "Fleek scalar-string kind differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "FLEEK_DUPLICATION_IDENTITY_SYMBOL, offsetof(pm_symbol_node_t, unescaped)",
  "FLEEK_DUPLICATION_IDENTITY_NONE, offsetof(pm_symbol_node_t, unescaped)",
  "Flay scalar symbol identity",
  "Fleek scalar-symbol kind differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "FLEEK_DUPLICATION_IDENTITY_CONSTANT, offsetof(pm_constant_read_node_t, name)",
  "FLEEK_DUPLICATION_IDENTITY_NONE, offsetof(pm_constant_read_node_t, name)",
  "Flay scalar constant identity",
  "Fleek scalar-constant_read kind differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_CALL_NODE] = { 0, 0, 0, false, false, true, FLEEK_DUPLICATION_IDENTITY_CONSTANT, offsetof(pm_call_node_t, name) },",
  "[PM_CALL_NODE] = { 0, 0, 0, false, false, false, FLEEK_DUPLICATION_IDENTITY_CONSTANT, offsetof(pm_call_node_t, name) },",
  "Flay method call candidates",
  "Fleek call-same_call status or grouping differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_CALL_NODE] = { 0, 0, 0, false, false, true, FLEEK_DUPLICATION_IDENTITY_CONSTANT, offsetof(pm_call_node_t, name) },",
  "[PM_CALL_NODE] = { 0, 0, 0, false, false, true, FLEEK_DUPLICATION_IDENTITY_NONE, offsetof(pm_call_node_t, name) },",
  "Flay method call identity",
  "Fleek call-differing_name kind differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_SPLAT_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_SPLAT_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method call splat candidates",
  "Fleek call-same_splat status or grouping differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (PM_NODE_TYPE_P(node, PM_BLOCK_NODE) && ((const pm_block_node_t *) node)->parameters == NULL) mass_adjustment = 0;",
  "if (PM_NODE_TYPE_P(node, PM_BLOCK_NODE) && ((const pm_block_node_t *) node)->parameters == NULL) mass_adjustment = -2;",
  "Flay method call block mass",
  "Fleek call-same_block mass differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_SPLAT_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_SPLAT_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method splat candidates",
  "splat-argument methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_YIELD_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_YIELD_NODE] = { 0, 0, 0, false, false, false },",
  "Flay yield expression candidates",
  "flow-yield methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_FORWARDING_SUPER_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_FORWARDING_SUPER_NODE] = { 0, 0, 0, false, false, false },",
  "Flay bare super candidates",
  "super methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_SUPER_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_SUPER_NODE] = { 0, 0, 0, false, false, false },",
  "Flay explicit super candidates",
  "super-arguments methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_NEXT_NODE] = { 0, 0, 1, false, false, true },",
  "[PM_NEXT_NODE] = { 0, 0, 1, false, false, false },",
  "Flay next expression candidates",
  "flow-next methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_NEXT_NODE] = { 0, 0, 1, false, false, true },",
  "[PM_NEXT_NODE] = { 0, 0, 0, false, false, true },",
  "Flay next expression mass",
  "flow-next kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_BREAK_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_BREAK_NODE] = { 0, 0, 0, false, false, false },",
  "Flay break expression candidates",
  "flow-break methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_REDO_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_REDO_NODE] = { 0, 0, 0, false, false, false },",
  "Flay redo expression candidates",
  "flow-redo methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_BEGIN_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_BEGIN_NODE] = { 0, 0, 0, false, false, false },",
  "Flay begin expression candidates",
  "flow-rescue-retry methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_RESCUE_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_RESCUE_NODE] = { 0, 0, 0, false, false, false },",
  "Flay rescue expression candidates",
  "flow-rescue-retry methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_RETRY_NODE] = { 0, 0, 1, false, false, true },",
  "[PM_RETRY_NODE] = { 0, 0, 1, false, false, false },",
  "Flay retry expression candidates",
  "flow-rescue-retry methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_RETRY_NODE] = { 0, 0, 1, false, false, true },",
  "[PM_RETRY_NODE] = { 0, 0, 0, false, false, true },",
  "Flay retry expression mass",
  "flow-rescue-retry kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_ENSURE_NODE] = { 0, 0, -1, false, false, true },",
  "[PM_ENSURE_NODE] = { 0, 0, -1, false, false, false },",
  "Flay ensure expression candidates",
  "flow-ensure methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_ENSURE_NODE] = { 0, 0, -1, false, false, true },",
  "[PM_ENSURE_NODE] = { 0, 0, 0, false, false, true },",
  "Flay ensure expression mass",
  "flow-ensure kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "mass += 2;\n            if (begin_node->rescue_clause->reference != NULL) mass += 1;",
  "mass += 0;\n            if (begin_node->rescue_clause->reference != NULL) mass += 1;",
  "Flay composed exception wrapper mass",
  "composed-exception-regexp-identical kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (begin_node->rescue_clause->reference != NULL) mass += 1;",
  "if (begin_node->rescue_clause->reference != NULL) mass += 0;",
  "Flay composed exception binding mass",
  "composed-exception-regexp-identical kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  ".supported = true,\n        .identity = FLEEK_DUPLICATION_IDENTITY_REGULAR_EXPRESSION,",
  ".supported = false,\n        .identity = FLEEK_DUPLICATION_IDENTITY_REGULAR_EXPRESSION,",
  "Flay regular expression candidates",
  "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded")).run
MutationCase.new(MutationCase::Configuration.new(source,
  ".identity = FLEEK_DUPLICATION_IDENTITY_RANGE },",
  ".identity = FLEEK_DUPLICATION_IDENTITY_NONE },",
  "Flay range descriptor identity",
  "generated Flay node descriptor omits RANGE identity for PM_RANGE_NODE")).run
MutationCase.new(MutationCase::Configuration.new(source,
  ".identity = FLEEK_DUPLICATION_IDENTITY_REGULAR_EXPRESSION,",
  ".identity = FLEEK_DUPLICATION_IDENTITY_NONE,",
  "Flay regular expression descriptor identity",
  "generated Flay node descriptor omits REGULAR_EXPRESSION identity for PM_REGULAR_EXPRESSION_NODE")).run
MutationCase.new(MutationCase::Configuration.new(source,
  ".identity = FLEEK_DUPLICATION_IDENTITY_INTERPOLATED_REGULAR_EXPRESSION },",
  ".identity = FLEEK_DUPLICATION_IDENTITY_NONE },",
  "Flay interpolated regular expression descriptor identity",
  "generated Flay node descriptor omits INTERPOLATED_REGULAR_EXPRESSION identity for PM_INTERPOLATED_REGULAR_EXPRESSION_NODE")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "length == 0 || memcmp(pm_string_source(left), pm_string_source(right), length) == 0",
  "true",
  "Flay regular expression content identity",
  "regexp-content kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_FLAGS(left) == PM_NODE_FLAGS(right) && fleek_duplication_strings_equal(left_string, right_string)",
  "true && fleek_duplication_strings_equal(left_string, right_string)",
  "Flay regular expression flags identity",
  "regexp-flags kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  ".mass_adjustment = -1, .supported = true,\n        .identity = FLEEK_DUPLICATION_IDENTITY_INTERPOLATED_REGULAR_EXPRESSION },",
  ".mass_adjustment = -1, .supported = false,\n        .identity = FLEEK_DUPLICATION_IDENTITY_INTERPOLATED_REGULAR_EXPRESSION },",
  "Flay interpolated regular expression candidates",
  "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded")).run
MutationCase.new(MutationCase::Configuration.new(source,
  ".mass_adjustment = -1, .supported = true,\n        .identity = FLEEK_DUPLICATION_IDENTITY_INTERPOLATED_REGULAR_EXPRESSION },",
  ".mass_adjustment = 0, .supported = true,\n        .identity = FLEEK_DUPLICATION_IDENTITY_INTERPOLATED_REGULAR_EXPRESSION },",
  "Flay interpolated regular expression mass",
  "interpolated-regexp kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return PM_NODE_FLAGS(left) == PM_NODE_FLAGS(right) && left_regex->parts.size == right_regex->parts.size;",
  "return true;",
  "Flay interpolated regular expression flags identity",
  "interpolated-regexp-flags kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_INTERPOLATED_STRING_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_INTERPOLATED_STRING_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method interpolated string candidates",
  "interpolated-string methods were not analyzed")).run
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
  "class methods across files were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "method->receiver != NULL || !fleek_duplication_method_parameters((const pm_node_t *) method->parameters, result)",
  "method->receiver != NULL || method->parameters != NULL || !fleek_duplication_method_parameters((const pm_node_t *) method->parameters, result)",
  "Flay required parameter candidates",
  "unsupported Flay candidate syntax")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return fleek_duplication_collect_namespace_methods(module_node, module_name_count, body, source, set);",
  "return true;",
  "Flay module method candidate collection",
  "multi-method Flay module group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (body->body.size == 1 && PM_NODE_TYPE_P(body->body.nodes[0], PM_MODULE_NODE)) {\n        return fleek_duplication_collect_nested_module_methods(module_node,",
  "if (false) {\n        return fleek_duplication_collect_nested_module_methods(module_node,",
  "Flay nested module candidate collection",
  "nested Flay module group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "current = (const pm_module_node_t *) body->body.nodes[0];\n          continue;",
  "return true;",
  "Flay arbitrary-depth nested module traversal",
  "deep nested Flay module candidates differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!fleek_duplication_collect_class_methods((const pm_node_t *) class_node, source, set, true)) return false;",
  "return true;",
  "Flay nested namespace class collection",
  "nested-namespace class group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (body->body.size == 1 && (PM_NODE_TYPE_P(body->body.nodes[0], PM_CLASS_NODE) ||\n            PM_NODE_TYPE_P(body->body.nodes[0], PM_MODULE_NODE))) {",
  "if (body->body.size == 1 && PM_NODE_TYPE_P(body->body.nodes[0], PM_MODULE_NODE)) {",
  "Flay nested class chain traversal",
  "64-level nested class candidates differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (body->body.size == 1 && (PM_NODE_TYPE_P(body->body.nodes[0], PM_CLASS_NODE) ||\n            PM_NODE_TYPE_P(body->body.nodes[0], PM_MODULE_NODE))) {",
  "if (body->body.size == 1 && PM_NODE_TYPE_P(body->body.nodes[0], PM_CLASS_NODE)) {",
  "Flay module scopes inside classes",
  "module scopes inside sibling classes differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (set->candidates[left].scope_types[index] != set->candidates[right].scope_types[index]) return false;",
  "if (false) return false;",
  "Flay mixed scope kind identity",
  "mixed class and module scopes were grouped incorrectly")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "set->candidates[index].scope_kind = 2;\n            set->candidates[index].scope_mass += module_name_count;",
  "set->candidates[index].scope_kind = 1;\n            set->candidates[index].scope_mass += module_name_count;",
  "Flay namespace class module scope kind",
  "namespace class-with-module scope parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "set->scope_lines[candidate] = fleek_source_line(source, class_node->base.location.start);\n            set->candidates[candidate].scope_kind = 1;\n            set->candidates[candidate].scope_mass = scope_depth;",
  "set->scope_lines[candidate] = fleek_source_line(source, class_node->base.location.start);\n            set->candidates[candidate].scope_kind = 1;\n            set->candidates[candidate].scope_mass = scope_depth - 1;",
  "Flay nested class scope mass",
  "module scopes inside sibling classes differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "set->candidates[candidate].scope_mass = inner_name == 0 ? 1 : 2;",
  "set->candidates[candidate].scope_mass = 0;",
  "Flay nested class sibling mass",
  "nested-class siblings group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!direct_methods && nested_body->body.size == 1 && PM_NODE_TYPE_P(nested_body->body.nodes[0], PM_CLASS_NODE)) {",
  "if (false) {",
  "Flay nested wrapped class siblings",
  "nested wrapped class siblings group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!fleek_duplication_scope_leaf_methods((const pm_node_t *) nested_class, &method_body, &scope_depth)) {\n                  fleek_duplication_partial = 1;\n                  continue;\n                }",
  "if (!fleek_duplication_scope_leaf_methods((const pm_node_t *) nested_class, &method_body, &scope_depth) || scope_depth > 1) {\n                  fleek_duplication_partial = 1;\n                  continue;\n                }",
  "Flay nested wrapped sibling scopes",
  "nested class sibling wrappers differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "bool direct_methods = nested_body->body.size > 0;",
  "bool direct_methods = nested_body->body.size == 1;",
  "Flay nested sibling multi-methods",
  "multi-method nested class siblings group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (collect_nested_sibling_scopes) {",
  "if (false) {",
  "Flay mixed sibling scope preservation",
  "mixed sibling scopes hid the independent Flay class group")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!PM_NODE_TYPE_P(method_node, PM_DEF_NODE)) continue;",
  "if (PM_NODE_TYPE_P(method_node, PM_DEF_NODE)) continue;",
  "Flay direct sibling method collection",
  "nested class sibling wrappers differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (collect_nested_sibling_scopes) {",
  "if (false) {",
  "Flay supported siblings beside unsupported class",
  "unsupported class sibling hid the verified Flay group")).run
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
  "if (body->body.size > 1) return fleek_duplication_collect_qualified_namespace_classes(module_node, module_name_count, body, source, set);",
  "if (body->body.size > 1) return true;",
  "Flay qualified namespace multiple classes",
  "multiple qualified-namespace class group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (class_node->body != NULL && !PM_NODE_TYPE_P(class_node->body, PM_STATEMENTS_NODE))",
  "if (class_node->body != NULL && (!PM_NODE_TYPE_P(class_node->body, PM_STATEMENTS_NODE) || ((const pm_statements_node_t *) class_node->body)->body.size > 1))",
  "Flay qualified namespace multi-method classes",
  "multi-method qualified class group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "set->candidates[index].scope_mass = module_name_count + module_class_count + 1;",
  "set->candidates[index].scope_mass = module_name_count + module_class_count;",
  "Flay qualified namespace multiple class mass",
  "multiple qualified-namespace class group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "class_body->body.size == 0 || class_body->body.size != class_candidate_count",
  "class_body->body.size == 0 || class_body->body.size != 1 || class_body->body.size != class_candidate_count",
  "Flay multiple qualified multi-method classes",
  "multiple multi-method qualified classes group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "set->candidates[index].scope_mass = module_name_count + 2;",
  "set->candidates[index].scope_mass = module_name_count + 1;",
  "Flay qualified namespace class mass",
  "qualified-namespace class group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!fleek_duplication_scope_path_element_equal(parser, set, left, right, name)) return false;",
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
  "[PM_OPTIONAL_PARAMETER_NODE] = { .supported = true, .compares_name = true, .has_default = true,",
  "[PM_OPTIONAL_PARAMETER_NODE] = { .supported = false, .compares_name = true, .has_default = true,",
  "Flay optional parameter candidates",
  "unsupported Flay candidate syntax")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!fleek_duplication_optional_default_supported(default_value, rule->allow_integer_call_argument)) return false;",
  "if (false && !fleek_duplication_optional_default_supported(default_value, rule->allow_integer_call_argument)) return false;",
  "Flay optional default boundary",
  "array-parameter-default unsupported result differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_SYMBOL_NODE) || PM_NODE_TYPE_P(node, PM_TRUE_NODE)",
  "PM_NODE_TYPE_P(node, PM_TRUE_NODE)",
  "Flay optional symbol default acceptance",
  "optional-symbol-default methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_FALSE_NODE) || PM_NODE_TYPE_P(node, PM_NIL_NODE) ||\n        PM_NODE_TYPE_P(node, PM_CONSTANT_READ_NODE);",
  "PM_NODE_TYPE_P(node, PM_FALSE_NODE) || PM_NODE_TYPE_P(node, PM_NIL_NODE);",
  "Flay optional positional constant defaults",
  "optional-positional-constant-default-names methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (call->arguments == NULL || call->arguments->arguments.size == 0) return true;",
  "if (call->arguments == NULL || call->arguments->arguments.size == 0) return false;",
  "Flay optional positional bare-call defaults",
  "optional-positional-call-default methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (call->receiver != NULL || call->block != NULL) return false;",
  "if (call->receiver != NULL || call->block != NULL || call->arguments != NULL) return false;",
  "Flay optional positional call argument candidates",
  "optional-positional-call-argument-default methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_OPTIONAL_KEYWORD_PARAMETER_NODE] = { .supported = true, .compares_name = true, .has_default = true,\n        .name_offset = offsetof(pm_optional_keyword_parameter_node_t, name),\n        .default_offset = offsetof(pm_optional_keyword_parameter_node_t, value), .mass_adjustment = 2 },",
  "[PM_OPTIONAL_KEYWORD_PARAMETER_NODE] = { .supported = true, .compares_name = true, .has_default = true,\n        .allow_integer_call_argument = true, .name_offset = offsetof(pm_optional_keyword_parameter_node_t, name),\n        .default_offset = offsetof(pm_optional_keyword_parameter_node_t, value), .mass_adjustment = 2 },",
  "Flay optional keyword call argument boundary",
  "unsupported result differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (default_call->arguments != NULL && default_call->arguments->arguments.size > 0) result->parameter_mass++;",
  "if (default_call->arguments != NULL && default_call->arguments->arguments.size > 0) result->parameter_mass += 0;",
  "Flay optional positional call argument mass",
  "optional-positional-call-argument-default kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  ".default_offset = offsetof(pm_optional_parameter_node_t, value), .mass_adjustment = 2 },",
  ".default_offset = offsetof(pm_optional_parameter_node_t, value), .mass_adjustment = 3 },",
  "Flay optional positional bare-call default mass",
  "optional-positional-call-default kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "result->parameter_mass += (size_t) rule->mass_adjustment;",
  "result->parameter_mass += 0;",
  "Flay optional parameter mass",
  "kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (compare_default && rule->has_default) {",
  "if (false) {",
  "Flay optional default identity",
  "kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_duplication_method_parameters_equal(parser, left, right) &&",
  "true &&",
  "Flay required parameter identity",
  "required-parameter-name kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_IF_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_IF_NODE] = { 0, 0, 0, false, false, false },",
  "Flay class method conditional candidates",
  "branch-if-else methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_UNLESS_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_UNLESS_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method unless candidates",
  "branch-unless methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  ".mass_adjustment = -2, .supported = true, .identity = FLEEK_DUPLICATION_IDENTITY_RANGE },",
  ".mass_adjustment = -2, .supported = false, .identity = FLEEK_DUPLICATION_IDENTITY_RANGE },",
  "Flay method range candidates",
  "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded")).run
MutationCase.new(MutationCase::Configuration.new(source,
  ".mass_adjustment = -2, .supported = true, .identity = FLEEK_DUPLICATION_IDENTITY_RANGE },",
  ".mass_adjustment = 0, .supported = true, .identity = FLEEK_DUPLICATION_IDENTITY_RANGE },",
  "Flay method range mass",
  "range-expression kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_FLAG_P(left, PM_RANGE_FLAGS_EXCLUDE_END) == PM_NODE_FLAG_P(right, PM_RANGE_FLAGS_EXCLUDE_END)",
  "true",
  "Flay method range identity",
  "range-operator kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "size_t next = method->data.ast.node_capacity == 0 ? 16 : method->data.ast.node_capacity;\n      while (next < required) {",
  "size_t next = method->data.ast.node_capacity == 0 ? 16 : method->data.ast.node_capacity;\n      if (next < required) return false;\n      while (next < required) {",
  "Flay method dynamic node capacity",
  "300-expression method candidates were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "size_t next = method->data.ast.tree_capacity == 0 ? 32 : method->data.ast.tree_capacity;\n      while (next < required) {",
  "size_t next = method->data.ast.tree_capacity == 0 ? 32 : method->data.ast.tree_capacity;\n      if (next < required) return false;\n      while (next < required) {",
  "Flay method dynamic tree capacity",
  "300-expression method candidates were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (ast->method->data.ast.tree_count == SIZE_MAX ||\n          !fleek_duplication_reserve_candidate_tree(ast->method, ast->method->data.ast.tree_count + 1)) {",
  "if (false) {",
  "Flay nested tree closing capacity",
  "top-level optional-parameter methods differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_BLOCK_NODE] = { 0, 0, -2, false, false, true },",
  "[PM_BLOCK_NODE] = { 0, 0, -2, false, false, false },",
  "Flay block expression candidates",
  "block-expression methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_SELF_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_SELF_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method self receiver",
  "self_receiver methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (PM_NODE_TYPE_P(node, PM_STATEMENTS_NODE) || PM_NODE_TYPE_P(node, PM_PARENTHESES_NODE)) {\n        const pm_node_t *parent = ast->parent; ast->parent = node;",
  "if (PM_NODE_TYPE_P(node, PM_STATEMENTS_NODE)) {\n        const pm_node_t *parent = ast->parent; ast->parent = node;",
  "Flay parenthesized method expression",
  "parenthesized_expression methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "size_t next = set->capacity == 0 ? 16 : set->capacity;\n      while (next < required) {",
  "size_t next = set->capacity == 0 ? 16 : set->capacity;\n      if (required > 24) return false;\n      while (next < required) {",
  "Flay dynamic class method candidates",
  "2200 class methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "body_count = body->body.size;\n        if (body->body.size == 1",
  "body_count = body->body.size;\n        if (body->body.size > 32) return false;\n        if (body->body.size == 1",
  "Flay dynamic class method body",
  "2200 class methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "static bool fleek_duplication_reserve_buffer(size_t required) {\n      if (required <= fleek_duplication_buffer_capacity) return true;",
  "static bool fleek_duplication_reserve_buffer(size_t required) {\n      if (required > 8192) return false;\n      if (required <= fleek_duplication_buffer_capacity) return true;",
  "Flay dynamic duplication report buffer",
  "2200 class methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_BLOCK_NODE] = { 0, 0, -2, false, false, true },",
  "[PM_BLOCK_NODE] = { 0, 0, 0, false, false, true },",
  "Flay block expression mass",
  "block-expression methods differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (rule->compares_name) {\n        pm_constant_id_t left_name =",
  "if (false) {\n        pm_constant_id_t left_name =",
  "Flay block parameter identity",
  "block-expression methods differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_RETURN_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_RETURN_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method return candidates",
  "branch-return methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_FALSE_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_FALSE_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method false literal candidates",
  "branch-return methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_OR_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_OR_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method OR candidates",
  "branch-or methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_AND_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_AND_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method AND candidates",
  "branch-and methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_CASE_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_CASE_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method CASE candidates",
  "branch-case methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_WHEN_NODE] = { 0, 0, 1, false, false, true },",
  "[PM_WHEN_NODE] = { 0, 0, 1, false, false, false },",
  "Flay method WHEN candidates",
  "branch-case methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_FLOAT_NODE] = { 0, 0, 0, false, false, true, FLEEK_DUPLICATION_IDENTITY_FLOAT, offsetof(pm_float_node_t, value) },",
  "[PM_FLOAT_NODE] = { 0, 0, 0, false, false, false, FLEEK_DUPLICATION_IDENTITY_FLOAT, offsetof(pm_float_node_t, value) },",
  "Flay method float candidates",
  "top-level methods with float literals differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_NIL_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_NIL_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method nil candidates",
  "top-level methods with nil literals differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "FLEEK_NAMED_NODE_RULE(PM_LOCAL_VARIABLE_WRITE_NODE, pm_local_variable_write_node_t, 0),",
  "[PM_LOCAL_VARIABLE_WRITE_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method local write candidates",
  "top-level methods with local writes differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_ARRAY_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_ARRAY_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method array expression",
  "method-array-expression methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_HASH_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_HASH_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method hash expression",
  "method-keyword-hash-expression methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_ASSOC_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_ASSOC_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method hash-rocket expression",
  "top-level hash-rocket methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_WHILE_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_WHILE_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method while loop candidates",
  "loop-while methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_UNTIL_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_UNTIL_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method until loop candidates",
  "loop-until methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_FOR_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_FOR_NODE] = { 0, 0, 0, false, false, false },",
  "Flay method for loop candidates",
  "for-control methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return (left == 0 || right == 0) ? left == right : fleek_constants_equal(parser, left, right);",
  "return (left == 0 || right == 0) ? left == right : true;",
  "Flay method rest parameter identity",
  "kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_REQUIRED_KEYWORD_PARAMETER_NODE] = { .supported = true, .compares_name = true,",
  "[PM_REQUIRED_KEYWORD_PARAMETER_NODE] = { .supported = false, .compares_name = true,",
  "Flay required keyword parameter candidates",
  "keyword-parameter methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "bool names_equal = rule->optional_name ? fleek_duplication_optional_parameter_name_equal(parser, left_name, right_name) : fleek_constants_equal(parser, left_name, right_name);",
  "bool names_equal = true;",
  "Flay required keyword parameter identity",
  "required-parameter-name kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_REQUIRED_KEYWORD_PARAMETER_NODE] = { .supported = true, .compares_name = true,\n        .name_offset = offsetof(pm_required_keyword_parameter_node_t, name), .mass_adjustment = 1 },",
  "[PM_REQUIRED_KEYWORD_PARAMETER_NODE] = { .supported = true, .compares_name = true,\n        .name_offset = offsetof(pm_required_keyword_parameter_node_t, name), .mass_adjustment = 0 },",
  "Flay required keyword parameter mass",
  "keyword-parameter kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_OPTIONAL_KEYWORD_PARAMETER_NODE] = { .supported = true, .compares_name = true, .has_default = true,",
  "[PM_OPTIONAL_KEYWORD_PARAMETER_NODE] = { .supported = false, .compares_name = true, .has_default = true,",
  "Flay optional keyword parameter candidates",
  "optional-keyword-parameter methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  ".default_offset = offsetof(pm_optional_keyword_parameter_node_t, value), .mass_adjustment = 2 },",
  ".default_offset = offsetof(pm_optional_keyword_parameter_node_t, value), .mass_adjustment = 0 },",
  "Flay optional keyword parameter mass",
  "optional-keyword-parameter kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (PM_NODE_TYPE_P(node, PM_CALL_NODE)) {",
  "if (false && PM_NODE_TYPE_P(node, PM_CALL_NODE)) {",
  "Flay optional keyword bare-call defaults",
  "optional-keyword-call-default methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return fleek_duplication_node_rule(node->type) != NULL;",
  "return false;",
  "Flay node-rule candidate support",
  "method-array-expression methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "int8_t mass_adjustment = node_rule->mass_adjustment;",
  "int8_t mass_adjustment = 0;",
  "Flay node-rule mass adjustments",
  "multiple-assignment kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  ".mass_adjustment = -2, .supported = true, .identity = FLEEK_DUPLICATION_IDENTITY_RANGE },",
  ".mass_adjustment = -2, .supported = false, .identity = FLEEK_DUPLICATION_IDENTITY_RANGE },",
  "Flay generated descriptor support",
  "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded")).run
MutationCase.new(MutationCase::Configuration.new(source,
  ".mass_adjustment = -2, .supported = true, .identity = FLEEK_DUPLICATION_IDENTITY_RANGE },",
  ".mass_adjustment = 0, .supported = true, .identity = FLEEK_DUPLICATION_IDENTITY_RANGE },",
  "Flay generated descriptor mass",
  "generated Flay descriptor results differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (rule->compares_name) {",
  "if (false) {",
  "Flay variable-rule name identity",
  "multiple-assignment-names kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (rule->compares_operator) {",
  "if (false) {",
  "Flay variable-rule operator identity",
  "local-operator-write-operators kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "PM_NODE_TYPE_P(node, PM_FALSE_NODE) || PM_NODE_TYPE_P(node, PM_NIL_NODE) ||\n        PM_NODE_TYPE_P(node, PM_CONSTANT_READ_NODE);",
  "PM_NODE_TYPE_P(node, PM_FALSE_NODE) || PM_NODE_TYPE_P(node, PM_NIL_NODE);",
  "Flay optional keyword constant defaults",
  "optional-keyword-nonliteral methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_REQUIRED_PARAMETER_NODE] = { .supported = true, .compares_name = true, .name_offset = offsetof(pm_required_parameter_node_t, name) },",
  "[PM_REQUIRED_PARAMETER_NODE] = { .supported = false, .compares_name = true, .name_offset = offsetof(pm_required_parameter_node_t, name) },",
  "Flay post parameter candidates",
  "unsupported Flay candidate syntax")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_REQUIRED_PARAMETER_NODE] = { .supported = true, .compares_name = true, .name_offset = offsetof(pm_required_parameter_node_t, name) },",
  "[PM_REQUIRED_PARAMETER_NODE] = { .supported = true, .compares_name = true, .name_offset = offsetof(pm_required_parameter_node_t, name), .mass_adjustment = 1 },",
  "Flay post parameter mass",
  "required-parameter kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "bool names_equal = rule->optional_name ? fleek_duplication_optional_parameter_name_equal(parser, left_name, right_name) : fleek_constants_equal(parser, left_name, right_name);",
  "bool names_equal = true;",
  "Flay post parameter identity",
  "required-parameter-name kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_REST_PARAMETER_NODE] = { .supported = true, .compares_name = true, .optional_name = true,",
  "[PM_REST_PARAMETER_NODE] = { .supported = false, .compares_name = true, .optional_name = true,",
  "Flay anonymous variadic parameter candidates",
  "unsupported Flay candidate syntax")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return (left == 0 || right == 0) ? left == right : fleek_constants_equal(parser, left, right);",
  "return (left == 0 || right == 0) ? left == right : true;",
  "Flay keyword-rest parameter identity",
  "kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_BLOCK_PARAMETER_NODE] = { .supported = true, .compares_name = true, .optional_name = true,",
  "[PM_BLOCK_PARAMETER_NODE] = { .supported = false, .compares_name = true, .optional_name = true,",
  "Flay method block parameter candidates",
  "unsupported Flay candidate syntax")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return (left == 0 || right == 0) ? left == right : fleek_constants_equal(parser, left, right);",
  "return (left == 0 || right == 0) ? true : fleek_constants_equal(parser, left, right);",
  "Flay method block parameter identity",
  "kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return (left == 0 || right == 0) ? left == right : fleek_constants_equal(parser, left, right);",
  "return false;",
  "Flay anonymous method block parameter identity",
  "kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return (left == 0 || right == 0) ? left == right : fleek_constants_equal(parser, left, right);",
  "return (left == 0 || right == 0) ? false : fleek_constants_equal(parser, left, right);",
  "Flay anonymous variadic parameter identity",
  "kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "bool names_equal = rule->optional_name ? fleek_duplication_optional_parameter_name_equal(parser, left_name, right_name) : fleek_constants_equal(parser, left_name, right_name);",
  "bool names_equal = true;",
  "Flay optional keyword parameter identity",
  "required-parameter-name kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (compare_default && rule->has_default) {",
  "if (false) {",
  "Flay optional keyword constant default identity",
  "kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!fleek_duplication_scalar_identity_equal(parser, left, right)) return false;",
  "if (false) return false;",
  "Flay optional positional bare-call default identity",
  "optional-positional-call-default kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "!fleek_duplication_scalar_identity_equal(parser, left_argument, right_argument)) return false;",
  "true) return false;",
  "Flay optional positional call argument identity",
  "optional-positional-call-argument-identity kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "(PM_NODE_TYPE_P(node, PM_ASSOC_NODE) && PM_NODE_TYPE_P(ast->parent, PM_HASH_NODE))",
  "(PM_NODE_TYPE_P(node, PM_ASSOC_NODE) && false)",
  "Flay method hash association mass",
  "method-keyword-hash-expression kind, mass, or locations differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (rule->compares_name) {",
  "if (false) {",
  "Flay method local write identity",
  "multiple-assignment-names kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_BLOCK_PARAMETERS_NODE] = { 0, 0, 0, false, false, true },",
  "[PM_BLOCK_PARAMETERS_NODE] = { 0, 0, 0, false, false, false },",
  "Flay block optional parameter candidates",
  "block-optional-parameter methods were not analyzed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return PM_NODE_TYPE_P(parameters, PM_PARAMETERS_NODE) && ((const pm_parameters_node_t *) parameters)->optionals.size > 0 ? rule->mass_adjustment : 0;",
  "return PM_NODE_TYPE_P(parameters, PM_PARAMETERS_NODE) && ((const pm_parameters_node_t *) parameters)->optionals.size > 0 ? 0 : 0;",
  "Flay block optional parameter mass",
  "block-optional-parameter kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (method->has_optional_method_parameters && PM_NODE_TYPE_P(method->data.ast.nodes[index], PM_BLOCK_PARAMETERS_NODE) && adjustment > 0) adjustment--;",
  "if (false && PM_NODE_TYPE_P(method->data.ast.nodes[index], PM_BLOCK_PARAMETERS_NODE) && adjustment > 0) adjustment--;",
  "Flay composed parameter block mass",
  "composed-signature-block-identical kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "int iter_group = same_shape ? 0 :\n        fleek_duplication_emit_matching_iter_group(&parser, (const uint8_t *) source,\n          iter_methods, 2, mass_threshold);",
  "int iter_group = 0;",
  "Flay composed block subtree selection",
  "renamed-default block group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "selected_mass + 3",
  "selected_mass + 2",
  "Flay composed cross-file subtree selection",
  "top default-order-0 result differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (fleek_duplication_composed_exception(candidate, node)) return false;",
  "if (false) return false;",
  "Flay composed cross-file class pruning",
  "class default-order-0 result differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_duplication_method_parameter_shapes_equal(first, second)",
  "true",
  "Flay method parameter shape selection",
  "Fleek renamed-default block group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!parameter_shapes_equal) {",
  "if (false) {",
  "Flay class method parameter shape selection",
  "generated Flay case composed-class-signature-block failed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "for (size_t first_node = 0; first_node < first->shape_count; first_node++) {",
  "for (size_t first_node = 0; first_node < 1; first_node++) {",
  "Flay multiple composed block groups",
  "generated Flay case composed-class-signature-block failed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "bool names_equal = rule->optional_name ? fleek_duplication_optional_parameter_name_equal(parser, left_name, right_name) : fleek_constants_equal(parser, left_name, right_name);",
  "bool names_equal = true;",
  "Flay block optional parameter name identity",
  "block-optional-parameter-names kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "!fleek_duplication_scalar_identity_equal(parser, left, right)",
  "false",
  "Flay block optional parameter expression identity",
  "block-optional-parameter-expression kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "[PM_ELSE_NODE] = { 0, 0, -1, false, false, true },",
  "[PM_ELSE_NODE] = { 0, 0, 0, false, false, true },",
  "Flay class method conditional mass",
  "top-level methods with conditionals differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "size_t next = set->capacity == 0 ? 16 : set->capacity;\n      while (next < required) {",
  "size_t next = set->capacity == 0 ? 16 : set->capacity;\n      if (required > 16) return false;\n      while (next < required) {",
  "Flay class method candidate capacity",
  "class-method candidate capacity parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "const pm_node_t *child = body->body.nodes[index];\n          if (!PM_NODE_TYPE_P(child, PM_DEF_NODE)) { fleek_duplication_partial = 1; continue; }\n          if (!fleek_duplication_reserve_next_class_candidate(set) ||",
  "const pm_node_t *child = body->body.nodes[index];\n          if (!PM_NODE_TYPE_P(child, PM_DEF_NODE)) { fleek_duplication_partial = 1; continue; }\n          if (set->count >= 1 || !fleek_duplication_reserve_next_class_candidate(set) ||",
  "Flay additional class method rejection",
  "Rails-shaped class method parity differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (method_count != 0 || ffi_module_count != 0 || !fleek_duplication_collect_class_methods(statement, (const uint8_t *) source, &class_candidates, collect_nested_sibling_scopes)) {",
  "if (scope_count != 0 || method_count != 0 || ffi_module_count != 0 || !fleek_duplication_collect_class_methods(statement, (const uint8_t *) source, &class_candidates, collect_nested_sibling_scopes)) {",
  "Flay multiple class declarations",
  "class methods across classes were not compared")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (count < 2) continue;\n        bool identical = true;\n        for (size_t index = 0; index < count; index++) {\n          size_t candidate = members[index];\n          lines[index] = set->scope_lines[candidate];",
  "if (count < 3) continue;\n        bool identical = true;\n        for (size_t index = 0; index < count; index++) {\n          size_t candidate = members[index];\n          lines[index] = set->scope_lines[candidate];",
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
  "different method shapes were grouped")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "left_mass >= (size_t) mass_threshold && left_mass == right_mass &&\n                  fleek_duplication_class_subtrees_equal(&set->candidates[left], left_node, &set->candidates[right], right_node)",
  "false",
  "Flay class method partial subtree",
  "partial class-method duplicate was silently skipped")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (adjustment < 0) mass -= (size_t) (-adjustment);\n        else mass += (size_t) adjustment;",
  "if (adjustment < 0) mass -= (size_t) (-adjustment);\n        else mass -= (size_t) adjustment;",
  "Flay method case condition mass",
  "branch-case kind, mass, or locations differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_duplication_scope_method_mass(set, first) + fleek_duplication_scope_mass(parser, set, first)",
  "fleek_duplication_scope_method_mass(set, first) + fleek_duplication_scope_mass(parser, set, first) - 1",
  "Flay outer scope mass",
  "cross-class Flay group differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "result->line = 1;\n      result->source_offset = (size_t) (method->def_keyword_loc.start - source);\n      for (const uint8_t *cursor = source; cursor < method->def_keyword_loc.start; cursor++) if (*cursor == '\\\\n') result->line++;\n      return true;\n    }\n    static bool fleek_duplication_constant_path_names",
  "result->line = 1;\n      result->source_offset = (size_t) (method->def_keyword_loc.start - source);\n      return true;\n    }\n    static bool fleek_duplication_constant_path_names",
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
  'patterns.any? { |pattern| flay_ignore_match?(path, pattern) }',
  'false',
  "Flay ignore scope",
  "Flay ignore did not report excluded source")).run
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
  'state->private_methods[state->count] = private_visibility;',
  'state->private_methods[state->count] = false;',
  "UnusedPrivateMethod private visibility",
  "UnusedPrivateMethod findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'state->private_methods[method_index] = fleek_name_is(parser, call->name, "private");',
  'state->private_methods[method_index] = false;',
  "UnusedPrivateMethod named visibility",
  "UnusedPrivateMethod findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'private_visibility = fleek_name_is(parser, call->name, "private");',
  'private_visibility = true;',
  "UnusedPrivateMethod public visibility",
  "UnusedPrivateMethod findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'if (fleek_constants_equal(call_state->parser, call->name, call_state->state->methods[index]->name)) call_state->state->used[index] = true;',
  'if (false) call_state->state->used[index] = true;',
  "UnusedPrivateMethod direct call tracking",
  "UnusedPrivateMethod findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'fleek_name_is(call_state->parser, call->name, "send")',
  'false',
  "UnusedPrivateMethod dynamic call boundary",
  "dynamic private method call was treated as complete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'paths.any? { |path| effective_detector_enabled(name, best_scope(path)) }',
  'paths.any? { |_path| effective_detector_enabled(name, -1) }',
  "Reek directory detector precedence",
  "Fleek ignored the parent directory disablement")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (PM_NODE_TYPE_P(node, PM_ARGUMENTS_NODE)) {",
  "if (false) {",
  "Flay top-level method argument calls",
  "top-level methods with argument calls differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (method->receiver != NULL || !fleek_duplication_method_parameters((const pm_node_t *) method->parameters, result) ||",
  "if (method->receiver != NULL || method->parameters != NULL ||",
  "Flay top-level required parameters",
  "unsupported Flay candidate syntax")).run
MutationCase.new(MutationCase::Configuration.new(source,
  '["--mass", "--only", "--liberal", "--fuzzy", "--legacy"].include?(argument)',
  '["--only", "--liberal", "--fuzzy", "--legacy"].include?(argument)',
  "Flay mass check applicability",
  "inapplicable Flay mass was not rejected before Reek analysis")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'group.node == only_node',
  'true',
  "Flay only node filtering",
  "--only class did not filter displayed Flay groups")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'puts "Total duplication score: #{score}"',
  'puts "Total duplication score: 0"',
  "Flay only total score preservation",
  "--only class did not preserve unfiltered total score")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'node = inputs[index + 1] if inputs[index] == "--only"',
  'node = inputs[1] if inputs[index] == "--only"',
  "Flay only repeated option precedence",
  "repeated --only did not use last value")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'return "--only requires a node type." unless node && !node.start_with?("-")',
  'node = node || ""',
  "Flay only missing repeated value",
  "missing repeated --only diagnostic changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  '["--mass", "--only", "--liberal", "--fuzzy", "--legacy"].include?(argument)',
  '["--mass", "--liberal", "--fuzzy", "--legacy"].include?(argument)',
  "Flay only check applicability",
  "inapplicable Flay only was not rejected before Reek analysis")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'input != "--liberal"',
  'input != "--only"',
  "Flay liberal option recognition",
  "liberal pruning omitted retained method candidates")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (covered[candidate] && !liberal) pruned = true;",
  "if (covered[candidate]) pruned = true;",
  "Flay liberal candidate retention",
  "liberal pruning omitted retained method candidates")).run
MutationCase.new(MutationCase::Configuration.new(source,
  '["--mass", "--only", "--liberal", "--fuzzy", "--legacy"].include?(argument)',
  '["--mass", "--only", "--fuzzy", "--legacy"].include?(argument)',
  "Flay liberal check applicability",
  "inapplicable Flay liberal was not rejected before Reek analysis")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'reek_inputs = without_option(without_option_pairs(without_option_pairs(without_option(without_optional_integer_option(inputs, "--fuzzy"), "--liberal"), "--mass"), "--only"), "--legacy")',
  'reek_inputs = without_option(without_option_pairs(without_option_pairs(without_optional_integer_option(inputs, "--fuzzy"), "--mass"), "--only"), "--legacy")',
  "Flay liberal combined routing",
  "combined Flay liberal status")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'input != "--fuzzy"',
  'input != "--only"',
  "Flay fuzzy option recognition",
  "Flay fuzzy CLI outcome changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (fuzzy > 0 && !same_shape && iter_group == 0) {",
  "if (false && !same_shape && iter_group == 0) {",
  "Flay fuzzy candidate collection",
  "Flay fuzzy CLI outcome changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "distance = candidate || 1",
  "distance = candidate || 0",
  "Flay fuzzy explicit distance parsing",
  "bare --fuzzy no longer defaults to distance one")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (removed_count > limit || masses[side] < removed_mass || masses[side] - removed_mass != masses[1 - side] ||",
  "if (removed_count > 1 || masses[side] < removed_mass || masses[side] - removed_mass != masses[1 - side] ||",
  "Flay fuzzy multiple statement matching",
  "Fleek distance two outcome changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'inputs.rindex("--mass") || inputs.length',
  'inputs.index("--mass") || inputs.length',
  "Flay repeated mass precedence",
  "repeated --mass did not use last value")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'index += next_input && next_input.match?(/\\A[0-9]+\\z/) ? 2 : 1',
  'index += next_input && !next_input.start_with?("-") ? 2 : 1',
  "Flay fuzzy liberal source routing",
  "fuzzy liberal routing lost source path")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (legacy) {\n        fleek_legacy_parser_state_t state = { false };",
  "if (false) {\n        fleek_legacy_parser_state_t state = { false };",
  "Flay legacy parser boundary",
  "Fleek legacy parser failure test/fixtures/ruby4_duplicate.rb changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  '["--mass", "--only", "--liberal", "--fuzzy", "--legacy"].include?(argument)',
  '["--mass", "--only", "--liberal", "--fuzzy"].include?(argument)',
  "Flay legacy check applicability",
  "Reek-only legacy option changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'File.exist?(".flayignore")',
  'File.file?(".flayignore")',
  "Flay unreadable ignore file",
  "Fleek unreadable ignore file did not report an error")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'return File.fnmatch?(absolute_pattern.tr("/", "\u0001"), absolute_path.tr("/", "\u0001")) unless pattern.include?("/")',
  'return File.fnmatch?(absolute_pattern, absolute_path) unless pattern.include?("/")',
  "Flay basename ignore matching",
  "nested basename glob source set differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'files.map { |path| normalize_duplication_source_path(path) }.uniq',
  'files.map { |path| normalize_duplication_source_path(path) }',
  "Flay path deduplication",
  "Fleek did not deduplicate overlapping paths")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'next if part.empty? || part == "."',
  'next if part.empty?',
  "Flay lexical path normalization",
  "Fleek did not deduplicate overlapping paths")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'return "" if path.empty?',
  '""',
  "Flay empty path safety",
  "Fleek empty-path fail-closed policy changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (left_size > 10 || right_size > 10 || left_mass / left_size > 12 || right_mass / right_size > 12) return 0;",
  "if (false) return 0;",
  "Flay fuzzy candidate bounds",
  "Flay fuzzy CLI outcome changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'fuzzy = fuzzy_locations.empty? ? "" : " fuzzy_locations=#{quote_text(fuzzy_locations.join(","))}"',
  'fuzzy = ""',
  "Flay fuzzy location attribution",
  "Flay fuzzy CLI report changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'check == FLAY_CHECK && inputs.include?("--reek-config") ? "--reek-config applies only to Reek checks." : ""',
  'false',
  "Reek config check applicability",
  "inapplicable Reek config was not rejected before Flay analysis")).run
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

process_id = Process.spawn("make", "build/fleek", out: MutationProcess.temporary_path("fleek-mutation-restore-out"), err: MutationProcess.temporary_path("fleek-mutation-restore-err"))
_, status = Process.waitpid2(process_id)
raise "mutation restore failed" unless status.success?
