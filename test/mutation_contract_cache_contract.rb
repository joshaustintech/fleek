# frozen_string_literal: true

require_relative "mutation_contract_cache"
require_relative "contract_support"

# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:IrresponsibleModule
# :reek:LongParameterList
# :reek:TooManyStatements
class MutationContractCacheContract
  def self.run
    root = "#{ENV.fetch('FLEEK_TEMP_ROOT')}/mutation-contract-cache-#{Process.pid}"
    create_inputs(root)
    verify_supported_contract_sets
    verify_miss_and_hit(root)
    verify_input_changes_miss(root)
    verify_corruption_misses(root)
    verify_failed_build_not_published(root)
    verify_concurrent_publishers(root)
    puts "Mutation contract cache contract: pass"
  ensure
    ContractSupport.cleanup(root, "mutation cache contract") if root
  end

  def self.verify_supported_contract_sets
    leaf = ["test/native_parser_contract.rb"]
    descriptor = ["test/duplication_method_call_contract.rb"]
    expect(MutationContractCache.supports_contract_set?(leaf, []), "native parser leaf was not cacheable")
    expect(MutationContractCache.supports_contract_set?(descriptor, ["test/duplication_method_pair_contract.rb"]),
      "call descriptor and its shared helper were not cacheable")
    expect(!MutationContractCache.supports_contract_set?(descriptor, []), "call descriptor without its helper was cacheable")
    expect(!MutationContractCache.supports_contract_set?(descriptor, ["test/unrelated_contract.rb"]),
      "call descriptor with an unexpected dependency was cacheable")
    expect(!MutationContractCache.supports_contract_set?(descriptor + leaf, ["test/duplication_method_pair_contract.rb"]),
      "multiple selected contracts were cacheable")
    cache = MutationContractCache.new("unused-cache-root")
    original = cache_key(cache, "#{ENV.fetch('FLEEK_TEMP_ROOT')}/mutation-contract-cache-#{Process.pid}")
    changed_rewrite = cache.key("#{ENV.fetch('FLEEK_TEMP_ROOT')}/mutation-contract-cache-#{Process.pid}/bundle",
      "#{ENV.fetch('FLEEK_TEMP_ROOT')}/mutation-contract-cache-#{Process.pid}/compiler",
      "#{ENV.fetch('FLEEK_TEMP_ROOT')}/mutation-contract-cache-#{Process.pid}/runtime", ["-O", "1"], "changed-rewrite")
    expect(original != changed_rewrite, "temporary-path rewrite format was omitted from cache identity")
  end

  def self.create_inputs(root)
    ContractSupport.create_test_directories(root, "cache")
    File.write("#{root}/bundle/native_parser_contract.rb", "unchanged contract source")
    File.write("#{root}/bundle/duplication_method_call_contract.rb", "prepared call contract")
    File.write("#{root}/bundle/duplication_method_pair_contract.rb", "prepared pair helper")
    File.write("#{root}/bundle/analysis_runner.rb", "prepared bundle source")
    File.write("#{root}/compiler", "compiler identity 1")
    File.write("#{root}/runtime/lib/sp_types.h", "runtime header")
    File.write("#{root}/runtime/vendor/prism/include/prism.h", "prism header")
    File.write("#{root}/runtime/vendor/rbs/include/rbs.h", "rbs header")
    File.write("#{root}/runtime/build/libprism.a", "prism library")
    File.write("#{root}/runtime/build/librbs.a", "rbs library")
  end

  def self.verify_miss_and_hit(root)
    builds = [0]
    first = compile_or_restore(root, "first", ["-O", "1"], builds, "contract executable")
    second = compile_or_restore(root, "second", ["-O", "1"], builds, "unexpected compile")
    expect(first == :miss && second == :hit, "first miss and second hit were not distinguished")
    expect(builds[0] == 1, "cache hit invoked the compiler")
    expect(File.binread("#{root}/second") == "contract executable", "cached executable bytes differed")
    expect((File.stat("#{root}/second").mode & 0o111).positive?, "cached executable lost execute permissions")
  end

  def self.verify_input_changes_miss(root)
    builds = [0]
    File.write("#{root}/bundle/native_parser_contract.rb", "changed contract source")
    expect(compile_or_restore(root, "source-change", ["-O", "1"], builds, "source-change") == :miss,
      "prepared source change hit cache")
    ["duplication_method_call_contract.rb", "duplication_method_pair_contract.rb", "analysis_runner.rb"].each do |source_name|
      File.write("#{root}/bundle/#{source_name}", "changed #{source_name}")
      destination = "#{source_name}-change"
      expect(compile_or_restore(root, destination, ["-O", "1"], builds, "#{source_name}-change") == :miss,
        "prepared dependency change hit cache: #{source_name}")
    end
    File.write("#{root}/compiler", "compiler identity 2")
    expect(compile_or_restore(root, "compiler-change", ["-O", "1"], builds, "compiler-change") == :miss,
      "compiler change hit cache")
    File.write("#{root}/runtime/build/libprism.a", "changed runtime library")
    expect(compile_or_restore(root, "runtime-change", ["-O", "1"], builds, "runtime-change") == :miss,
      "runtime library change hit cache")
    File.write("#{root}/runtime/vendor/prism/include/prism.h", "changed runtime header")
    expect(compile_or_restore(root, "header-change", ["-O", "1"], builds, "header-change") == :miss,
      "runtime header change hit cache")
    expect(compile_or_restore(root, "flags-change", ["-O", "0"], builds, "flags-change") == :miss,
      "compile option change hit cache")
  end

  def self.verify_corruption_misses(root)
    builds = [0]
    cache = MutationContractCache.new("#{root}/corrupt-cache")
    key = cache_key(cache, root)
    cache_path = cache.entry_path(key)
    cache.make_cache_directory
    File.write(cache_path, "corrupt incomplete entry")
    cache_result = compile_with_cache(cache, root, "#{root}/restored", ["-O", "1"], builds, "rebuilt executable")
    expect(cache_result == :miss && build_count(builds) == 1, "corrupt cache entry was used")
    expect(File.binread("#{root}/restored") == "rebuilt executable", "corrupt entry was not rebuilt")
  end

  def self.verify_failed_build_not_published(root)
    cache = MutationContractCache.new("#{root}/failed-cache")
    key = cache_key(cache, root)
    begin
      cache.prepare("#{root}/bundle", "#{root}/failed", "#{root}/compiler", "#{root}/runtime", ["-O", "1"]) do |path|
        File.write(path, "partial executable")
        raise "expected fake compiler failure"
      end
    rescue RuntimeError => error
      expect(error.message == "expected fake compiler failure", "unexpected build failure")
    end
    expect(!File.exist?(cache.entry_path(key)), "failed compiler output was published")
    builds = [0]
    cache_result = compile_with_cache(cache, root, "#{root}/failed", ["-O", "1"], builds, "recovered executable")
    expect(cache_result == :miss && build_count(builds) == 1, "failed build produced a cache hit")
  end

  def self.verify_concurrent_publishers(root)
    cache = MutationContractCache.new("#{root}/concurrent-cache")
    cache.make_cache_directory
    key = cache_key(cache, root)
    first_source = "#{root}/publisher-one"
    second_source = "#{root}/publisher-two"
    File.binwrite(first_source, "one" * 200_000)
    File.binwrite(second_source, "two" * 200_000)
    File.chmod(0o755, first_source)
    File.chmod(0o755, second_source)
    first = launch_publisher(cache, key, first_source)
    second = launch_publisher(cache, key, second_source)
    _, first_status = Process.waitpid2(first)
    _, second_status = Process.waitpid2(second)
    expect(first_status.success? && second_status.success?, "concurrent publisher failed")
    restored = "#{root}/concurrent-restored"
    expect(cache.restore(cache.entry_path(key), key, restored), "concurrent publisher exposed a partial entry")
    payload = File.binread(restored)
    expect(payload == File.binread(first_source) || payload == File.binread(second_source),
      "concurrent publisher mixed executable bytes")
    expect(Dir.glob(cache.entry_path(key) + ".tmp-*").empty?, "publisher left a temporary file")
  end

  def self.launch_publisher(cache, key, source)
    Process.spawn(ENV.fetch("SPINEL"), "-E", "test/mutation_contract_cache_publisher.rb", File.dirname(cache.entry_path(key)),
      cache.entry_path(key), key, source, out: "/dev/null", err: "/dev/null")
  end

  def self.compile_or_restore(root, destination_name, options, builds, bytes)
    cache = MutationContractCache.new("#{root}/cache")
    compile_with_cache(cache, root, "#{root}/#{destination_name}", options, builds, bytes)
  end

  def self.compile_with_cache(cache, root, destination, options, builds, bytes)
    cache.prepare("#{root}/bundle", destination, "#{root}/compiler", "#{root}/runtime", options) do |path|
      ContractSupport.write_executable(path, builds, bytes)
    end
  end

  def self.cache_key(cache, root)
    cache.key("#{root}/bundle", "#{root}/compiler", "#{root}/runtime", ["-O", "1"])
  end

  def self.build_count(builds)
    builds[0]
  end

  def self.expect(condition, message)
    ContractSupport.expect(condition, message)
  end
end

MutationContractCacheContract.run
