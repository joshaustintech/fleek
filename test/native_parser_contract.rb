# Exercises the compiled parser on source bytes without evaluating that source.
class NativeParserProcess
  def self.run(source_path)
    process_id = Process.spawn("env", "PATH=/usr/bin:/bin", "./build/fleek", "--parse-ruby4", source_path, out: "/tmp/fleek-parser-out", err: "/tmp/fleek-parser-err")
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read("/tmp/fleek-parser-out"), File.read("/tmp/fleek-parser-err")]
  end
end

valid = NativeParserProcess.run("test/fixtures/ruby4.rb")
raise "Ruby 4 parse status" unless valid[0] == 0
raise "parse claimed a check" unless valid[1].include?("PARSE OK") && !valid[1].include?("PASS")
raise "comments were not retained" unless valid[1].include?("comments retained")
raise "valid output stderr" unless valid[2] == ""
raise "repeated parse changed result" unless NativeParserProcess.run("test/fixtures/ruby4.rb") == valid

spinel_source = NativeParserProcess.run("test/fixtures/spinel_ffi.rb")
raise "Spinel FFI declaration parse status" unless spinel_source[0] == 0

invalid = NativeParserProcess.run("test/fixtures/invalid.rb")
raise "invalid Ruby source status" unless invalid[0] == 1
raise "original byte location changed" unless invalid[2].include?("test/fixtures/invalid.rb:2:17:") && invalid[2].include?("byte 31")
raise "Prism diagnostic was not preserved" unless invalid[2].include?("expected")

missing = NativeParserProcess.run("test/fixtures/not-found.rb")
raise "missing input was not handled" unless missing[0] == 1 && missing[2].include?("Cannot read source file")

side_effect = NativeParserProcess.run("test/fixtures/side_effect.rb")
raise "side effect source parse status" unless side_effect[0] == 0
raise "source was executed" if File.exist?("/tmp/fleek-parser-side-effect")

File.binwrite("test/fixtures/embedded-nul.rb", "1\0def broken(")
begin
  raise "binary fixture did not preserve NUL" unless File.binread("test/fixtures/embedded-nul.rb").bytesize == 13
  nul_result = NativeParserProcess.run("test/fixtures/embedded-nul.rb")
  raise "embedded NUL was not rejected" unless nul_result[0] == 1 && nul_result[2].include?("embedded NUL byte is unsupported")
ensure
  File.delete("test/fixtures/embedded-nul.rb") if File.exist?("test/fixtures/embedded-nul.rb")
end

puts "Native parser contract: pass"
