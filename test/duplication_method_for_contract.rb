path = "test/fixtures/duplication_methods_for_control.rb"
temporary_root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
actual_output_path = "#{temporary_root}/fleek-for-control-actual.out"
actual_error_path = "#{temporary_root}/fleek-for-control-actual.err"
reference_output_path = "#{temporary_root}/fleek-for-control-reference.out"
reference_error_path = "#{temporary_root}/fleek-for-control-reference.err"

actual_process = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", "3", path,
  out: actual_output_path, err: actual_error_path)
_, actual_status = Process.waitpid2(actual_process)
actual_output = File.read(actual_output_path)
actual_error = File.read(actual_error_path)
raise "top-level methods with for-control loops differed from Flay: #{actual_output} #{actual_error}" unless actual_status.exitstatus == 2

reference_process = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "flay", "--mass", "3", path,
  out: reference_output_path, err: reference_error_path)
_, reference_status = Process.waitpid2(reference_process)
reference_output = File.read(reference_output_path)
reference_fields = ["Similar code found in :defn (mass = 14)", "#{path}:1", "#{path}:7", "Total score (lower is better) = 14"]
raise "top-level methods with for-control loops differed from Flay: reference #{reference_output}" unless reference_status.success? && reference_fields.all? { |field| reference_output.include?(field) }

expected = "node=\"defn\" kind=\"similar\" locations=\"#{path}:1,#{path}:7\" mass=14 score=14"
raise "top-level methods with for-control loops differed from Flay: #{actual_output}" unless actual_output.include?(expected)
raise "top-level methods with for-control loops differed from Flay: #{actual_output}" unless actual_output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
raise "top-level methods with for-control loops differed from Flay: #{actual_output}" unless actual_output.include?("Status: findings")

[actual_output_path, actual_error_path, reference_output_path, reference_error_path].each { |file| File.delete(file) }
puts "Method for-control contract: pass"
