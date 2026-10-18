fixtures = {
  "self_receiver" => 10,
  "parenthesized_expression" => 8
}
temporary_root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
fixtures.each do |name, mass|
  path = "test/fixtures/duplication_methods_#{name}.rb"
  actual_output_path = "#{temporary_root}/fleek-method-expression-#{name}-actual.out"
  actual_error_path = "#{temporary_root}/fleek-method-expression-#{name}-actual.err"
  reference_output_path = "#{temporary_root}/fleek-method-expression-#{name}-reference.out"
  reference_error_path = "#{temporary_root}/fleek-method-expression-#{name}-reference.err"
  actual_process = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", "3", path,
    out: actual_output_path, err: actual_error_path)
  _, actual_status = Process.waitpid2(actual_process)
  actual_output = File.read(actual_output_path)
  actual_error = File.read(actual_error_path)
  raise "#{name} methods were not analyzed: #{actual_output} #{actual_error}" unless actual_status.exitstatus == 2
  reference_process = Process.spawn("bundle", "exec", "flay", "--mass", "3", path,
    out: reference_output_path, err: reference_error_path)
  _, reference_status = Process.waitpid2(reference_process)
  reference_output = File.read(reference_output_path)
  raise "Flay #{name} reference changed: #{reference_output}" unless reference_status.success? && reference_output.include?("Similar code found in :defn (mass = #{mass})")
  expected = "node=\"defn\" kind=\"similar\" locations=\"#{path}:1,#{path}:5\" mass=#{mass} score=#{mass}"
  raise "#{name} methods differed from Flay: #{actual_output}" unless actual_output.include?(expected)
  raise "#{name} methods were marked incomplete: #{actual_output}" unless actual_output.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
  File.delete(actual_output_path)
  File.delete(actual_error_path)
  File.delete(reference_output_path)
  File.delete(reference_error_path)
end
puts "Method expression wrapper contract: pass"
