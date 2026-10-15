# Verifies Ruby 4 and pinned Spinel source findings without executing analyzed source.
require_relative "analysis_runner"

# Keeps extension finding identity and location assertions explicit.
class LanguageExtensionContract
  # Describes one extension finding's original source identity.
  Finding = Struct.new(:path, :line, :context)
  # Defines reference-backed Flay group expectations.
  Duplication = Struct.new(:path, :kind, :mass, :score, :first_line, :second_line)

  def self.verify_finding(result, expectation)
    path, line, context = expectation.to_a
    fields = ["source=\"#{path}\"", "lines=\"#{line}\"", "context=\"#{context}\"", "name=\"@@count\""]
    raise "#{context} ClassVariable finding or location was lost" unless result[0] == 2 && fields.all? { |field| result[1].include?(field) }
  end

  def self.verify_duplication(actual, reference, expectation)
    verify_reference_duplication(reference, expectation)
    verify_actual_duplication(actual, expectation)
  end

  def self.verify_reference_duplication(reference, expectation)
    output = reference[1]
    score_line = "Total score (lower is better) = #{expectation.score}"
    locations = duplication_locations(expectation)
    valid = reference[0] == 0 && output.include?(score_line) && output.include?(reference_group(expectation)) && output.index(locations[0]) < output.index(locations[1])
    raise "#{expectation.path} Flay reference kind, mass, score, or locations changed" unless valid
  end

  def self.verify_actual_duplication(actual, expectation)
    output = actual[1]
    raise "#{expectation.path} Flay finding or coverage differs" unless actual[0] == 2 && output.include?(duplication_group(expectation))
  end

  def self.duplication_locations(expectation)
    [expectation.first_line, expectation.second_line].map { |line| "#{expectation.path}:#{line}" }
  end

  def self.duplication_group(expectation)
    locations = duplication_locations(expectation).join(",")
    "kind=\"#{expectation.kind}\" locations=\"#{locations}\" mass=#{expectation.mass} score=#{expectation.score}"
  end

  def self.reference_group(expectation)
    if expectation.kind == "identical"
      "IDENTICAL code found in :defn (mass*2 = #{expectation.score})"
    else
      "Similar code found in :defn (mass = #{expectation.mass})"
    end
  end
end

spinel_side_effect = "/tmp/fleek-spinel-source-executed"
raise "Spinel side-effect marker already exists" if File.exist?(spinel_side_effect)

spinel_path = "test/fixtures/spinel_ffi.rb"
spinel = AnalysisRunner.fleek(spinel_path)
LanguageExtensionContract.verify_finding(spinel, LanguageExtensionContract::Finding.new(spinel_path, "6", "NativeDependency"))
spinel_reference = AnalysisRunner.reek(spinel_path)
AnalysisRunner.assert_same_report(spinel, spinel_reference, "Spinel FFI ClassVariable extension")
raise "Spinel source was executed or its require was loaded" if File.exist?(spinel_side_effect)

spinel_flay = AnalysisRunner.fleek_with_check("flay:StructuralDuplication", spinel_path)
raise "unsupported Spinel duplication module implied success" unless spinel_flay[0] == 1 && spinel_flay[1].include?("Status: incomplete")
spinel_flay_reference = AnalysisRunner.flay(spinel_path)
raise "Spinel Flay reference behavior changed" unless spinel_flay_reference[0] == 0 && spinel_flay_reference[1].include?("Total score (lower is better) = 0")
spinel_duplication_path = "test/fixtures/spinel_duplicate.rb"
spinel_duplication = AnalysisRunner.fleek_with_check("flay:StructuralDuplication", spinel_duplication_path)
spinel_duplication_reference = AnalysisRunner.flay(spinel_duplication_path)
LanguageExtensionContract.verify_duplication(spinel_duplication, spinel_duplication_reference, LanguageExtensionContract::Duplication.new(spinel_duplication_path, "similar", 32, 32, 5, 22))
spinel_source = File.read(spinel_duplication_path).lines
reordered_module_path = "/tmp/fleek-spinel-module-after-methods.rb"
reordered_module_source = spinel_source.drop(4).join + "\n" + spinel_source.first(3).join
File.write(reordered_module_path, reordered_module_source)
reordered_module = AnalysisRunner.fleek_with_check("flay:StructuralDuplication", reordered_module_path)
raise "Spinel FFI module after methods was not rejected as incomplete" unless reordered_module[0] == 1 && reordered_module[1].include?("Status: incomplete")

ruby4_path = "test/fixtures/ruby4.rb"
ruby4 = AnalysisRunner.fleek(ruby4_path)
LanguageExtensionContract.verify_finding(ruby4, LanguageExtensionContract::Finding.new(ruby4_path, "3", "RubyFourExample"))
ruby4_reference = AnalysisRunner.reek(ruby4_path)
raise "Ruby 4 reference rejection was mistaken for clean analysis" unless ruby4_reference[0] == 0 && ruby4_reference[2].include?("cannot be processed by Reek")

ruby4_duplication_path = "test/fixtures/ruby4_duplicate.rb"
ruby4_flay = AnalysisRunner.fleek_with_check("flay:StructuralDuplication", ruby4_duplication_path)
ruby4_flay_reference = AnalysisRunner.flay(ruby4_duplication_path)
LanguageExtensionContract.verify_duplication(ruby4_flay, ruby4_flay_reference, LanguageExtensionContract::Duplication.new(ruby4_duplication_path, "similar", 36, 36, 1, 19))
identical_path = "/tmp/fleek-ruby4-identical.rb"
identical_source = File.read(ruby4_duplication_path).gsub("ruby4_first", "ruby4_shared").gsub("ruby4_second", "ruby4_shared").gsub("43", "42")
File.write(identical_path, identical_source)
identical_flay = AnalysisRunner.fleek_with_check("flay:StructuralDuplication", identical_path)
identical_reference = AnalysisRunner.flay(identical_path)
LanguageExtensionContract.verify_duplication(identical_flay, identical_reference, LanguageExtensionContract::Duplication.new(identical_path, "identical", 36, 72, 1, 19))
unsupported_and_path = "/tmp/fleek-ruby4-unsupported-and.rb"
unsupported_and_source = File.read(ruby4_duplication_path).gsub("42\n    &&", "call_13\n    &&").gsub("43\n    &&", "call_13\n    &&")
File.write(unsupported_and_path, unsupported_and_source)
unsupported_and = AnalysisRunner.fleek_with_check("flay:StructuralDuplication", unsupported_and_path)
raise "unsupported Ruby 4 logical-and operands implied successful analysis" unless unsupported_and[0] == 1 && unsupported_and[1].include?("Status: incomplete")
nonfinal_and_path = "/tmp/fleek-ruby4-nonfinal-and.rb"
nonfinal_and_source = File.read(ruby4_duplication_path).gsub("    && true\nend", "    && true\n  call_14\nend")
File.write(nonfinal_and_path, nonfinal_and_source)
nonfinal_and = AnalysisRunner.fleek_with_check("flay:StructuralDuplication", nonfinal_and_path)
raise "non-final Ruby 4 logical-and was not rejected as incomplete" unless nonfinal_and[0] == 1 && nonfinal_and[1].include?("Status: incomplete")

suppressed_path = "test/fixtures/ruby4_suppressed.rb"
suppressed = AnalysisRunner.fleek(suppressed_path)
raise "Ruby 4 suppression comment was not retained" unless suppressed[0] == 0 && !suppressed[1].include?("ClassVariable:")

puts "Language extension contract: pass"
