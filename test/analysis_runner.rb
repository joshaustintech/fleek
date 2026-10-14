# Runs Fleek and Reek for CLI comparison contracts.
class AnalysisRunner
  def self.fleek(path)
    process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", path, out: "/tmp/fleek-contract-out", err: "/tmp/fleek-contract-err")
    observe(process_id, "/tmp/fleek-contract-out", "/tmp/fleek-contract-err")
  end

  def self.reek(path)
    process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "reek", "--smell", "ClassVariable", path, out: "/tmp/reek-contract-out", err: "/tmp/reek-contract-err")
    observe(process_id, "/tmp/reek-contract-out", "/tmp/reek-contract-err")
  end

  # :reek:ControlParameter
  def self.repeated(tool, path)
    if tool == "fleek"
      process_id = Process.spawn("build/fleek", "--checks", "reek:ClassVariable", path, path, out: "/tmp/fleek-contract-out", err: "/tmp/fleek-contract-err")
      observe(process_id, "/tmp/fleek-contract-out", "/tmp/fleek-contract-err")
    else
      process_id = Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "reek", "--smell", "ClassVariable", path, path, out: "/tmp/reek-contract-out", err: "/tmp/reek-contract-err")
      observe(process_id, "/tmp/reek-contract-out", "/tmp/reek-contract-err")
    end
  end

  def self.observe(process_id, output_path, error_path)
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read(output_path), File.read(error_path)]
  end

  def self.assert_reference(actual, reference, label)
    assert_status(actual, reference, label)
    reports = [actual, reference].map { |result| finding_lines(result[1]) }
    raise "#{label} findings differ from Reek" unless reports[0] == reports[1]
  end

  def self.assert_status(actual, reference, label)
    actual_status = actual[0]
    raise "#{label} status differs from Reek" unless actual_status == reference[0] && actual_status == 2
  end

  def self.finding_lines(output)
    output.lines.select { |line| / -- |ClassVariable:/.match?(line) }
  end
end
