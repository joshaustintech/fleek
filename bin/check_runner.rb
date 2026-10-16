# frozen_string_literal: true

# Runs independent checks in disposable source copies; worker lifecycle stays together.
# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:FeatureEnvy
# :reek:InstanceVariableAssumption
# :reek:LongParameterList
# :reek:TooManyInstanceVariables
# :reek:TooManyStatements
# :reek:UtilityFunction
class CheckRunner
  TESTS = %w[
    test/cli_contract.rb
    test/commit_identity_contract.rb
    test/text_report_contract.rb
    test/duplication_contract.rb
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
  ].freeze

  def initialize(mode)
    @mode = mode
    @spinel = ENV.fetch("SPINEL", "spinel")
    @spinel_root = ENV.fetch("SPINEL_ROOT", "")
    @jobs = worker_limit
    @failures = []
    @serial = 0
  end

  def run
    tasks.each do |task|
      wait_for_capacity
      launch(task)
    end
    until @workers.empty?
      finish(@workers.first)
    end
    report
  ensure
    @workers&.dup&.each { |worker| finish(worker) }
  end

  private

  def tasks
    mutations = Array.new(@jobs) { |shard| [:mutation, shard] }
    case @mode
    when "test" then TESTS.map { |path| [:spinel, path] }
    when "mutation" then mutations
    when "check"
      TESTS.map { |path| [:spinel, path] } + mutations + [[:command, "reference"], [:command, "flay"], [:command, "reek"]]
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
    finish(@workers.first) while @workers && @workers.length >= @jobs
  end

  def launch(task)
    @workers ||= []
    @serial += 1
    directory = "/tmp/fleek-check-#{Process.pid}-#{@serial}"
    copy_process = Process.spawn("cp", "-R", ".", directory, out: "/dev/null", err: "/dev/null")
    _, copy_status = Process.waitpid2(copy_process)
    raise "could not create isolated check copy" unless copy_status.success?
    configure_mutation_shard(directory, task) if task[0] == :mutation
    namespace_temporary_paths(directory, @serial)
    output = "/tmp/fleek-check-#{Process.pid}-#{@serial}.out"
    error = "/tmp/fleek-check-#{Process.pid}-#{@serial}.err"
    process_id = spawn_task(task, directory, output, error)
    @workers << { id: process_id, task: task, directory: directory, output: output, error: error }
  end

  def configure_mutation_shard(directory, task)
    path = "#{directory}/test/mutation_contract.rb"
    source = File.read(path)
    source = source.gsub("MUTATION_SHARD = nil", "MUTATION_SHARD = #{task[1]}")
    source = source.gsub("MUTATION_SHARDS = nil", "MUTATION_SHARDS = #{@jobs}")
    File.write(path, source)
  end

  def namespace_temporary_paths(directory, serial)
    Dir.glob("#{directory}/test/*.rb").each do |path|
      source = File.read(path)
      File.write(path, source.gsub("/tmp/", "/tmp/fleek-worker-#{Process.pid}-#{serial}-")) if source.include?("/tmp/")
    end
  end

  def spawn_task(task, directory, output, error)
    kind, value = task
    case kind
    when :spinel
      Process.spawn("env", "SPINEL=#{@spinel}", "SPINEL_ROOT=#{@spinel_root}", @spinel, "-E", value,
        chdir: directory, out: output, err: error)
    when :mutation
      Process.spawn("env", "SPINEL=#{@spinel}", "SPINEL_ROOT=#{@spinel_root}", @spinel, "-E", "test/mutation_contract.rb",
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

  def finish(worker)
    return unless worker

    _, status = Process.waitpid2(worker.fetch(:id))
    result = [worker[:task], status.success?, File.read(worker[:output]), File.read(worker[:error])]
    @failures << result unless result[1]
    puts "Check #{task_name(worker[:task])}: #{result[1] ? 'pass' : 'FAIL'}"
    print result[2] unless result[2].empty?
    warn result[3] unless result[3].empty?
    File.delete(worker[:output]) if File.exist?(worker[:output])
    File.delete(worker[:error]) if File.exist?(worker[:error])
    cleanup_process = Process.spawn("rm", "-rf", worker[:directory], out: "/dev/null", err: "/dev/null")
    Process.waitpid2(cleanup_process)
    @workers.delete(worker)
  end

  def task_name(task)
    task.map(&:to_s).join(" ")
  end

  def report
    raise "#{@failures.length} check worker(s) failed" unless @failures.empty?
    puts "Check runner: #{@serial} workers passed with JOBS=#{@jobs}"
  end
end

CheckRunner.new(ARGV.fetch(0, "")).run
