temporary_root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
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
  path = "#{temporary_root}/fleek-method-scalar-#{name}.rb"
  parameters = name == :interpolated_regexp ? "(value)" : ""
  File.write(path, "def transform#{parameters}\n  #{values[0]}\nend\n\ndef transform#{parameters}\n  #{values[1]}\nend\n")
  actual_output_path = "#{path}.actual.out"
  actual_error_path = "#{path}.actual.err"
  reference_output_path = "#{path}.reference.out"
  reference_error_path = "#{path}.reference.err"
  actual_process = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", "3", path,
    out: actual_output_path, err: actual_error_path)
  _, actual_status = Process.waitpid2(actual_process)
  actual_output = File.read(actual_output_path)
  actual_error = File.read(actual_error_path)
  reference_process = Process.spawn("bundle", "exec", "flay", "--mass", "3", path,
    out: reference_output_path, err: reference_error_path)
  _, reference_status = Process.waitpid2(reference_process)
  reference_output = File.read(reference_output_path)
  reference_error = File.read(reference_error_path)
  raise "Flay #{name} reference failed: #{reference_output} #{reference_error}" unless reference_status.success?
  reference_group = reference_output.lines.find { |line| line.include?("code found in :defn") }
  expected_status = reference_group ? 2 : 0
  raise "Fleek #{name} status differed: #{actual_output} #{actual_error}" unless actual_status.exitstatus == expected_status
  native_group = actual_output.lines.find { |line| line.include?('node="defn"') }
  raise "Fleek #{name} grouping differed from Flay: #{actual_output} / #{reference_output}" unless !!native_group == !!reference_group
  reference_total = reference_output[/Total score \(lower is better\) = (\d+)/, 1].to_i
  native_total = actual_output[/Total duplication score: (\d+)/, 1].to_i
  if reference_group
    expected_kind = reference_group.include?("IDENTICAL code") ? "identical" : "similar"
    raise "Fleek #{name} kind differed: #{native_group}" unless native_group.include?("kind=\"#{expected_kind}\"")
    reference_mass = reference_group[/mass(?:\*2)? = (\d+)/, 1].to_i
    reference_mass /= 2 if reference_group.include?("mass*2")
    native_mass = native_group[/ mass=(\d+)/, 1].to_i
    raise "Fleek #{name} mass differed: #{native_group} / #{reference_group}" unless native_mass == reference_mass
    native_score = native_group[/ score=(\d+)/, 1].to_i
    raise "Fleek #{name} group score differed: #{native_group} / #{reference_group}" unless native_score == reference_total
    expected_locations = ["#{path}:1", "#{path}:5"].join(",")
    raise "Fleek #{name} locations differed: #{native_group}" unless native_group.include?("locations=\"#{expected_locations}\"")
    raise "Fleek #{name} location order differed: #{native_group}" unless native_group.index("#{path}:1") < native_group.index("#{path}:5")
  end
  raise "Fleek #{name} total score differed: #{actual_output} / #{reference_output}" unless native_total == reference_total
  raise "Fleek #{name} coverage incomplete: #{actual_output}" unless actual_output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
  [path, actual_output_path, actual_error_path, reference_output_path, reference_error_path].each { |file| File.delete(file) }
end
puts "Method scalar-value contract: pass"
