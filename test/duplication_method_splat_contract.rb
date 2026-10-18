temporary_root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
path = "#{temporary_root}/fleek-method-splat-arguments.rb"
source = "def first(items)\n  normalize(*items)\nend\n\ndef second(values)\n  normalize(*values)\nend\n"
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
raise "Flay splat-argument reference failed: #{reference_output} #{reference_error}" unless reference_status.success?
reference_group = reference_output.lines.find { |line| line.include?("code found in :defn") }
raise "Flay did not group splat-argument methods: #{reference_output}" unless reference_group
raise "splat-argument methods were not analyzed: #{actual_output} #{actual_error}" unless actual_status.exitstatus == 2
native_group = actual_output.lines.find { |line| line.include?('node="defn"') }
raise "Fleek did not group splat-argument methods: #{actual_output}" unless native_group
reference_mass = reference_group[/mass = (\d+)/, 1].to_i
native_mass = native_group[/ mass=(\d+)/, 1].to_i
raise "splat-argument mass differed from Flay: #{reference_group} / #{native_group}" unless native_mass == reference_mass
expected_kind = reference_group.include?("IDENTICAL code") ? "identical" : "similar"
raise "splat-argument kind differed from Flay: #{native_group}" unless native_group.include?("kind=\"#{expected_kind}\"")
actual_locations = native_group[/locations=\"([^\"]+)\"/, 1]
expected_locations = ["#{path}:1", "#{path}:5"].join(",")
raise "splat-argument locations differed from Flay: #{native_group}" unless actual_locations == expected_locations
raise "splat-argument coverage was incomplete: #{actual_output}" unless actual_output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
puts "Method splat-argument contract: pass"
File.delete(path)
File.delete(actual_output_path)
File.delete(actual_error_path)
File.delete(reference_output_path)
File.delete(reference_error_path)
