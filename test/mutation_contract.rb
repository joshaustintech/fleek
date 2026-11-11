# Proves public checks reject deliberately broken parser, CLI, and analyzer behaviors.
require_relative "mutation_contract_cache"

MUTATION_SHARD = nil
MUTATION_SHARDS = nil

# Runs one configured source mutation and requires its public contract to fail.
class MutationCase
  # :reek:DuplicateMethodCall
  # :reek:TooManyStatements
  # Carries one behavior mutation and its expected contract failure.
  Configuration = Struct.new(:source, :target, :replacement, :label, :expected_failure, :path)
  COMPILED_CONTRACTS = {}
  CONTRACTS = {
    "Flay generic sexp mass" => "test/duplication_generic_contract.rb",
    "Flay generic root exclusion" => "test/duplication_generic_contract.rb",
    "Flay generic singleton pruning" => "test/duplication_generic_contract.rb",
    "Flay generic conservative pruning" => "test/duplication_generic_contract.rb",
    "Flay generic liberal pruning" => "test/duplication_generic_contract.rb",
    "Flay generic identity" => "test/duplication_generic_contract.rb",
    "Flay generic mass threshold" => "test/duplication_contract.rb",
    "Flay generic statement block" => "test/duplication_generic_contract.rb",
    "Flay generic right-nested logical" => "test/duplication_generic_contract.rb",
    "Flay generic unless branches" => "test/duplication_generic_contract.rb",
    "Flay generic class variable scope" => "test/duplication_generic_contract.rb",
    "Flay generic hash values" => "test/duplication_generic_contract.rb",
    "Flay generic fuzzy template bounds" => "test/duplication_fuzzy_contract.rb",
    "Flay generic fuzzy marking" => "test/duplication_fuzzy_contract.rb",
    "Flay generic source paths" => "test/duplication_contract.rb",
    "Flay generic legacy syntax" => "test/legacy_parser_contract.rb",
    "Flay generic call name identity" => "test/duplication_method_call_contract.rb",
    "Flay per-file parse continuation" => "test/duplication_contract.rb",
    "Reek AST begin wrapping" => "test/reek_ast_contract.rb",
    "Reek engine descriptive comment threshold" => "test/reek_engine_contract.rb",
    "Reek engine namespace modules" => "test/reek_engine_contract.rb",
    "Reek engine comment suppression" => "test/reek_engine_contract.rb",
    "Reek engine last directive wins" => "test/reek_engine_contract.rb",
    "Reek engine parent suppression" => "test/reek_engine_contract.rb",
    "Reek engine Struct modules" => "test/reek_engine_contract.rb",
    "Reek engine root naming" => "test/reek_engine_contract.rb",
    "Reek engine begin statements" => "test/reek_engine_contract.rb",
    "Reek engine if statements" => "test/reek_engine_contract.rb",
    "Reek engine block statements" => "test/reek_engine_contract.rb",
    "Reek engine method body statements" => "test/reek_engine_contract.rb",
    "Reek engine directive statement limit" => "test/reek_engine_contract.rb",
    "Reek engine singleton method names" => "test/reek_engine_contract.rb",
    "Reek engine rescue statements" => "test/reek_engine_contract.rb",
    "Reek engine case statements" => "test/reek_engine_contract.rb",
    "Reek engine loop statements" => "test/reek_engine_contract.rb",
    "Reek default initialize exclusion" => "test/reek_engine_contract.rb",
    "Reek engine ignored iterator depth" => "test/reek_engine_contract.rb",
    "Reek engine argumentless iterators" => "test/reek_engine_contract.rb",
    "Reek engine iterators in calls" => "test/reek_engine_contract.rb",
    "Reek engine iterator depth groups" => "test/reek_engine_contract.rb",
    "Reek engine ignored iterator patterns" => "test/reek_engine_contract.rb",
    "Reek engine self as most popular" => "test/reek_engine_contract.rb",
    "Reek engine object creation calls" => "test/reek_engine_contract.rb",
    "Reek engine self call references" => "test/reek_engine_contract.rb",
    "Reek engine envy without self" => "test/reek_engine_contract.rb",
    "Reek engine operator assignment references" => "test/reek_engine_contract.rb",
    "Reek engine module function methods" => "test/reek_engine_contract.rb",
    "Reek engine methods without calls" => "test/reek_engine_contract.rb",
    "Reek engine public methods only directive" => "test/reek_engine_contract.rb",
    "Reek engine named visibility" => "test/reek_engine_contract.rb",
    "Reek engine ghost singleton methods" => "test/reek_engine_contract.rb",
    "Reek engine refinement contexts" => "test/reek_engine_contract.rb",
    "Reek engine parent expression comments" => "test/reek_engine_contract.rb",
    "Reek engine super self references" => "test/reek_engine_contract.rb",
    "Reek engine nil queries" => "test/reek_engine_contract.rb",
    "Reek engine case equality nil checks" => "test/reek_engine_contract.rb",
    "Reek engine when nil checks" => "test/reek_engine_contract.rb",
    "Reek engine duplicate object creation" => "test/reek_engine_contract.rb",
    "Reek engine duplicate simple calls" => "test/reek_engine_contract.rb",
    "Reek engine duplicate blocks" => "test/reek_engine_contract.rb",
    "Reek engine duplicate assignment targets" => "test/reek_engine_contract.rb",
    "Reek engine duplicate call limit directive" => "test/reek_engine_contract.rb",
    "Reek engine duplicate allowed calls" => "test/reek_engine_contract.rb",
    "Reek engine control calls in conditions" => "test/reek_engine_contract.rb",
    "Reek engine control comparisons" => "test/reek_engine_contract.rb",
    "Reek engine control body uses" => "test/reek_engine_contract.rb",
    "Reek engine control logical bodies" => "test/reek_engine_contract.rb",
    "Reek engine control nested branches" => "test/reek_engine_contract.rb",
    "Reek engine unused implicit super" => "test/reek_engine_contract.rb",
    "Reek engine unused underscore markers" => "test/reek_engine_contract.rb",
    "Reek engine unused parameter reads" => "test/reek_engine_contract.rb",
    "Reek engine unused parameter assignments" => "test/reek_engine_contract.rb",
    "Reek engine unused block arguments" => "test/reek_engine_contract.rb",
    "Reek engine destructured parameters" => "test/reek_engine_contract.rb",
    "Reek engine false boolean defaults" => "test/reek_engine_contract.rb",
    "Reek engine keyword boolean defaults" => "test/reek_engine_contract.rb",
    "Reek engine block arguments in parameter counts" => "test/reek_engine_contract.rb",
    "Reek engine initialize parameter override" => "test/reek_engine_contract.rb",
    "Reek engine parameter limit directive" => "test/reek_engine_contract.rb",
    "Reek engine yield limit boundary" => "test/reek_engine_contract.rb",
    "Reek engine module-defining constants" => "test/reek_engine_contract.rb",
    "Reek engine instance variable or-assignments" => "test/reek_engine_contract.rb",
    "Reek engine distinct instance variables" => "test/reek_engine_contract.rb",
    "Reek engine singleton class method counts" => "test/reek_engine_contract.rb",
    "Reek engine module singleton initialize" => "test/reek_engine_contract.rb",
    "Reek engine module constant counts" => "test/reek_engine_contract.rb",
    "Reek engine private attributes" => "test/reek_engine_contract.rb",
    "Reek engine string attribute names" => "test/reek_engine_contract.rb",
    "Reek engine memoized instance variables" => "test/reek_engine_contract.rb",
    "Reek engine initialized instance variables" => "test/reek_engine_contract.rb",
    "Reek engine Class.new core superclasses" => "test/reek_engine_contract.rb",
    "Reek engine namespaced superclasses" => "test/reek_engine_contract.rb",
    "Reek engine safe method companions" => "test/reek_engine_contract.rb",
    "Reek engine excluded bang methods" => "test/reek_engine_contract.rb",
    "Reek engine respond_to calls" => "test/reek_engine_contract.rb",
    "Reek AST string lines" => "test/reek_ast_contract.rb",
    "Reek AST pattern guards" => "test/reek_ast_contract.rb",
    "Reek AST regexp match assignment" => "test/reek_ast_contract.rb",
    "Reek AST legacy forward args" => "test/reek_ast_contract.rb",
    "Reek AST unless branches" => "test/reek_ast_contract.rb",
    "Flay parse failure attribution" => "test/duplication_contract.rb",
    "embedded NUL acceptance" => "test/native_parser_contract.rb",
    "Ruby 4 grammar downgrade" => "test/native_parser_contract.rb",
    "location attribution" => "test/native_parser_contract.rb",
    "ClassVariable occurrence grouping" => "test/class_variable_scope_contract.rb",
    "ClassVariable nested scope isolation" => "test/class_variable_scope_contract.rb",
    "inherited ClassVariable class rejection" => "test/class_variable_contract.rb",
    "ClassVariable namespace context traversal" => "test/class_variable_contract.rb",
    "ClassVariable wrapped namespace child acceptance" => "test/class_variable_contract.rb",
    "qualified ClassVariable namespace context" => "test/class_variable_contract.rb",
    "ClassVariable nested namespace class support" => "test/class_variable_contract.rb",
    "ClassVariable nested namespace boundary" => "test/class_variable_contract.rb",
    "ClassVariable namespace occurrence handling" => "test/class_variable_contract.rb",
    "missing ClassVariable finding" => "test/text_report_contract.rb",
    "wrong ClassVariable location" => "test/text_report_contract.rb",
    "false-positive ClassVariable finding" => "test/text_report_contract.rb",
    "wrong ClassVariable findings status" => "test/text_report_contract.rb",
    "UnusedPrivateMethod empty framework subclass handling" => "test/default_argument_api_contract.rb",
    "ignored DuplicateMethodCall list entry" => "test/default_argument_api_contract.rb",
    "RepeatedConditional class scope isolation" => "test/default_argument_api_contract.rb",
    "ignored MissingSafeMethod exclusion entry" => "test/default_argument_api_contract.rb",
    "missing RepeatedConditional finding" => "test/default_argument_api_contract.rb",
    "ignored NestedIterators list entry" => "test/default_argument_api_contract.rb",
    "missing DataClump finding" => "test/default_argument_api_contract.rb",
    "DataClump first-method dependence" => "test/default_argument_api_contract.rb",
    "DataClump singleton parameter participation" => "test/default_argument_api_contract.rb",
    "DataClump first clump only" => "test/default_argument_api_contract.rb",
    "DataClump drops findings on incomplete syntax" => "test/default_argument_api_contract.rb",
    "UncommunicativeMethodName nested singleton context" => "test/default_argument_api_contract.rb",
    "UncommunicativeModuleName qualified context" => "test/default_argument_api_contract.rb",
    "UncommunicativeVariableName block parameters" => "test/default_argument_api_contract.rb",
    "missing UncommunicativeMethodName finding" => "test/default_argument_api_contract.rb",
    "missing UncommunicativeModuleName finding" => "test/default_argument_api_contract.rb",
    "missing UncommunicativeParameterName finding" => "test/default_argument_api_contract.rb",
    "missing UncommunicativeVariableName finding" => "test/default_argument_api_contract.rb",
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
    "Flay negative timeout incomplete outcome" => "test/duplication_timeout_contract.rb",
    "Flay timeout interrupts native worker" => "test/duplication_timeout_contract.rb",
    "Flay per-file timeout retains completed source" => "test/duplication_timeout_contract.rb",
    "Flay numbering no-op support" => "test/duplication_presentation_contract.rb",
    "Flay identical multiplier" => "test/duplication_contract.rb",
    "Flay total score" => "test/duplication_contract.rb",
    "Flay keyword-rest parameter candidates" => "test/duplication_method_parameter_contract.rb",
    "Flay mass check applicability" => "test/cli_contract.rb",
    "Flay only node filtering" => "test/duplication_only_node_contract.rb",
    "Flay only total score preservation" => "test/duplication_only_node_contract.rb",
    "Flay only repeated option precedence" => "test/duplication_only_node_contract.rb",
    "Flay only missing repeated value" => "test/duplication_only_node_contract.rb",
    "Flay only check applicability" => "test/cli_contract.rb",
    "Flay liberal option recognition" => "test/duplication_contract.rb",
    "Flay liberal check applicability" => "test/cli_contract.rb",
    "Flay liberal combined routing" => "test/cli_contract.rb",
    "Flay fuzzy option recognition" => "test/duplication_fuzzy_contract.rb",
    "Flay fuzzy location attribution" => "test/duplication_fuzzy_contract.rb",
    "Flay fuzzy explicit distance parsing" => "test/duplication_fuzzy_distance_contract.rb",
    "Flay repeated mass precedence" => "test/duplication_control_interactions_contract.rb",
    "Flay fuzzy liberal source routing" => "test/duplication_control_interactions_contract.rb",
    "Flay legacy check applicability" => "test/legacy_parser_contract.rb",
    "Flay unreadable ignore file" => "test/flayignore_contract.rb",
    "Flay basename ignore matching" => "test/flayignore_contract.rb",
    "Flay path deduplication" => "test/flay_paths_contract.rb",
    "Flay lexical path normalization" => "test/flay_paths_contract.rb",
    "Flay empty path safety" => "test/flay_paths_contract.rb",
    "Reek config check applicability" => "test/cli_contract.rb",
    "Flay deep nested module candidate collection" => "test/duplication_contract.rb",
    "Flay group ordering" => "test/duplication_group_order_contract.rb",
    "Flay grouped file score" => "test/duplication_contract.rb",
    "Flay optional positional constant default identity" => "test/duplication_method_optional_positional_constant_contract.rb",
    "Flay dynamic duplication report buffer" => "test/duplication_method_candidate_capacity_contract.rb",
    "Flay cross-file location mapping" => "test/duplication_contract.rb",
    "Flay cross-file ordering" => "test/duplication_contract.rb",
    "combined failure precedence" => "test/combined_contract.rb",
    "Flay ignore scope" => "test/combined_contract.rb",
    "Spinel module finding traversal" => "test/language_extensions_contract.rb",
    "Spinel module finding location" => "test/language_extensions_contract.rb",
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
    "UnusedPrivateMethod inherited scope boundary" => "test/default_argument_api_contract.rb",
    "UnusedPrivateMethod method object boundary" => "test/default_argument_api_contract.rb",
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
    # The mutated file: bin/fleek.rb unless the configuration names another source.
    @target_path = configuration.path || "bin/fleek.rb"
  end

  def run
    return unless self.class::CONTRACTS.key?(@configuration.label)
    return unless selected_mutation?

    apply_mutation
    verify_mutation
  ensure
    File.write(@target_path, @source)
  end

  def apply_mutation
    mutated = @source.gsub(@configuration.target, @configuration.replacement)
    raise "#{@configuration.label} mutation target missing" if mutated == @source
    File.write(@target_path, mutated)
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
    label = @configuration.label
    contract = CONTRACTS.fetch(label)
    executable = compile_contract(contract)
    contract_directory = ENV["FLEEK_MUTATION_CONTRACT_DIRECTORY"]
    verify_shared_contract(executable, contract, contract_directory) if contract_directory
    Dir.mkdir("build/mutation-reference-cache") unless Dir.exist?("build/mutation-reference-cache")
    status = MutationProcess.run_contract(executable, label)
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
    source_paths = (contracts + dependency_paths + ["test/analysis_runner.rb", "test/flay_groups.rb", "test/reek_findings.rb"]).uniq
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
  def self.run_contract(executable, label)
    process_id = Process.spawn("env", "FLEEK_REFERENCE_CACHE=build/mutation-reference-cache", "FLEEK_MUTATION_LABEL=#{label}", executable,
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
  "return report_timeout_skip(arguments, timeout) if timeout && timeout < 0",
  "return run_without_unsupported_format(arguments) if timeout && timeout < 0",
  "Flay negative timeout incomplete outcome",
  "negative timeout was not reported as incomplete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return report_timeout_skip(arguments, timeout) if expired",
  "return report_timeout_skip(arguments, timeout) if timeout.positive?",
  "Flay timeout interrupts native worker",
  "Fleek --timeout 60 changed complete analysis")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "report.paths = report.paths - timeout_failures.map(&:path)",
  "report.paths = report.paths",
  "Flay per-file timeout retains completed source",
  "Fleek per-file timeout did not retain the completed source result")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'input != "--timeout" && input != "-#" && !input.start_with?("--fuzzy=")',
  'input != "--timeout" && !input.start_with?("--fuzzy=")',
  "Flay numbering no-op support",
  "Fleek numbering option changed normalized status")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (class_node->body == NULL) return true;",
  "if (class_node->body == NULL) return false;",
  "UnusedPrivateMethod empty framework subclass handling",
  "UnusedPrivateMethod status differs from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'configuration.detector_setting("DuplicateMethodCall", "allow_calls", path) || ""',
  '""',
  "ignored DuplicateMethodCall list entry",
  "DuplicateMethodCall findings differ from Reek")).run
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
  "state.count = 0;\n        state.unsupported = false;",
  "state.unsupported = false;",
  "RepeatedConditional class scope isolation",
  "per-class RepeatedConditional threshold was not clean and complete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'ignored = configuration.detector_setting("NestedIterators", "ignore_iterators", path) || "Tempfile.create\\ntap"',
  'ignored = ""',
  "ignored NestedIterators list entry",
  "ignored map did not produce a complete clean result")).run
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
  "if (!fleek_data_clump_method_has(state, candidate, clumps[clump_index][parameter])) shares_clump = false;",
  "if (false) shares_clump = false;",
  "DataClump singleton parameter participation",
  "DataClump findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "return state.unsupported ? (findings > 0 ? -5 : -4) : (int) findings;",
  "return state.unsupported ? -4 : (int) findings;",
  "DataClump drops findings on incomplete syntax",
  "DataClump findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "qualified_name, (size_t) qualified_length, statement, state);",
  "(const char *) nested_name->start, nested_name->length, statement, state);",
  "UncommunicativeMethodName nested singleton context",
  "nested singleton UncommunicativeMethodName context differs from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "(int) context_length, context, (int) name->length, name->start);",
  "(int) name->length, name->start, (int) name->length, name->start);",
  "UncommunicativeModuleName qualified context",
  "qualified UncommunicativeModuleName context differs from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (PM_NODE_TYPE_P(node, PM_BLOCK_PARAMETERS_NODE)) {",
  "if (false) {",
  "UncommunicativeVariableName block parameters",
  "UncommunicativeVariableName findings differ from Reek")).run
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
  "bool one_level_namespace = fleek_scope_contains(fleek_namespace_scope, fleek_only_scope) &&",
  "bool one_level_namespace = false &&",
  "ClassVariable namespace context traversal",
  "namespaced class status differs from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_module_has_direct_child(fleek_namespace_scope, fleek_only_scope) &&",
  "true &&",
  "ClassVariable wrapped namespace child acceptance",
  "unsupported ClassVariable namespace was not reported incomplete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "\"%.*s::%.*s\"",
  "\"%.*s/%.*s\"",
  "qualified ClassVariable namespace context",
  "namespaced class findings differ from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "bool nested_class_namespace = fleek_class_count == 1 && fleek_module_count == 2 &&",
  "bool nested_class_namespace = false &&",
  "ClassVariable nested namespace class support",
  "nested namespace ClassVariable status differs from Reek")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_module_has_direct_child(fleek_inner_namespace_scope, fleek_only_scope);",
  "true;",
  "ClassVariable nested namespace boundary",
  "unsupported ClassVariable namespace was not reported incomplete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (namespace_has_occurrences) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }",
  "if (false) { pm_node_destroy(&parser, root); pm_parser_free(&parser); pm_options_free(&options); return -4; }",
  "ClassVariable namespace occurrence handling",
  "unsupported ClassVariable namespace was not reported incomplete")).run
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
  "group_mass = node_mass * count;\n        multiplier = identical ? count : 1;",
  "group_mass = node_mass * count;\n        multiplier = 1;",
  "Flay identical multiplier",
  "top-level array-expression methods differed from Flay: missing node=\"defn\" kind=\"identical\" locations=\"test/fixtures/duplication_methods_array_expression.rb:1,test/fixtures/duplication_methods_array_expression.rb:5\" mass=38 score=76")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'puts "Total duplication score: #{score}"',
  'puts "Total duplication score: 0"',
  "Flay total score",
  "similar method group report differed")).run
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
  "static bool fleek_duplication_reserve_buffer(size_t required) {\n      if (required <= fleek_duplication_buffer_capacity) return true;",
  "static bool fleek_duplication_reserve_buffer(size_t required) {\n      if (required > 8192) return false;\n      if (required <= fleek_duplication_buffer_capacity) return true;",
  "Flay dynamic duplication report buffer",
  "2200 class methods were not analyzed")).run
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
  "combined failed source implied success")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'patterns.any? { |pattern| flay_ignore_match?(path, pattern) }',
  'false',
  "Flay ignore scope",
  "Flay ignore did not report excluded source")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'inputs = arguments.empty? ? [Dir.pwd] : arguments',
  'inputs = arguments',
  "implicit current directory",
  "complete default run with findings did not exit 2")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "RUNNABLE_DEFAULT_CHECKS = DEFAULT_CHECKS",
  "RUNNABLE_DEFAULT_CHECKS = []",
  "default runnable selection",
  "complete default run with findings did not exit 2")).run
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
  "inherited/dynamic private call graph was treated as complete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'fleek_class_count != 1 ||',
  'false ||',
  "UnusedPrivateMethod inherited scope boundary",
  "inherited/dynamic private call graph was treated as complete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'fleek_name_is(call_state->parser, call->name, "method")',
  'false',
  "UnusedPrivateMethod method object boundary",
  "inherited/dynamic private call graph was treated as complete")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'paths.any? { |path| effective_detector_enabled(name, best_scope(path)) }',
  'paths.any? { |_path| effective_detector_enabled(name, -1) }',
  "Reek directory detector precedence",
  "Fleek ignored the parent directory disablement")).run
MutationCase.new(MutationCase::Configuration.new(source,
  '["--mass", "--only", "--liberal", "--fuzzy", "--legacy", "--timeout", "-#"].include?(argument)',
  '["--only", "--liberal", "--fuzzy", "--legacy", "--timeout"].include?(argument)',
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
  '["--mass", "--only", "--liberal", "--fuzzy", "--legacy", "--timeout", "-#"].include?(argument)',
  '["--mass", "--liberal", "--fuzzy", "--legacy", "--timeout"].include?(argument)',
  "Flay only check applicability",
  "inapplicable Flay only was not rejected before Reek analysis")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'input != "--liberal"',
  'input != "--only"',
  "Flay liberal option recognition",
  "liberal pruning omitted retained method candidates")).run
MutationCase.new(MutationCase::Configuration.new(source,
  '["--mass", "--only", "--liberal", "--fuzzy", "--legacy", "--timeout", "-#"].include?(argument)',
  '["--mass", "--only", "--fuzzy", "--legacy", "--timeout"].include?(argument)',
  "Flay liberal check applicability",
  "inapplicable Flay liberal was not rejected before Reek analysis")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'reek_inputs = without_option(without_option_pairs(without_option(without_option_pairs(without_option_pairs(without_option(without_optional_integer_option(inputs, "--fuzzy"), "--liberal"), "--mass"), "--only"), "--legacy"), "--timeout"), "-#")',
  'reek_inputs = without_option_pairs(without_option_pairs(without_option_pairs(without_option(without_optional_integer_option(inputs, "--fuzzy"), "--mass"), "--only"), "--legacy"), "--timeout")',
  "Flay liberal combined routing",
  "combined Flay liberal status")).run
MutationCase.new(MutationCase::Configuration.new(source,
  'input != "--fuzzy"',
  'input != "--only"',
  "Flay fuzzy option recognition",
  "Flay fuzzy CLI outcome changed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "distance = candidate || 1",
  "distance = candidate || 0",
  "Flay fuzzy explicit distance parsing",
  "bare --fuzzy no longer defaults to distance one")).run
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
  '["--mass", "--only", "--liberal", "--fuzzy", "--legacy", "--timeout", "-#"].include?(argument)',
  '["--mass", "--only", "--liberal", "--fuzzy", "--timeout"].include?(argument)',
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
  "UncommunicativeVariableName findings differ from Reek")).run

MutationCase.new(MutationCase::Configuration.new(source,
  "uint32_t mass = 1;", "uint32_t mass = 0;",
  "Flay generic sexp mass", "generic engine differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "ok = fleek_flay_finish(&ctx, (uint32_t) translated) && fleek_flay_collect(&ctx, (uint32_t) translated",
  "ok = fleek_flay_finish(&ctx, (uint32_t) translated) && fleek_flay_list_push(&hashed, (uint32_t) translated) && fleek_flay_collect(&ctx, (uint32_t) translated",
  "Flay generic root exclusion", "generic engine differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (group_size[shape] < 2 || all_modified) removed[shape] = 1;", "if (all_modified) removed[shape] = 1;",
  "Flay generic singleton pruning", "generic engine differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "for (size_t shape = 0; shape < shape_count; shape++) if (marked[shape]) removed[shape] = 1;", "",
  "Flay generic conservative pruning", "generic engine differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!(sub != 0 && sub > top)) pruned[child] = 1;", "pruned[child] = 1;",
  "Flay generic liberal pruning", "generic engine differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (node->value != first->value) identical = false;", "",
  "Flay generic identity", "generic engine differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "(int) ctx->nodes[child].mass < mass_threshold) continue;", "(int) ctx->nodes[child].mass <= mass_threshold) continue;",
  "Flay generic mass threshold", "similar method group report differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "      if (body->size == 1) return fleek_flay_visit(ctx, body->nodes[0]);\n", "",
  "Flay generic statement block", "generic engine differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (!fleek_flay_is(ctx, visited, type)) {", "if (true) {",
  "Flay generic right-nested logical", "generic engine differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "          fleek_flay_add_visit(ctx, result, (const pm_node_t *) branch->else_clause);\n          return fleek_flay_add_visit(ctx, result, (const pm_node_t *) branch->statements);",
  "          fleek_flay_add_visit(ctx, result, (const pm_node_t *) branch->statements);\n          return fleek_flay_add_visit(ctx, result, (const pm_node_t *) branch->else_clause);",
  "Flay generic unless branches", "generic engine differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "ctx->in_def ? \"cvasgn\" : \"cvdecl\"", "\"cvasgn\"",
  "Flay generic class variable scope", "generic engine differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_flay_add_visit(ctx, result, ((const pm_assoc_node_t *) element)->value);", "",
  "Flay generic hash values", "generic engine differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (size > 10 || ctx->nodes[index].mass / size > 12) return true;", "return true;",
  "Flay generic fuzzy template bounds", "Flay fuzzy CLI")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "ctx->nodes[fuzzy].modified = true;", "ctx->nodes[fuzzy].modified = false;",
  "Flay generic fuzzy marking", "Flay fuzzy CLI")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "source_map.map { |entry| entry[0] }.join(\"\\n\")", "\"\"",
  "Flay generic source paths", "source file and line literals: analysis differed from Flay")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (legacy_state.unsupported) {", "if (false) {",
  "Flay generic legacy syntax", "Fleek legacy parser")).run


MutationCase.new(MutationCase::Configuration.new(source,
  "match_name ? fleek_flay_text_atom(ctx, 's', \"=~\") : fleek_flay_symbol(ctx, call->name)", "fleek_flay_text_atom(ctx, 's', \"call\")",
  "Flay generic call name identity", "Fleek call-differing_name kind differed")).run

MutationCase.new(MutationCase::Configuration.new(source,
  "if (!recorded) goto done;", "goto done;",
  "Flay per-file parse continuation", "unparseable source hid remaining Flay groups")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "apply_duplication_timeout_failures(report, failures) unless failures.empty?", "failures",
  "Flay parse failure attribution", "unparseable source hid remaining Flay groups")).run

MutationCase.new(MutationCase::Configuration.new(source,
  "        if (list->size == 1) { fleek_reek_visit(ast, list->nodes[0]); return; }\n", "",
  "Reek AST begin wrapping", "Reek AST differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "bool compose = standalone && segments > 1;", "bool compose = false;",
  "Reek AST string lines", "Reek AST differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "guard_type = if_guard ? \"if_guard\" : \"unless_guard\";", "guard_type = \"if_guard\";",
  "Reek AST pattern guards", "Reek AST differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "if (name->length == 2 && memcmp(name->start, \"=~\", 2) == 0 && call->receiver != NULL", "if (false && call->receiver != NULL",
  "Reek AST regexp match assignment", "Reek AST differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_reek_open(ast, \"forward_args\", parameters->keyword_rest);", "fleek_reek_open(ast, \"args\", parameters->keyword_rest);",
  "Reek AST legacy forward args", "Reek AST differed")).run
MutationCase.new(MutationCase::Configuration.new(source,
  "fleek_reek_body(ast, branch->else_clause == NULL ? NULL : (const pm_node_t *) branch->else_clause->statements);\n          fleek_reek_body(ast, (const pm_node_t *) branch->statements);",
  "fleek_reek_body(ast, (const pm_node_t *) branch->statements);\n          fleek_reek_body(ast, branch->else_clause == NULL ? NULL : (const pm_node_t *) branch->else_clause->statements);",
  "Reek AST unless branches", "Reek AST differed")).run

MutationCase.new(MutationCase::Configuration.new(source,
  "DEFAULT_DETECTOR_EXCLUDES = { \"TooManyStatements\" => [\"initialize\"] }.freeze", "DEFAULT_DETECTOR_EXCLUDES = {}.freeze",
  "Reek default initialize exclusion", "differed from Reek")).run

engine_source = File.read("bin/reek_engine.rb")
[
  ["sanitized.split(\" \").length >= 2", "sanitized.split(\" \").length >= 1", "Reek engine descriptive comment threshold"],
  ["!children.empty? && children.all? { |child| CONSTANT_TYPES.include?(child.type) }", "false", "Reek engine namespace modules"],
  ["directive_value(context, detector, \"enabled\") == \"false\"", "false", "Reek engine comment suppression"],
  ["      next unless found && found[1] == detector\n", "      next unless found && found[1] == detector && options.empty?\n", "Reek engine last directive wins"],
  ["      current = current.parent", "      current = nil", "Reek engine parent suppression"],
  ["(name == \"new\" && (simple == \"Class\" || simple == \"Struct\"))", "(name == \"new\" && simple == \"Class\")", "Reek engine Struct modules"],
  ["      return \"\" if context.kind == \"root\"", "", "Reek engine root naming"],
  ["when \"begin\", \"kwbegin\" then count_list(children.length - 1)", "when \"begin\", \"kwbegin\" then count_list(0)", "Reek engine begin statements"],
  ["when \"if\" then count_list(count_value(exp.child(1)) + count_value(exp.child(2)) - 1)", "when \"if\" then count_list(0)", "Reek engine if statements"],
  ["when \"block\" then count(exp.child(2))", "when \"block\" then count_list(0)", "Reek engine block statements"],
  ["inside(Context.new(@current.method_kind, exp, parent_exp), exp) { count(exp.child(2)) }", "inside(Context.new(@current.method_kind, exp, parent_exp), exp)", "Reek engine method body statements"],
  ["limit.negative? ? maximum : limit", "maximum", "Reek engine directive statement limit"],
  ["}\#{receiver_name(exp.child(0))}.\#{exp.child(1).symbol_name}\"", "}\#{exp.child(1).symbol_name}\"", "Reek engine singleton method names"],
  ["when \"resbody\" then count_list(", "when \"resbody\" then nil && count_list(", "Reek engine rescue statements"],
  ["when \"case\" then count_list(count_value(children.last) - 1)", "when \"case\" then count_list(0)", "Reek engine case statements"],
  ["when \"while\", \"until\" then count_list(count_value(exp.child(1)) - 1)", "when \"while\", \"until\" then count_list(0)", "Reek engine loop statements"],
  ["nested_depth = ignored_iterator?(iterator, source, ignored) ? depth : depth + 1", "nested_depth = depth + 1", "Reek engine ignored iterator depth"],
  [" || iterator.child(1).children.empty?", "", "Reek engine argumentless iterators"],
  [" + scout(iterator.child(0), depth, source, ignored)", "", "Reek engine iterators in calls"],
  ["violations.group_by { |pair| pair[1] }", "violations.group_by { |pair| 0 }", "Reek engine iterator depth groups"],
  ["ignored.any? { |pattern| call.match?(Regexp.new(pattern)) }", "false", "Reek engine ignored iterator patterns"],
  ["popular.include?(\"self\") ? [] : popular", "popular", "Reek engine self as most popular"],
  [" unless exp.child(1).value == \":new\"", "", "Reek engine object creation calls"],
  ["      when \"self\" then record(\"self\", exp.line)\n", "", "Reek engine self call references"],
  ["next if suppressed?(context, \"FeatureEnvy\") || !depends_on_instance?(context.exp)", "next if suppressed?(context, \"FeatureEnvy\")", "Reek engine envy without self"],
  ["      when \"op_asgn\"\n        @current.record_call_to(exp)\n", "      when \"op_asgn\"\n", "Reek engine operator assignment references"],
  ["next unless context.kind == \"method\" && context.visibility != \"module_function\"", "next unless context.kind == \"method\"", "Reek engine module function methods"],
  ["next if each_node(exp, [\"send\"], %w[class module]).empty?", "", "Reek engine methods without calls"],
  ["directive_value(context, \"UtilityFunction\", \"public_methods_only\") == \"true\"", "false", "Reek engine public methods only directive"],
  ["      if names.empty?\n", "      if true\n", "Reek engine named visibility"],
  ["      return \"singleton_method\" if @kind == \"ghost\"\n", "", "Reek engine ghost singleton methods"],
  ["refinement?(exp) ? inside(Context.new(\"refinement\", exp, nil), exp) : process(exp)", "process(exp)", "Reek engine refinement contexts"],
  ["own.empty? && method_context? ? comment_of(@parent_exp) : own", "own", "Reek engine parent expression comments"],
  ["SELF_TYPES = %w[self super zsuper ivar ivasgn send]", "SELF_TYPES = %w[self zsuper ivar ivasgn send]", "Reek engine super self references"],
  ["    return true if name == \":nil?\"\n", "", "Reek engine nil queries"],
  ["(name == \":==\" || name == \":===\")", "(name == \":==\")", "Reek engine case equality nil checks"],
  ["found.children[0, found.children.length - 1].any?", "found.children[0, 0].any?", "Reek engine when nil checks"],
  ["next if call.child(1).value == \":new\" || ", "next if ", "Reek engine duplicate object creation"],
  [" || (call.child(0).atom? && call.children.length == 2)", "", "Reek engine duplicate simple calls"],
  ["    each_node(exp, [\"block\"], %w[class module]).each { |block| record_call(groups, block) }\n", "", "Reek engine duplicate blocks"],
  ["each_node(exp, [\"send\"], %w[mlhs class module])", "each_node(exp, [\"send\"], %w[class module])", "Reek engine duplicate assignment targets"],
  ["limit = configured_limit(context, \"DuplicateMethodCall\", \"max_calls\", maximum)", "limit = maximum", "Reek engine duplicate call limit directive"],
  ["patterns.any? { |pattern| call.match?(Regexp.new(pattern)) }", "false", "Reek engine duplicate allowed calls"],
  ["    return true if call_in_condition?(node, parameter)\n", "", "Reek engine control calls in conditions"],
  ["COMPARISON_CALLS = %w[:== :!= :=~]", "COMPARISON_CALLS = %w[:!= :=~]", "Reek engine control comparisons"],
  ["    return true if body_nodes(node, [\"lvar\"], CONDITIONAL_TYPES).any? { |lvar| lvar.child(0).value == parameter }\n", "", "Reek engine control body uses"],
  ["      branch = node.child(1)\n", "      branch = node.child(0)\n", "Reek engine control logical bodies"],
  [".reject { |child| child.atom? || ignoring.include?(child.type) }", ".reject { |child| child.atom? }", "Reek engine control nested branches"],
  ["      next if !body.atom? && !each_node(body, [\"zsuper\"], []).empty?\n", "", "Reek engine unused implicit super"],
  ["name[1, name.length - 1].start_with?(\"_\") || ", "", "Reek engine unused underscore markers"],
  [" || used.include?(name)", "", "Reek engine unused parameter reads"],
  ["each_node(exp, %w[lvar lvasgn], %w[class module])", "each_node(exp, %w[lvar], %w[class module])", "Reek engine unused parameter assignments"],
  ["next if parameter.type == \"blockarg\" || ", "next if ", "Reek engine unused block arguments"],
  ["node.type == \"args\" || node.type == \"mlhs\"", "node.type == \"args\"", "Reek engine destructured parameters"],
  ["%w[true false].include?(parameter.child(1).type)", "%w[true].include?(parameter.child(1).type)", "Reek engine false boolean defaults"],
  ["OPTIONAL_ARGUMENTS = %w[optarg kwoptarg]", "OPTIONAL_ARGUMENTS = %w[optarg]", "Reek engine keyword boolean defaults"],
  ["parameters(context.exp).reject { |parameter| parameter.type == \"blockarg\" }.length", "parameters(context.exp).length", "Reek engine block arguments in parameter counts"],
  ["name.include?(\"initialize\") ? initialize_maximum : maximum", "maximum", "Reek engine initialize parameter override"],
  ["limit = configured_limit(context, \"LongParameterList\", \"max_params\", name.include?(\"initialize\") ? initialize_maximum : maximum)", "limit = name.include?(\"initialize\") ? initialize_maximum : maximum", "Reek engine parameter limit directive"],
  ["count > limit ? ", "count >= limit ? ", "Reek engine yield limit boundary"],
  [".reject { |node| defines_module?(node) }.length", ".length", "Reek engine module-defining constants"],
  ["each_node(exp, [\"ivasgn\"], %w[or_asgn class module])", "each_node(exp, [\"ivasgn\"], %w[class module])", "Reek engine instance variable or-assignments"],
  [".map { |node| node.child(0).value }.uniq.length", ".length", "Reek engine distinct instance variables"],
  ["else each_node(exp, [\"def\"], %w[class module]).length", "else each_node(exp, [\"def\"], %w[class module sclass]).length", "Reek engine singleton class method counts"],
  ["child.instance_method? && child.name == \":initialize\"", "child.name == \":initialize\"", "Reek engine module singleton initialize"],
  ["\"TooManyConstants\" => [%w[class module], \"max_constants\"]", "\"TooManyConstants\" => [[\"class\"], \"max_constants\"]", "Reek engine module constant counts"],
  [" && exp.type == \"sym\" && context.visibility == \"public\"", " && exp.type == \"sym\"", "Reek engine private attributes"],
  ["context.kind.end_with?(\"attribute\") && exp.type == \"sym\"", "context.kind.end_with?(\"attribute\")", "Reek engine string attribute names"],
  ["variable_names(method, \"ivar\", [\"or_asgn\"])", "variable_names(method, \"ivar\", [])", "Reek engine memoized instance variables"],
  ["(assumed - assigned).uniq", "assumed.uniq", "Reek engine initialized instance variables"],
  ["CORE_CLASSES = %w[Array Hash String]", "CORE_CLASSES = %w[Hash String]", "Reek engine Class.new core superclasses"],
  ["namespace.atom? ? simple : ", "simple || ", "Reek engine namespaced superclasses"],
  [" && !method_names.include?(name.chop)", "", "Reek engine safe method companions"],
  [" && !ignored.include?(name)", "", "Reek engine excluded bang methods"],
  ["call.child(1).value == \":respond_to?\"", "false", "Reek engine respond_to calls"],
].each do |target, replacement, label|
  MutationCase.new(MutationCase::Configuration.new(engine_source, target.to_s, replacement.to_s, label.to_s,
    "differed from Reek", "bin/reek_engine.rb")).run
end

process_id = Process.spawn("make", "build/fleek", out: MutationProcess.temporary_path("fleek-mutation-restore-out"), err: MutationProcess.temporary_path("fleek-mutation-restore-err"))
_, status = Process.waitpid2(process_id)
raise "mutation restore failed" unless status.success?
