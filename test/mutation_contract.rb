# Proves public checks reject two deliberately broken parser/CLI behaviors.
class MutationCase
  # Carries one behavior mutation and its expected contract failure.
  Configuration = Struct.new(:source, :target, :replacement, :label, :expected_failure)

  def initialize(configuration)
    @configuration = configuration
  end

  def run
    source = @configuration.source
    mutated = source.gsub(@configuration.target, @configuration.replacement)
    raise "#{@configuration.label} mutation target missing" if mutated == source

    File.write("bin/fleek.rb", mutated)
    verify_mutation
  ensure
    File.write("bin/fleek.rb", source)
  end

  def verify_mutation
    process_id = Process.spawn("make", "-B", "test", out: "/tmp/fleek-mutation-out", err: "/tmp/fleek-mutation-err")
    _, status = Process.waitpid2(process_id)
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

source = File.read("bin/fleek.rb")
MutationCase.new(MutationCase::Configuration.new(source,
  "    warn \"Usage: fleek [--help | --version]\"\n    1\n  end",
  "    warn \"Usage: fleek [--help | --version]\"\n    0\n  end",
  "wrong usage status",
  "empty invocation status")).run
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

process_id = Process.spawn("make", "-B", "test", out: "/tmp/fleek-mutation-restore-out", err: "/tmp/fleek-mutation-restore-err")
_, status = Process.waitpid2(process_id)
raise "mutation restore failed" unless status.success?
