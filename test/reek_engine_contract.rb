require_relative "reek_findings"

# Compares detectors migrated to the ported Reek context engine with pinned Reek 6.6.0.
class ReekEngineContract
  ROOT = "test/fixtures/reek_engine"
  CASES = [
    ["IrresponsibleModule", "#{ROOT}/irresponsible_module.rb"],
    ["IrresponsibleModule", "#{ROOT}/irresponsible_module_single.rb"],
    ["TooManyStatements", "#{ROOT}/too_many_statements.rb"],
    ["NestedIterators", "#{ROOT}/nested_iterators.rb"],
    ["FeatureEnvy", "#{ROOT}/feature_envy.rb"],
    ["UtilityFunction", "#{ROOT}/utility_function.rb"],
    ["NilCheck", "#{ROOT}/nil_check.rb"],
    ["DuplicateMethodCall", "#{ROOT}/duplicate_method_call.rb"],
    ["ControlParameter", "#{ROOT}/control_parameter.rb"],
    ["UnusedParameters", "#{ROOT}/unused_parameters.rb"],
    ["BooleanParameter", "#{ROOT}/parameter_lists.rb"],
    ["LongParameterList", "#{ROOT}/parameter_lists.rb"],
    ["LongYieldList", "#{ROOT}/parameter_lists.rb"],
    ["ModuleInitialize", "#{ROOT}/module_sizes.rb"],
    ["TooManyConstants", "#{ROOT}/module_sizes.rb"],
    ["TooManyInstanceVariables", "#{ROOT}/module_sizes.rb"],
    ["TooManyMethods", "#{ROOT}/module_sizes.rb"],
    ["Attribute", "#{ROOT}/class_api.rb"],
    ["InstanceVariableAssumption", "#{ROOT}/class_api.rb"],
    ["SubclassedFromCoreClass", "#{ROOT}/class_api.rb"],
    ["MissingSafeMethod", "#{ROOT}/class_api.rb"],
    ["ManualDispatch", "#{ROOT}/class_api.rb"],
    ["RepeatedConditional", "#{ROOT}/conditionals_and_clumps.rb"],
    ["DataClump", "#{ROOT}/conditionals_and_clumps.rb"],
    ["UncommunicativeMethodName", "#{ROOT}/names.rb"],
    ["UncommunicativeModuleName", "#{ROOT}/names.rb"],
    ["UncommunicativeParameterName", "#{ROOT}/names.rb"],
    ["UncommunicativeVariableName", "#{ROOT}/names.rb"]
  ].freeze
  OUTPUT = "/tmp/fleek-reek-engine"
  # Runs "$0" with the remaining arguments, writing stdout to $1 and stderr to $1.err.
  REDIRECT = 'out="$1"; shift; exec "$0" "$@" > "$out" 2> "$out.err"'

  def self.verify
    # to_s: Spinel 2026.09.12 drops untyped nested-array elements from spawn arguments.
    CASES.each_with_index { |item, index| verify_case(item[0].to_s, item[1].to_s, "#{OUTPUT}-#{index}") }
    puts "Reek engine contract: pass (#{CASES.length} cases)"
  end

  # :reek:TooManyStatements
  def self.verify_case(detector, path, output)
    expected = ReekFindings.reference(run_reek(detector, path, output))
    native = run_fleek(detector, path, output)
    raise "#{detector} left #{path} incomplete" unless native.include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
    raise "Reek reported no #{detector} findings for #{path}" if expected.empty?
    actual = ReekFindings.native(native)
    raise "#{detector} differed from Reek for #{path}: #{(expected - actual).inspect} missing, #{(actual - expected).inspect} extra" unless actual == expected
  end

  def self.run_reek(detector, path, output)
    process_id = Process.spawn("sh", "-c", REDIRECT, ENV["BUNDLE"] || "bundle", "#{output}-reference", "exec", "reek", "--no-progress", "--smell", detector, path)
    Process.waitpid2(process_id)
    File.read("#{output}-reference")
  end

  def self.run_fleek(detector, path, output)
    process_id = Process.spawn("sh", "-c", REDIRECT, "build/fleek", "#{output}-actual", "--checks", "reek:#{detector}", path)
    Process.waitpid2(process_id)
    File.read("#{output}-actual")
  end
end

ReekEngineContract.verify
