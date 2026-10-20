# frozen_string_literal: true

require_relative "workspace_stager"

# Runs independent checks in disposable source copies; worker lifecycle stays together.
# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:FeatureEnvy
# :reek:InstanceVariableAssumption
# :reek:LongParameterList
# :reek:RepeatedConditional
# :reek:TooManyInstanceVariables
# :reek:TooManyMethods
# :reek:TooManyStatements
# :reek:UtilityFunction
class CheckRunner
  TESTS = %w[
    test/mutation_contract_cache_contract.rb
    test/check_runner_precompile_budget_contract.rb
    test/check_runner_staging_contract.rb
    test/check_runner_scheduler_contract.rb
    test/cli_contract.rb
    test/commit_identity_contract.rb
    test/text_report_contract.rb
    test/duplication_contract.rb
    test/duplication_group_order_contract.rb
    test/duplication_method_capacity_contract.rb
    test/duplication_method_block_contract.rb
    test/duplication_method_for_contract.rb
    test/duplication_method_parameter_contract.rb
    test/duplication_method_parameter_boundary_contract.rb
    test/duplication_method_self_contract.rb
    test/duplication_method_candidate_capacity_contract.rb
    test/duplication_only_node_contract.rb
    test/duplication_unsupported_sibling_contract.rb
    test/duplication_array_expression_contract.rb
    test/duplication_hash_expression_contract.rb
    test/combined_contract.rb
    test/language_extensions_contract.rb
    test/native_parser_contract.rb
    test/class_variable_contract.rb
    test/class_variable_scope_contract.rb
    test/analysis_runner.rb
    test/analysis_stdin_contract.rb
    test/analysis_inputs_contract.rb
    test/configuration_contract.rb
    test/runtime_evidence_contract.rb
    test/default_invocation_contract.rb
    test/default_configuration_contract.rb
    test/default_object_scope_contract.rb
    test/default_argument_api_contract.rb
  ].freeze
  REGRESSION_TESTS = %w[
    test/duplication_method_optional_positional_call_contract.rb
    test/duplication_method_optional_positional_call_argument_contract.rb
    test/duplication_method_optional_keyword_call_argument_contract.rb
    test/duplication_method_optional_positional_constant_contract.rb
    test/duplication_method_regexp_contract.rb
    test/duplication_method_block_parameter_contract.rb
    test/duplication_method_anonymous_parameter_contract.rb
    test/duplication_method_block_optional_parameter_contract.rb
    test/duplication_composed_parameter_block_contract.rb
    test/duplication_similar_composed_block_contract.rb
    test/duplication_composed_collection_contract.rb
    test/duplication_method_variable_rule_contract.rb
    test/duplication_method_scalar_value_contract.rb
    test/duplication_method_call_contract.rb
    test/duplication_method_collection_contract.rb
    test/duplication_method_branch_contract.rb
    test/duplication_method_loop_contract.rb
    test/duplication_method_exception_flow_contract.rb
    test/duplication_method_range_contract.rb
    test/duplication_method_range_regexp_boundary_contract.rb
    test/duplication_generated_descriptor_contract.rb
    test/duplication_method_optional_keyword_count_contract.rb
    test/ticket_documents_contract.rb
  ].freeze

  def initialize(mode)
    @mode = mode
    @spinel = ENV.fetch("SPINEL", "spinel")
    @spinel_root = ENV.fetch("SPINEL_ROOT", "")
    @jobs = worker_limit
    @mutation_jobs = mutation_worker_limit
    @mutation_contract_cache_root = File.expand_path("build/mutation-contract-cache")
    @failures = []
    @serial = 0
  end

  def run
    if @mode == "runner-probe"
      File.write("#{ENV.fetch('FLEEK_RUNNER_PROBE_ROOT')}/runner-pid", Process.pid.to_s)
    end
    tasks.each do |task|
      wait_for_capacity
      if task[0] == :mutation && !@mutation_contract_directory
        prepare_mutation_contracts
      end
      launch(task)
    end
    drain_workers
    report
  ensure
    @workers&.dup&.each { |worker| finish(worker) }
    cleanup_mutation_contracts
  end

  private

  def test_paths
    TESTS + REGRESSION_TESTS
  end

  def tasks
    mutations = Array.new(@mutation_jobs) { |shard| [:mutation, shard] }
    case @mode
    when "test" then test_paths.map { |path| [:spinel, path] }
    when "mutation" then mutations
    when "runner-probe"
      second = ENV["FLEEK_RUNNER_PROBE_FAILURE"] ? "fail" : "fast"
      [[:probe, "slow"], [:probe, second], [:probe, "third"]]
    when "check"
      test_paths.map { |path| [:spinel, path] } + mutations + [[:command, "reference"], [:command, "flay"], [:command, "reek"]]
    else raise "usage: check_runner.rb test|mutation|check"
    end
  end

  def worker_limit
    requested = ENV["JOBS"]
    return logical_cpus unless requested

    value = Integer(requested, 10)
    raise "JOBS must be a positive integer" unless value.positive?
    [value, logical_cpus].min
  rescue ArgumentError
    raise "JOBS must be a positive integer"
  end

  def mutation_worker_limit
    selected = ENV["FLEEK_MUTATIONS"]
    return @jobs unless selected && !selected.empty?

    [@jobs, selected.split(",").uniq.length].min
  end

  def logical_cpus
    output = "/tmp/fleek-check-cpus-#{Process.pid}"
    process_id = Process.spawn("getconf", "_NPROCESSORS_ONLN", out: output, err: "/dev/null")
    _, status = Process.waitpid2(process_id)
    count = status.success? ? Integer(File.read(output).strip, 10) : 1
    File.delete(output)
    [count, 1].max
  rescue ArgumentError
    1
  end

  def wait_for_capacity
    finish_next_worker while @workers && @workers.length >= @jobs
  end

  def drain_workers
    finish_next_worker until @workers.empty?
  end

  def finish_next_worker
    process_id, status = Process.waitpid2(-1)
    worker = @workers.find { |candidate| candidate[:id] == process_id }
    raise "completed check worker not found" unless worker

    finish(worker, status)
  end

  def launch(task)
    @workers ||= []
    @serial += 1
    directory = "/tmp/fleek-check-#{Process.pid}-#{@serial}"
    temporary_root = "/tmp/fleek-worker-#{Process.pid}-#{@serial}"
    worker = { id: nil, task: task, directory: directory, output: "/tmp/fleek-check-#{Process.pid}-#{@serial}.out",
      error: "/tmp/fleek-check-#{Process.pid}-#{@serial}.err", temporary_root: temporary_root }
    @workers << worker
    raise "could not create isolated check copy" unless WorkspaceStager.copy(".", directory)
    raise "check worker includes generated mutation artifacts" unless Dir.glob("#{directory}/build/mutation-*").empty?
    namespace_temporary_paths(directory, @serial) if task[0] == :spinel
    configure_mutation_shard(directory, task) if task[0] == :mutation
    temporary_process = Process.spawn("mkdir", "-p", temporary_root, out: "/dev/null", err: "/dev/null")
    _, temporary_status = Process.waitpid2(temporary_process)
    raise "could not create isolated check temp directory" unless temporary_status.success?
    worker[:id] = spawn_task(task, directory, worker[:output], worker[:error], temporary_root)
  rescue StandardError
    cleanup_worker(worker) if worker
    @workers.delete(worker) if worker
    raise
  end

  def configure_mutation_shard(directory, task)
    clear_mutation_reference_cache(directory)
    path = "#{directory}/test/mutation_contract.rb"
    source = File.read(path)
    source = source.gsub("MUTATION_SHARD = nil", "MUTATION_SHARD = #{task[1]}")
    source = source.gsub("MUTATION_SHARDS = nil", "MUTATION_SHARDS = #{@mutation_jobs}")
    File.write(path, source)
  end

  def clear_mutation_reference_cache(directory)
    path = "#{directory}/build/mutation-reference-cache"
    cleanup_paths([path], "copied mutation reference cache") if Dir.exist?(path)
  end

  def namespace_temporary_paths(directory, serial)
    Dir.glob("#{directory}/test/*.rb").each do |path|
      source = File.read(path)
      File.write(path, source.gsub("/tmp/", "/tmp/fleek-worker-#{Process.pid}-#{serial}-")) if source.include?("/tmp/")
    end
  end

  def prepare_mutation_contracts
    @mutation_contract_directory = "/tmp/fleek-mutation-contracts-#{Process.pid}"
    @mutation_precompile_root = "/tmp/fleek-mutation-precompile-#{Process.pid}"
    mkdir_process = Process.spawn("mkdir", "-p", @mutation_precompile_root, out: "/dev/null", err: "/dev/null")
    _, mkdir_status = Process.waitpid2(mkdir_process)
    raise "could not create mutation precompile temp directory" unless mkdir_status.success?
    output = "#{@mutation_precompile_root}/out"
    error = "#{@mutation_precompile_root}/err"
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    process_id = Process.spawn("env",
      "FLEEK_TEMP_ROOT=#{@mutation_precompile_root}",
      "FLEEK_MUTATION_CONTRACT_DIRECTORY=#{@mutation_contract_directory}",
      "FLEEK_MUTATION_CONTRACT_CACHE_ROOT=#{@mutation_contract_cache_root}",
      "FLEEK_PRECOMPILE_MUTATION_CONTRACTS=1",
      "FLEEK_PRECOMPILE_BUDGET_REPORT=#{ENV['FLEEK_PRECOMPILE_BUDGET_REPORT'] || 'false'}",
      "JOBS=#{@jobs}",
      "SPINEL=#{@spinel}", "SPINEL_ROOT=#{@spinel_root}",
      @spinel, "-E", "test/mutation_contract.rb", out: output, err: error)
    _, status = Process.waitpid2(process_id)
    child_error = File.exist?(error) ? File.read(error) : ""
    print File.read(output) if File.exist?(output)
    warn child_error unless child_error.empty?
    File.delete(output) if File.exist?(output)
    File.delete(error) if File.exist?(error)
    if ENV["FLEEK_PRECOMPILE_BUDGET_REPORT"] == "true"
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      puts "Mutation precompile elapsed: #{elapsed}s"
    end
    unless status.success?
      raise "could not precompile shared mutation contracts (status=#{status.exitstatus}): #{child_error}"
    end
  end

  def spawn_task(task, directory, output, error, temporary_root)
    kind, value = task
    case kind
    when :spinel
      Process.spawn("env", "FLEEK_TEMP_ROOT=#{temporary_root}", "SPINEL=#{@spinel}", "SPINEL_ROOT=#{@spinel_root}", @spinel, "-E", value,
        chdir: directory, out: output, err: error)
    when :mutation
      Process.spawn("env", "FLEEK_TEMP_ROOT=#{temporary_root}", "FLEEK_MUTATION_CONTRACT_DIRECTORY=#{@mutation_contract_directory}",
        "FLEEK_MUTATION_CONTRACT_CACHE_ROOT=#{@mutation_contract_cache_root}",
        "FLEEK_EXPECTED_WORKING_DIRECTORY=#{directory}",
        "FLEEK_EXPECTED_TEMP_ROOT=#{temporary_root}",
        "SPINEL=#{@spinel}", "SPINEL_ROOT=#{@spinel_root}", @spinel, "-E", "test/mutation_contract.rb",
        chdir: directory, out: output, err: error)
    when :probe
      Process.spawn("env", "SPINEL=#{@spinel}", "FLEEK_RUNNER_PROBE_ROOT=#{ENV.fetch('FLEEK_RUNNER_PROBE_ROOT')}",
        "FLEEK_RUNNER_PROBE_TASK=#{value}", "FLEEK_PROBE_GATE_SPINEL=#{@spinel}",
        "FLEEK_PROBE_GATE_ROOT=#{ENV.fetch('FLEEK_RUNNER_PROBE_ROOT')}", "FLEEK_PROBE_GATE_MARKER=release-slow",
        @spinel, "-E", "test/check_runner_probe_child.rb",
        chdir: directory, out: output, err: error)
    when :command then spawn_check(value, directory, output, error)
    end
  end

  def spawn_check(name, directory, output, error)
    case name
    when "reference" then Process.spawn("make", "reference", chdir: directory, out: output, err: error)
    when "flay" then Process.spawn("make", "flay", chdir: directory, out: output, err: error)
    when "reek" then Process.spawn("make", "reek", chdir: directory, out: output, err: error)
    end
  end

  def finish(worker, status = nil)
    return unless worker

    _, status = Process.waitpid2(worker.fetch(:id)) unless status
    result = [worker[:task], status.success?, File.read(worker[:output]), File.read(worker[:error])]
    @failures << result unless result[1]
    puts "Check #{task_name(worker[:task])}: #{result[1] ? 'pass' : 'FAIL'}"
    print result[2] unless result[2].empty?
    warn result[3] unless result[3].empty?
    cleanup_worker(worker)
    @workers.delete(worker)
  end

  def cleanup_worker(worker)
    cleanup_paths([worker[:output], worker[:error], worker[:directory], worker[:temporary_root]], "check worker")
  end

  def cleanup_paths(paths, description)
    paths.compact.each do |path|
      process_id = Process.spawn("rm", "-rf", path, out: "/dev/null", err: "/dev/null")
      _, status = Process.waitpid2(process_id)
      raise "could not clean #{description} path: #{path}" unless status.success?
    end
  end

  def cleanup_mutation_contracts
    return unless @mutation_contract_directory || @mutation_precompile_root

    cleanup_paths([@mutation_contract_directory, @mutation_precompile_root], "mutation contract")
  end

  def task_name(task)
    task.map(&:to_s).join(" ")
  end

  def report
    raise "#{@failures.length} check worker(s) failed" unless @failures.empty?
    puts "Check runner: #{@serial} workers passed with JOBS=#{@jobs}; mutation workers=#{@mutation_jobs}"
  end
end

CheckRunner.new(ARGV.fetch(0, "")).run
