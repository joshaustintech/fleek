levels = 300
temporary_root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
path = "#{temporary_root}/fleek-generated-method-expression-depth-#{levels}.rb"
statements = String.new
levels.times { |index| statements << "  validate(value, :item#{index})\n" }
method_pair = "def alpha(value)\n#{statements}end\ndef beta(value)\n#{statements}end\n"
File.write(path, method_pair)
output_path = "#{path}.out"
error_path = "#{path}.err"
process = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", "3", path, out: output_path, err: error_path)
_, status = Process.waitpid2(process)
output = File.read(output_path)
error = File.read(error_path)
raise "300-expression method candidates were not analyzed: #{output} #{error}" unless status.exitstatus == 2
raise "300-expression method group was missing: #{output}" unless output.include?("kind=\"similar\"") && output.include?("locations=\"#{path}:1,#{path}:#{levels + 3}\"")
raise "300-expression methods were marked incomplete: #{output}" unless output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
reference_process = Process.spawn("bundle", "exec", "flay", "--mass", "3", path, out: "#{path}.reference.out", err: "#{path}.reference.err")
_, reference_status = Process.waitpid2(reference_process)
reference = File.read("#{path}.reference.out")
raise "Flay 2.14.4 did not report the generated method group: #{reference}" unless reference_status.success? && reference.include?("Similar code found in :defn (mass = ")
native_group = output.split("\n").find { |line| line.include?("node=\"defn\"") }
reference_group = reference.split("\n").find { |line| line.include?("Similar code found in :defn (mass = ") }
native_mass = native_group.split("mass=")[1].split.first
reference_mass = reference_group.split("mass = ")[1].split(")")[0]
raise "300-expression method mass differed from Flay: #{native_group} / #{reference_group}" unless native_mass == reference_mass
puts "Method candidate capacity contract: pass"
File.delete(path)
File.delete(output_path)
File.delete(error_path)
File.delete("#{path}.reference.out")
File.delete("#{path}.reference.err")
