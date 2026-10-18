candidate_count = 2200
temporary_root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
path = "#{temporary_root}/fleek-generated-class-method-count-#{candidate_count}.rb"
methods = candidate_count.times.map do |index|
  "  def transform_#{index}(value)\n    convert(value)\n  end\n"
end
File.write(path, "class Batch\n#{methods.join}end\n")
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
raise "Flay did not report #{candidate_count} method candidates: #{reference_output} #{reference_error}" unless reference_status.success?
raise "#{candidate_count} class methods were not analyzed: #{actual_output} #{actual_error}" unless actual_status.exitstatus == 2
raise "Flay method group changed: #{reference_output}" unless reference_output.include?("code found in :defn")
raise "#{candidate_count} class methods were not grouped: #{actual_output}" unless actual_output.include?("node=\"defn\" kind=\"similar\"")
raise "#{candidate_count} class methods were marked incomplete: #{actual_output}" unless actual_output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
expected_lines = candidate_count.times.map { |index| "#{path}:#{2 + 3 * index}" }
expected_locations = "locations=\"#{expected_lines.join(',')}\""
raise "#{candidate_count} class method locations were incomplete: #{actual_output}" unless actual_output.include?(expected_locations)
native_group = actual_output.lines.find { |line| line.include?("node=\"defn\"") }
flay_mass = reference_output[/code found in :defn \(mass = (\d+)\)/, 1]
native_mass = native_group[/ mass=(\d+)/, 1]
raise "#{candidate_count} class method mass differed: #{reference_output} / #{native_group}" unless flay_mass == native_mass
raise "#{candidate_count} class method score differed: #{native_group}" unless native_group.include?("score=#{flay_mass}")
puts "Method candidate count contract: pass"
File.delete(path)
File.delete(actual_output_path)
File.delete(actual_error_path)
File.delete(reference_output_path)
File.delete(reference_error_path)
