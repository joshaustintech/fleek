require_relative "duplication_method_pair_contract"
require_relative "analysis_runner"

cases = {
  same_call: ["process(1)", "process(1)"],
  differing_argument: ["process(1)", "process(2)"],
  differing_name: ["process(1)", "render(1)"],
  same_receiver: ["client.process(1)", "client.process(1)"],
  differing_receiver: ["client.process(1)", "server.process(1)"],
  same_splat: ["process(*values)", "process(*values)"],
  differing_splat: ["process(*values)", "process(*other_values)"],
  same_block: ["process { value }", "process { value }"],
  differing_block: ["process { value }", "process { other_value }"]
}
cases.each do |name, calls|
  input = DuplicationMethodPairContract::Input.new("call-#{name}", calls[0], calls[1], "")
  DuplicationMethodPairContract.verify(input)
end

FlayMethodCandidateContract.verify_unsupported("test/fixtures/duplication_methods_call_forwarding.rb", "forwarding-call", 20)
puts "Method call contract: pass"
