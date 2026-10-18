temporary_root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
first_path = "#{temporary_root}/fleek-class-method-cross-file-a.rb"
second_path = "#{temporary_root}/fleek-class-method-cross-file-b.rb"
first_source = "class SharedClass\n  def transform(value)\n    validate(value)\n    normalize(value)\n    persist(value)\n    return value\n  end\n\n  def unique\n    check(1)\n  end\nend\n"
second_source = "class SharedClass\n  def transform(value)\n    validate(value)\n    normalize(value)\n    persist(value)\n    return value\n  end\n\n  def unique\n    check(1, 2)\n  end\nend\n"
File.write(first_path, first_source)
File.write(second_path, second_source)
actual_output_path = "#{first_path}.actual.out"
actual_error_path = "#{first_path}.actual.err"
reference_output_path = "#{first_path}.reference.out"
reference_error_path = "#{first_path}.reference.err"
actual_process = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", "3", second_path, first_path,
  out: actual_output_path, err: actual_error_path)
_, actual_status = Process.waitpid2(actual_process)
actual_output = File.read(actual_output_path)
actual_error = File.read(actual_error_path)
reference_process = Process.spawn("bundle", "exec", "flay", "--mass", "3", second_path, first_path,
  out: reference_output_path, err: reference_error_path)
_, reference_status = Process.waitpid2(reference_process)
reference_output = File.read(reference_output_path)
reference_error = File.read(reference_error_path)
raise "Flay class-method reference changed: #{reference_output} #{reference_error}" unless reference_status.success?
raise "class methods across files were not analyzed: #{actual_output} #{actual_error}" unless actual_status.exitstatus == 2
native_group = actual_output.lines.find { |line| line.include?('node="defn"') }
reference_group = reference_output.lines.find { |line| line.include?("code found in :defn") }
raise "Flay did not group class methods across files: #{reference_output}" unless reference_group
raise "Fleek did not group class methods across files: #{actual_output}" unless native_group
flay_reported_mass = reference_group[/mass(?:\*2)? = (\d+)/, 1].to_i
flay_mass = reference_group.include?("mass*2") ? flay_reported_mass / 2 : flay_reported_mass
native_mass = native_group[/ mass=(\d+)/, 1].to_i
expected_locations = "locations=\"#{first_path}:2,#{second_path}:2\""
raise "cross-file class method mass differed from Flay: #{reference_group} / #{native_group}" unless native_mass == flay_mass
raise "cross-file class method kind or score differed: #{native_group}" unless native_group.include?("kind=\"identical\"") && native_group.include?("score=#{flay_reported_mass}")
raise "cross-file class method locations or order differed: #{actual_output}" unless native_group.include?(expected_locations)
reference_locations = ["#{first_path}:2", "#{second_path}:2"]
reference_locations_match = reference_locations.all? { |location| reference_output.include?(location) } && reference_output.index(reference_locations[0]) < reference_output.index(reference_locations[1])
raise "Flay cross-file class method locations or order changed: #{reference_output}" unless reference_locations_match
raise "cross-file class methods were marked incomplete: #{actual_output}" unless actual_output.include?("Coverage: 2 selected; 2 analyzed; 0 failed; 0 excluded")
puts "Cross-file class method contract: pass"
File.delete(first_path)
File.delete(second_path)
File.delete(actual_output_path)
File.delete(actual_error_path)
File.delete(reference_output_path)
File.delete(reference_error_path)
