require_relative "duplication_method_pair_contract"

cases = {
  integer: ["1", "2"], float: ["1.0", "2.0"],
  string: ['"one"', '"two"'], symbol: [":one", ":two"],
  boolean: ["true", "false"], boolean_same: ["true", "true"],
  nil: ["nil", "false"], nil_same: ["nil", "nil"],
  constant_read: ["FirstValue", "SecondValue"], constant_read_same: ["FirstValue", "FirstValue"],
  constant_path: ["Namespace::FirstValue", "Namespace::SecondValue"],
  constant_path_parent: ["First::Value", "Second::Value"],
  interpolated_regexp: ['/pre#{value}post/ =~ value', '/new#{value}post/ =~ value'],
  block_parameter_default: ["[].map { |entry = 1| entry }", "[].map { |entry = 2| entry }"]
}
cases.each do |name, values|
  parameters = name == :interpolated_regexp ? "(value)" : ""
  input = DuplicationMethodPairContract::Input.new("scalar-#{name}", values[0], values[1], parameters)
  DuplicationMethodPairContract.verify(input)
end
puts "Method scalar-value contract: pass"
