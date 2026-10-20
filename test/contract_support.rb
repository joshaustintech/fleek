# frozen_string_literal: true

# :reek:ControlParameter
# :reek:IrresponsibleModule
# :reek:LongParameterList
# :reek:TooManyStatements
class ContractSupport
  def self.create_directories(paths)
    paths.each do |path|
      process_id = Process.spawn("mkdir", "-p", path, out: "/dev/null", err: "/dev/null")
      _, status = Process.waitpid2(process_id)
      expect(status.success?, "could not prepare contract directory")
    end
  end

  def self.create_test_directories(root, kind)
    suffixes = kind == "staging" ? "test test/fixtures .githooks .git dist build build/mutation-reference-cache" :
      "bundle cache runtime runtime/lib runtime/vendor/prism/include runtime/vendor/rbs/include runtime/build"
    paths = [root]
    suffixes.split.each { |suffix| paths << "#{root}/#{suffix}" }
    create_directories(paths)
  end

  def self.cleanup(root, description)
    process_id = Process.spawn("rm", "-rf", root, out: "/dev/null", err: "/dev/null")
    _, status = Process.waitpid2(process_id)
    expect(status.success?, "could not clean #{description}")
  end

  def self.write_executable(path, builds, bytes)
    builds[0] += 1
    File.binwrite(path, bytes)
    File.chmod(0o755, path)
  end

  def self.expect(condition, message)
    raise message unless condition
  end
end
