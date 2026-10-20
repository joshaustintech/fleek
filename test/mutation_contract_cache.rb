# frozen_string_literal: true

require "digest"

# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:IrresponsibleModule
# :reek:LongParameterList
# :reek:DataClump
# :reek:FeatureEnvy
# :reek:NestedIterators
# :reek:TooManyMethods
# :reek:UtilityFunction
# :reek:TooManyStatements
class MutationContractCache
  FORMAT = "fleek-public-contract-cache-v3"
  REWRITE_FORMAT = "public-contract-temp-root-rewrite-v1"
  ENVIRONMENT = %w[PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH LIBRARY_PATH SDKROOT DEVELOPER_DIR CC CFLAGS CPPFLAGS LDFLAGS ARCHFLAGS MACOSX_DEPLOYMENT_TARGET].freeze

  def initialize(root)
    @root = root
    @temporary_serial = 0
  end

  def self.supports_contract_set?(contracts, dependencies, mapped_contracts, dependency_map)
    return false if contracts.empty? || !contracts.all? { |contract| mapped_contracts.include?(contract) }

    contracts.flat_map { |contract| dependency_map.fetch(contract, []) } == dependencies
  end

  def prepare(bundle, executable, compiler, runtime_root, options)
    cache_key = key_if_available(bundle, compiler, runtime_root, options)
    unless cache_key
      yield executable
      return :miss
    end
    return :hit if restore(entry_path(cache_key), cache_key, executable)

    yield executable
    publish(entry_path(cache_key), cache_key, executable)
    :miss
  end

  def prepare_many(bundle, contracts, directory, compiler, runtime_root, options)
    cache_key = key_if_available(bundle, compiler, runtime_root, options)
    hits = 0
    misses = []
    contracts.each do |contract|
      name = File.basename(contract, ".rb")
      executable = File.expand_path("#{directory}/#{name}")
      if cache_key && restore(entry_path(cache_key, name), cache_key, executable)
        hits += 1
      else
        misses << contract
      end
    end
    yield misses unless misses.empty?
    misses.each do |contract|
      name = File.basename(contract, ".rb")
      publish(entry_path(cache_key, name), cache_key, "#{directory}/#{name}") if cache_key
    end
    { hits: hits, misses: misses.length }
  end

  def key_if_available(bundle, compiler, runtime_root, options)
    return unless make_cache_directory

    key(bundle, compiler, runtime_root, options)
  rescue StandardError => error
    warn "Cache key unavailable: #{error.message}"
    nil
  end

  def key(bundle, compiler, runtime_root, options, rewrite_format = REWRITE_FORMAT)
    digest = String.new
    add(digest, FORMAT)
    add(digest, rewrite_format)
    add(digest, RUBY_PLATFORM)
    add(digest, File.realpath(runtime_root))
    add(digest, options.join(" "))
    ENVIRONMENT.each { |name| add(digest, "#{name}=#{ENV[name]}") }
    files = []
    add_compiler(digest, compiler, files)
    add_sources(digest, bundle, files)
    add_runtime(digest, runtime_root, files)
    file_digests(digest, files.uniq.sort)
    Digest::SHA256.hexdigest(digest)
  end

  def entry_path(cache_key, contract_name = nil)
    suffix = contract_name ? "#{contract_name}-" : ""
    "#{@root}/#{suffix}#{cache_key}.cache"
  end

  def make_cache_directory
    process_id = Process.spawn("mkdir", "-p", @root, out: "/dev/null", err: "/dev/null")
    _, status = Process.waitpid2(process_id)
    status.success?
  end

  def restore(path, cache_key, executable)
    return false unless File.file?(path)

    File.open(path, "rb") do |cache|
      return false unless cache.gets == "#{FORMAT}\n"
      return false unless cache.gets&.chomp == cache_key

      mode = Integer(cache.gets&.chomp, 8)
      return false unless (mode & 0o111).positive?

      checksum = cache.gets&.chomp
      return false unless cache.gets == "\n"

      bytes = cache.read
      return false unless checksum == Digest::SHA256.hexdigest(bytes)

      atomic_copy(bytes, executable, mode)
    end
    true
  rescue StandardError
    false
  end

  def publish(path, cache_key, executable)
    return false unless File.file?(executable)
    mode = File.stat(executable).mode & 0o777
    return false unless (mode & 0o111).positive?

    bytes = File.binread(executable)
    temporary = unique_path("#{path}.tmp")
    File.open(temporary, "wb") do |cache|
      cache.write("#{FORMAT}\n#{cache_key}\n#{mode.to_s(8)}\n#{Digest::SHA256.hexdigest(bytes)}\n\n")
      cache.write(bytes)
    end
    File.rename(temporary, path)
    true
  rescue StandardError
    false
  ensure
    File.delete(temporary) if temporary && File.exist?(temporary)
  end

  def atomic_copy(bytes, executable, mode)
    temporary = unique_path("#{executable}.restore")
    File.binwrite(temporary, bytes)
    File.chmod(mode, temporary)
    File.rename(temporary, executable)
    true
  ensure
    File.delete(temporary) if temporary && File.exist?(temporary)
  end

  def unique_path(prefix)
    @temporary_serial += 1
    "#{prefix}-#{Process.pid}-#{object_id}-#{@temporary_serial}"
  end

  def add_compiler(digest, compiler, files)
    path = executable_path(compiler)
    add(digest, path)
    files << path
  end

  def executable_path(compiler)
    return File.realpath(compiler) if File.file?(compiler)

    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |directory|
      candidate = "#{directory}/#{compiler}"
      return File.realpath(candidate) if File.file?(candidate)
    end
    raise "compiler executable unavailable for contract cache"
  end

  def add_sources(digest, bundle, files)
    paths = Dir.glob("#{bundle}/**/*").select { |path| File.file?(path) }.sort
    raise "prepared contract bundle is empty" if paths.empty?

    paths.each do |path|
      add(digest, path.sub("#{bundle}/", ""))
      files << path
    end
  end

  def add_runtime(digest, runtime_root, files)
    paths = []
    ["lib/**/*.h", "lib/**/*.a", "vendor/prism/include/**/*.h", "vendor/rbs/include/**/*.h",
      "build/*.a"].each do |pattern|
      paths.concat(Dir.glob("#{runtime_root}/#{pattern}").select { |path| File.file?(path) })
    end
    raise "compiler runtime identity unavailable" if paths.empty?

    paths.sort.each do |path|
      add(digest, path.sub("#{runtime_root}/", ""))
      files << path
    end
  end

  def file_digests(digest, paths)
    input = unique_path("/tmp/fleek-contract-cache-inputs")
    output = unique_path("/tmp/fleek-contract-cache-digests")
    File.open(input, "wb") do |identity|
      paths.each do |path|
        bytes = File.binread(path)
        identity.write("#{bytes.bytesize}:")
        identity.write(bytes)
      end
    end
    process_id = Process.spawn("shasum", "-a", "256", input, out: output, err: "/dev/null")
    _, status = Process.waitpid2(process_id)
    raise "could not identify contract cache input" unless status.success?

    lines = File.readlines(output)
    raise "could not read contract cache identity" unless lines.length == 1

    add(digest, lines[0].split(" ", 2).first)
  ensure
    File.delete(input) if input && File.exist?(input)
    File.delete(output) if output && File.exist?(output)
  end

  def add(digest, value)
    bytes = value.to_s
    digest << "#{bytes.bytesize}:#{bytes}"
  end
end
