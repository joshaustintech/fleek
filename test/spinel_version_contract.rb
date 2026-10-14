# Keeps the compiler boundary on the accepted Spinel source revision.
version_output_path = "/tmp/fleek-spinel-version-out"
version_error_path = "/tmp/fleek-spinel-version-err"
process_id = Process.spawn(ARGV[0], "--version", out: version_output_path, err: version_error_path)
_, process_status = Process.waitpid2(process_id)
raise "cannot read Spinel version" unless process_status.success?
version_output = File.read(version_output_path)
expected_identity = "spinel 112bae85c1a2 (2026.09.12)"
raise "wrong Spinel compiler identity" unless version_output.include?(expected_identity)
parser_root = ARGV[1]
parser_header_path = parser_root + "/vendor/prism/include/prism/version.h"
raise "set SPINEL_ROOT to the pinned Spinel source checkout" unless File.file?(parser_header_path)
parser_header = File.read(parser_header_path)
expected_parser = "#define PRISM_VERSION \"1.9.0\""
raise "wrong vendored Prism identity" unless parser_header.include?(expected_parser)
lockfile = File.read("Gemfile.lock")
raise "wrong locked Prism artifact" unless lockfile.include?("prism (1.9.0)")
raise "Prism artifact checksum is missing" unless lockfile.include?("prism (1.9.0) sha256=7b530c6a9f92c24300014919c9dcbc055bf4cdf51ec30aed099b06cd6674ef85")

puts "Spinel and Prism identities: pass"
