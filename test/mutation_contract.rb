# Proves the CLI contract rejects a false successful usage status.
source_path = "bin/fleek.rb"
original_source = File.read(source_path)
mutation_target = "    1\n  end\n\n  def self.run(arguments)"
mutated_source = original_source.gsub(mutation_target, "    0\n  end\n\n  def self.run(arguments)")
raise "mutation target missing" if mutated_source == original_source

File.write(source_path, mutated_source)
begin
  process_id = Process.spawn("make", "test", out: "/tmp/fleek-mutation-out", err: "/tmp/fleek-mutation-err")
  _, process_status = Process.waitpid2(process_id)
  raise "CLI contract survived wrong usage status" if process_status.success?
  raise "unexpected mutation failure" unless File.read("/tmp/fleek-mutation-err").include?("empty invocation status")
ensure
  File.write(source_path, original_source)
end

puts "Mutation contract: caught wrong usage status"
