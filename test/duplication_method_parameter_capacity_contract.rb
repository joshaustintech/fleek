parameter_count = 40
temporary_root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
path = "#{temporary_root}/fleek-generated-method-parameter-count-#{parameter_count}.rb"
first_parameters = parameter_count.times.map { |index| "first_#{index}" }
second_parameters = parameter_count.times.map { |index| "second_#{index}" }
source = "def transform(#{first_parameters.join(', ')})\n  convert(first_0)\nend\n\n" +
  "def transform(value, #{second_parameters.drop(1).join(', ')})\n  convert(value)\nend\n"
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
raise "Flay did not report #{parameter_count} parameters: #{reference_output} #{reference_error}" unless reference_status.success?
raise "#{parameter_count}-parameter methods were not analyzed: #{actual_output} #{actual_error}" unless actual_status.exitstatus == 2
raise "Flay parameter group changed: #{reference_output}" unless reference_output.include?("code found in :defn")
raise "#{parameter_count}-parameter methods were not grouped: #{actual_output}" unless actual_output.include?('kind="similar"')
raise "#{parameter_count}-parameter methods were incomplete: #{actual_output}" unless actual_output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
native_group = actual_output.lines.find { |line| line.include?('node="defn"') }
flay_mass = reference_output[/code found in :defn \(mass = (\d+)\)/, 1]
native_mass = native_group[/ mass=(\d+)/, 1]
raise "#{parameter_count}-parameter method mass differed: #{reference_output} / #{native_group}" unless flay_mass == native_mass
raise "#{parameter_count}-parameter method score differed: #{native_group}" unless native_group.include?("score=#{flay_mass}")
raise "#{parameter_count}-parameter method locations differed: #{native_group}" unless native_group.include?("locations=\"#{path}:1,#{path}:5\"")
puts "Method parameter capacity contract: pass"
File.delete(path)
File.delete(actual_output_path)
File.delete(actual_error_path)
File.delete(reference_output_path)
File.delete(reference_error_path)
