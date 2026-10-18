path = "test/fixtures/duplication_methods_block_expression.rb"
temporary_root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
actual_output_path = "#{temporary_root}/fleek-block-actual.out"
actual_error_path = "#{temporary_root}/fleek-block-actual.err"
reference_output_path = "#{temporary_root}/fleek-block-reference.out"
reference_error_path = "#{temporary_root}/fleek-block-reference.err"
actual_process = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", "3", path,
  out: actual_output_path, err: actual_error_path)
_, actual_status = Process.waitpid2(actual_process)
actual_output = File.read(actual_output_path)
actual_error = File.read(actual_error_path)
raise "block-expression methods were not analyzed: #{actual_output} #{actual_error}" unless actual_status.exitstatus == 2
reference_process = Process.spawn("bundle", "exec", "flay", "--mass", "3", path, out: reference_output_path, err: reference_error_path)
_, reference_status = Process.waitpid2(reference_process)
reference_output = File.read(reference_output_path)
raise "Flay block-expression reference changed: #{reference_output}" unless reference_status.success? && reference_output.include?("Similar code found in :defn (mass = 16)")
expected = "node=\"defn\" kind=\"similar\" locations=\"#{path}:1,#{path}:5\" mass=16 score=16"
raise "block-expression methods differed from Flay: #{actual_output}" unless actual_output.include?(expected)
raise "block-expression methods were marked incomplete: #{actual_output}" unless actual_output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
puts "Method block contract: pass"
File.delete(actual_output_path)
File.delete(actual_error_path)
File.delete(reference_output_path)
File.delete(reference_error_path)
