# Compares Fleek's Reek AST translation with the pinned parser gem using Reek 6.6.0's builder modes.
class ReekAstContract
  FIXTURES = Dir.glob("test/fixtures/reek_ast/*.rb").sort.freeze
  OUTPUT = "/tmp/fleek-reek-ast"
  # Runs "$0" with the remaining arguments, writing stdout to $1 and stderr to $1.err.
  REDIRECT = 'out="$1"; shift; exec "$0" "$@" > "$out" 2> "$out.err"'

  def self.verify
    paths = selected_paths
    failures = paths.each_with_index.map { |path, index| compare(path, "#{OUTPUT}-#{index}") }.compact
    raise "Reek AST differed:\n#{failures.join("\n")}" unless failures.empty?
    puts "Reek AST contract: pass (#{paths.length} sources)"
  end

  def self.selected_paths
    list = ENV["FLEEK_REEK_AST_FILES"]
    paths = list ? File.read(list).split("\n") : FIXTURES
    raise "no Reek AST fixtures selected" if paths.empty?
    paths
  end

  def self.compare(path, output)
    expected = normalize_reference(run_reference(path, output))
    actual = normalize(run_fleek(path, output))
    return nil if expected == actual
    "#{path}: #{first_difference(expected, actual)}"
  end

  def self.run_reference(path, output)
    # The child writes its own files: Spinel 2026.09.12 can return from waitpid2 before redirected output lands.
    process_id = Process.spawn("sh", "-c", REDIRECT, ENV["BUNDLE"] || "bundle", "#{output}-reference", "exec", "ruby-parse", "--34",
      "--legacy-procarg0", "--legacy-encoding", "--legacy-index", "--legacy-arg-inside-procarg0", "--legacy-forward-arg", "--legacy-kwargs",
      "--legacy-match-pattern", path)
    Process.waitpid2(process_id)
    File.read("#{output}-reference")
  end

  def self.run_fleek(path, output)
    process_id = Process.spawn("sh", "-c", REDIRECT, "build/fleek", "#{output}-actual", "--reek-ast", path)
    Process.waitpid2(process_id)
    File.read("#{output}-actual") + File.read("#{output}-actual.err")
  end

  # Whitespace split without a regexp: regexp split was intermittently wrong under Spinel 2026.09.12.
  def self.normalize(text)
    text.split(" ")
  end

  # ruby-parse prints node types with dashes; Reek's symbols use underscores.
  def self.normalize_reference(text)
    normalize(text).map { |token| token.start_with?("(") ? token.tr("-", "_") : token }
  end

  def self.first_difference(expected, actual)
    index = 0
    index += 1 while index < expected.length && index < actual.length && expected[index] == actual[index]
    start = index > 6 ? index - 6 : 0
    "expected #{expected[start, 14].join(" ")} | actual #{actual[start, 14].join(" ")}"
  end
end

ReekAstContract.verify
