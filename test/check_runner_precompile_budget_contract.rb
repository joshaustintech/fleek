# frozen_string_literal: true
# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:IrresponsibleModule
# :reek:LongParameterList
# :reek:RepeatedConditional
# :reek:TooManyStatements

class CheckRunnerPrecompileBudgetContract
  LABELS = ["Flay method call splat candidates", "Flay generated descriptor support", "Flay method array expression",
    "Flay method while loop candidates", "Flay method for loop candidates", "Flay required keyword parameter candidates",
    "Flay next expression candidates", "Flay regular expression candidates", "Flay method range candidates",
    "Flay class method candidate collection"].join(",").freeze

  def self.run
    fake_compiler = compile_fake_compiler
    cpu_count = available_cpus
    verify_scenario(fake_compiler, "default", cpu_count, cpu_count)
    verify_scenario(fake_compiler, "single", 1, cpu_count)
    verify_scenario(fake_compiler, "explicit", 3, cpu_count)
    verify_scenario(fake_compiler, "over-cpu-resolved", cpu_count, cpu_count)
    puts "Check runner precompile budget contract: pass"
  end

  def self.compile_fake_compiler
    executable = "#{ENV.fetch('FLEEK_TEMP_ROOT')}/check-runner-fake-spinel"
    process_id = Process.spawn(ENV.fetch("SPINEL"), "-O", "1", "test/check_runner_fake_compiler.rb", "-o", executable,
      out: "/dev/null", err: "/dev/null")
    _, status = Process.waitpid2(process_id)
    expect(status.success?, "fake compiler did not compile")
    executable
  end

  def self.verify_scenario(fake_compiler, name, jobs, cpu_count)
    root = "#{ENV.fetch('FLEEK_TEMP_ROOT')}/precompile-budget-#{Process.pid}-#{name}"
    Dir.mkdir(root)
    output = "#{root}/runner.out"
    error = "#{root}/runner.err"
    process_id = launch_precompiler(fake_compiler, root, output, error, jobs)
    first_batch = wait_for_started(root, [jobs, LABELS.split(",").length].min)
    File.write("#{root}/release", "release")
    _, status = Process.waitpid2(process_id)
    verify_results(root, output, error, status, jobs, cpu_count, first_batch)
  ensure
    File.write("#{root}/release", "release") if root && Dir.exist?(root)
  end

  def self.launch_precompiler(fake_compiler, root, output, error, jobs)
    directory = "#{root}/contracts"
    temporary_root = "#{root}/temporary"
    Dir.mkdir(temporary_root)
    Process.spawn("env", "JOBS=#{jobs}", "SPINEL=#{fake_compiler}", "SPINEL_ROOT=#{ENV.fetch('SPINEL_ROOT')}",
      "FLEEK_PRECOMPILE_PROBE_ROOT=#{root}", "FLEEK_PRECOMPILE_MUTATION_CONTRACTS=1",
      "FLEEK_PRECOMPILE_BUDGET_REPORT=true", "FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true",
      "FLEEK_MUTATION_CONTRACT_DIRECTORY=#{directory}",
      "FLEEK_TEMP_ROOT=#{temporary_root}", "FLEEK_MUTATIONS=#{LABELS}",
      "FLEEK_PROBE_GATE_SPINEL=#{ENV.fetch('SPINEL')}", "FLEEK_PROBE_GATE_ROOT=#{root}",
      "FLEEK_PROBE_GATE_MARKER=release", ENV.fetch("SPINEL"), "-E",
      "test/mutation_contract.rb", out: output, err: error)
  end

  def self.wait_for_started(root, expected_count)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 15
    until Dir.glob("#{root}/started-*").length >= expected_count
      return Dir.glob("#{root}/started-*").length if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
    end
    Dir.glob("#{root}/started-*").length
  end

  def self.verify_results(root, output, error, status, jobs, cpu_count, first_batch)
    stdout = File.read(output)
    stderr = File.read(error)
    expected_batch = [jobs, LABELS.split(",").length].min
    expect(status.success?, "precompile probe failed: #{stderr}")
    expect(stdout.include?("Mutation precompile budget: JOBS=#{jobs}; max batch=#{expected_batch}"),
      "precompile budget did not match resolved runner budget")
    expect(first_batch == expected_batch, "compiler fan-out was #{first_batch}, expected #{expected_batch}")
    started = Dir.glob("#{root}/started-*")
    finished = Dir.glob("#{root}/finished-*")
    expect(started.length == LABELS.split(",").length, "focused selection compiled unexpected contract count")
    expect(finished.length == started.length, "precompile left compiler processes running")
    temporary_roots = started.map { |path| File.read(path) }
    expect(temporary_roots.uniq.length == started.length, "compiler temp roots were shared")
    flags = started.map { |path| File.read("#{root}/flags-#{path.split('-').last}") }
    expect(flags.all? { |value| value == "-O 1" }, "contract compiler optimization changed")
    expect(stdout.include?("duplication_method_pair_contract.rb"), "selected dependency was not prepared")
    expect(!stdout.include?("test/duplication_contract.rb"), "unselected contract entered prepared bundle")
    expect(jobs <= cpu_count, "test requested an invalid resolved budget")
  end

  def self.available_cpus
    path = "#{ENV.fetch('FLEEK_TEMP_ROOT')}/cpu-count"
    process_id = Process.spawn("getconf", "_NPROCESSORS_ONLN", out: path, err: "/dev/null")
    _, status = Process.waitpid2(process_id)
    expect(status.success?, "could not determine CPU count")
    Integer(File.read(path).strip, 10)
  end

  def self.expect(condition, message)
    raise message unless condition
  end
end

CheckRunnerPrecompileBudgetContract.run
