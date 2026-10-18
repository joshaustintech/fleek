temporary_root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
cases = {
  "identical" => ["Namespace::Converter.new(value)", "Namespace::Converter.new(value)"],
  "different_name" => ["Namespace::Converter.new(value)", "Namespace::Encoder.new(value)"]
}
cases.each do |name, expressions|
  path = "#{temporary_root}/fleek-method-constant-path-#{name}.rb"
  source = "def transform(value)\n  #{expressions[0]}\nend\n\ndef transform(value)\n  #{expressions[1]}\nend\n"
  File.write(path, source)
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
  raise "Flay #{name} constant-path reference failed: #{reference_output} #{reference_error}" unless reference_status.success?
  expected_group = !!reference_output.lines.find { |line| line.include?("code found in :defn") }
  expected_status = expected_group ? 2 : 0
  raise "#{name} constant-path methods were not analyzed: #{actual_output} #{actual_error}" unless actual_status.exitstatus == expected_status
  native_group = actual_output.lines.find { |line| line.include?('node="defn"') }
  reference_group = reference_output.lines.find { |line| line.include?("code found in :defn") }
  raise "Flay #{name} constant-path grouping changed: #{reference_output}" unless !!reference_group == expected_group
  if expected_group
    raise "Fleek did not group #{name} constant-path methods: #{actual_output}" unless native_group
    flay_reported_mass = reference_group[/mass(?:\*2)? = (\d+)/, 1].to_i
    flay_mass = reference_group.include?("mass*2") ? flay_reported_mass / 2 : flay_reported_mass
    native_mass = native_group[/ mass=(\d+)/, 1].to_i
    raise "#{name} constant-path mass differed: #{reference_group} / #{native_group}" unless native_mass == flay_mass
    expected_kind = reference_group.include?("IDENTICAL code") ? "identical" : "similar"
    raise "#{name} constant-path kind differed: #{native_group}" unless native_group.include?("kind=\"#{expected_kind}\"")
    actual_locations = native_group[/locations=\"([^\"]+)\"/, 1]
    expected_locations = ["#{path}:1", "#{path}:5"].join(",")
    raise "#{name} constant-path locations differed: #{native_group}" unless actual_locations == expected_locations
  else
    raise "Fleek grouped different constant paths: #{actual_output}" if native_group
  end
  raise "#{name} constant-path coverage was incomplete: #{actual_output}" unless actual_output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
  File.delete(path)
  File.delete(actual_output_path)
  File.delete(actual_error_path)
  File.delete(reference_output_path)
  File.delete(reference_error_path)
end
puts "Method constant-path contract: pass"
