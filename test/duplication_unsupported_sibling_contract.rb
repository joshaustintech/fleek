require_relative "analysis_runner"

unsupported_sibling_path = "test/fixtures/duplication_class_unsupported_sibling.rb"
temporary_root = ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")
fleek_output = "#{temporary_root}/fleek-unsupported-sibling-out"
fleek_error = "#{temporary_root}/fleek-unsupported-sibling-err"
flay_output = "#{temporary_root}/flay-unsupported-sibling-out"
flay_error = "#{temporary_root}/flay-unsupported-sibling-err"
fleek_process = Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", unsupported_sibling_path,
  out: fleek_output, err: fleek_error)
actual = AnalysisRunner.observe(fleek_process, fleek_output, fleek_error)
flay_process = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "flay", unsupported_sibling_path,
  out: flay_output, err: flay_error)
reference = AnalysisRunner.observe(flay_process, flay_output, flay_error)
group = "node=\"class\" kind=\"similar\" locations=\"#{unsupported_sibling_path}:2,#{unsupported_sibling_path}:11\" mass=50 score=50"
actual_fields = [group, "Total duplication score: 50", "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"]
reference_fields = ["Similar code found in :class (mass = 50)", "#{unsupported_sibling_path}:2", "#{unsupported_sibling_path}:11", "Total score (lower is better) = 50"]
[[actual, 1, actual_fields, "unsupported class sibling hid the verified Flay group"],
  [reference, 0, reference_fields, "unsupported sibling Flay reference changed"]].each do |observation, status, fields, message|
  raise message unless observation[0] == status && fields.all? { |field| observation[1].index(field) != nil }
end
puts "Unsupported sibling duplication contract: pass"
