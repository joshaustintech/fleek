require_relative "analysis_runner"

# Compares the first structural grouping slice with locked Flay output.
class DuplicationProcess
  def self.temporary_path(name)
    "#{ENV["FLEEK_TEMP_ROOT"] || "/tmp"}/#{name}"
  end

  def self.capture_paths(tool)
    OutputPaths.new(temporary_path("#{tool}-duplication-out"), temporary_path("#{tool}-duplication-err"))
  end

  # Describes one source invocation and its optional Fleek arguments.
  Input = Struct.new(:path, :tool, :option, :value)
  # Carries stdout and stderr destinations for one subprocess.
  OutputPaths = Struct.new(:output, :error)
  # Describes the expected output status and required fields.
  OutputExpectation = Struct.new(:status, :fields, :message)
  # Carries one generated CLI input shape and source identity.
  NestedScopeInput = Struct.new(:kind, :levels, :prefix, :method_name)
  # Stores independent reference facts for generated scope variants.
  NestedScopeShape = Struct.new(:mass_offset, :line_offset, :method_body, :failure)
  # Carries expected native and reference reports for one generated input.
  NestedScopeExpectation = Struct.new(:status, :fields, :message, :reference_fields)
  NESTED_SCOPE_SHAPES = {
    "module" => NestedScopeShape.new(30, 6, "", "deep nested Flay module candidates differed"),
    "class" => NestedScopeShape.new(48, 7, "  @entries = @stream.current.list(limit: params[:limit])\n", "64-level nested class candidates differed")
  }
  # Carries scalar paired CLI/reference expectations for class-method fixtures.
  ClassMethodExpectation = Struct.new(:kind, :score, :mass, :second_line, :reference_group, :message, :first_line)
  CLASS_METHOD_EXPECTATIONS = {
    rails_pair: ClassMethodExpectation.new("similar", 48, 48, 9, "Similar code found in :defn (mass = 48)", "Rails-shaped class method parity differed"),
    module_methods: ClassMethodExpectation.new("similar", 48, 48, 9, "Similar code found in :defn (mass = 48)", "module method parity differed"),
    required_parameters: ClassMethodExpectation.new("similar", 48, 48, 8, "Similar code found in :defn (mass = 48)", "required-parameter class method parity differed"),
    optional_parameters: ClassMethodExpectation.new("similar", 52, 52, 9, "Similar code found in :defn (mass = 52)", "optional-parameter class method parity differed"),
    optional_parameter_defaults: ClassMethodExpectation.new("similar", 52, 52, 9, "Similar code found in :defn (mass = 52)", "optional-parameter default parity differed"),
    optional_literal_defaults: ClassMethodExpectation.new("similar", 40, 40, 8, "Similar code found in :defn (mass = 40)", "optional literal default parity differed"),
    parameter_arity: ClassMethodExpectation.new("similar", 48, 48, 9, "Similar code found in :defn (mass = 48)", "parameter-arity class method parity differed"),
    parameter_names: ClassMethodExpectation.new("similar", 48, 48, 9, "Similar code found in :defn (mass = 48)", "parameter-name class method parity differed"),
    conditionals: ClassMethodExpectation.new("similar", 62, 62, 14, "Similar code found in :defn (mass = 62)", "conditional class method parity differed"),
    unless_branches: ClassMethodExpectation.new("similar", 62, 62, 14, "Similar code found in :defn (mass = 62)", "unless class method parity differed"),
    conditional_return: ClassMethodExpectation.new("similar", 44, 44, 10, "Similar code found in :defn (mass = 44)", "conditional return class method parity differed"),
    or_expression: ClassMethodExpectation.new("similar", 34, 34, 12, "Similar code found in :defn (mass = 34)", "class-method OR expression parity differed"),
    local_writes: ClassMethodExpectation.new("similar", 38, 38, 10, "Similar code found in :defn (mass = 38)", "local-write class method parity differed"),
    local_write_names: ClassMethodExpectation.new("similar", 42, 42, 20, "Similar code found in :defn (mass = 42)", "local-write identity parity differed"),
    candidate_capacity: ClassMethodExpectation.new("similar", 62, 62, 31, "Similar code found in :defn (mass = 62)", "class-method candidate capacity parity differed", 19),
    identical: ClassMethodExpectation.new("identical", 64, 32, 19, "IDENTICAL code found in :defn (mass*2 = 64)", "identical class method group changed")
  }

  def self.run(input)
    path, tool, option, value = input.to_a
    return run_fleek(path, option, value) if tool == "fleek"
    return run_flay_with_mass(path, value) if option == "--mass"
    return run_flay_with_liberal(path) if option == "--liberal"
    run_flay(path)
  end

  # :reek:TooManyStatements
  def self.nested_scope_source(input)
    kind = input.kind
    prefix = input.prefix
    levels = input.levels
    openings = String.new
    closings = String.new
    levels.times do |index|
      openings << "#{kind} #{prefix}#{index}\n"
      closings << "end\n"
    end
    shape = NESTED_SCOPE_SHAPES.fetch(kind)
    openings + "def #{input.method_name}\n  @heading = \"#{prefix}\"\n  @stream = Stream.open(params[:token])\n#{shape.method_body}  render \"#{prefix}\", status: :unprocessable_entity\nend\n" + closings
  end

  # :reek:TooManyStatements
  def self.nested_scope_expectation(input, path)
    kind = input.kind
    levels = input.levels
    shape = NESTED_SCOPE_SHAPES.fetch(kind)
    scope_mass = 2 * levels
    mass = scope_mass + shape.mass_offset
    second_line = scope_mass + shape.line_offset
    fields = ["node=\"#{kind}\" kind=\"similar\" locations=\"#{path}:1,#{path}:#{second_line}\" mass=#{mass} score=#{mass}", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
    reference_fields = ["Similar code found in :#{kind} (mass = #{mass})", "#{path}:1", "#{path}:#{second_line}"]
    NestedScopeExpectation.new(2, fields, shape.failure, reference_fields)
  end

  # :reek:TooManyStatements
  def self.verify_nested_scope_depth(input)
    kind = input.kind
    levels = input.levels
    path = temporary_path("fleek-generated-#{kind}-depth-#{levels}.rb")
    second = NestedScopeInput.new(kind, levels, "Right", "beta")
    File.write(path, nested_scope_source(input) + nested_scope_source(second))
    actual = run(Input.new(path, "fleek", ""))
    reference = run(Input.new(path, "flay", ""))
    expectation = nested_scope_expectation(input, path)
    actual_output = actual[1]
    reference_output = reference[1]
    verify(actual[0] == expectation.status && includes_all?(actual_output, expectation.fields), "#{expectation.message}: #{actual_output} #{actual[2]}")
    verify(reference[0] == 0 && includes_all?(reference_output, expectation.reference_fields), "#{levels}-level Flay #{kind} report differed: #{reference_output}")
  ensure
    File.delete(path) if path && File.file?(path)
  end

  # :reek:TooManyStatements
  def self.run_fleek(path, option, value)
    paths = capture_paths("fleek")
    output = paths.output
    error = paths.error
    process_id = if option.empty?
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", path, out: output, err: error)
                 elsif option == "--mass"
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", "--mass", value.to_s, path, out: output, err: error)
                 else
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", option, path, out: output, err: error)
                 end
    AnalysisRunner.observe(process_id, output, error)
  end

  def self.run_flay(path)
    run_flay_reference("single", [path])
  end

  def self.run_flay_with_mass(path, mass)
    run_flay_reference("mass-#{mass}", ["--mass", mass.to_s, path])
  end

  def self.run_flay_with_liberal(path)
    run_flay_reference("liberal", ["--liberal", path])
  end

  def self.run_fleek_pair(first, second)
    run_fleek_sources(first, second, "")
  end

  # :reek:TooManyStatements
  def self.run_fleek_sources(first, second, third)
    paths = capture_paths("fleek")
    output = paths.output
    error = paths.error
    process_id = if third.empty?
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", first, second, out: output, err: error)
                 else
                   Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", first, second, third, out: output, err: error)
                 end
    AnalysisRunner.observe(process_id, output, error)
  end

  def self.run_flay_pair(first, second)
    run_flay_reference("pair", [first, second])
  end

  def self.run_flay_reference(kind, arguments)
    verify_flay_source_paths(kind, *arguments)
    bundle = ENV["BUNDLE"] || "bundle"
    run_reference(flay_reference_key(kind, arguments)) { run_flay_process(bundle, arguments) }
  end

  def self.flay_reference_key(kind, arguments)
    reference_key(kind, arguments.map { |argument| "#{argument.length}:#{argument}" }.join)
  end

  def self.run_flay_process(bundle, arguments)
    paths = capture_paths("flay")
    process_id = spawn_flay(bundle, arguments, paths)
    AnalysisRunner.observe(process_id, paths.output, paths.error)
  end

  # :reek:TooManyStatements
  def self.spawn_flay(bundle, arguments, paths)
    count = arguments.length
    first = arguments[0]
    second = arguments[1]
    third = arguments[2]
    output = paths.output
    error = paths.error
    return Process.spawn(bundle, "exec", "flay", first, out: output, err: error) if count == 1
    return Process.spawn(bundle, "exec", "flay", first, second, out: output, err: error) if count == 2

    Process.spawn(bundle, "exec", "flay", first, second, third, out: output, err: error)
  end

  # :reek:TooManyStatements
  def self.run_reference(key)
    cache_path = reference_cache_path(key)
    if cache_path && File.file?("#{cache_path}.status")
      cached = read_reference_cache(cache_path)
      return cached.first(3) if cached[3] == key
    end

    result = yield
    write_reference_cache(cache_path, result + [key]) if cache_path
    result
  end

  def self.reference_key(kind, first, second = "")
    "#{kind}-#{first.length}:#{first}-#{second.length}:#{second}"
  end

  def self.verify_flay_source_paths(kind, *paths)
    invalid = paths.select { |path| !path.is_a?(String) || path.empty? }
    verify(invalid.empty?, "Flay #{kind} input path was empty: #{paths.inspect}; caller=#{caller(1, 3).join(' <- ')}")
  end

  def self.verify_reference_cache_key_boundaries
    first = reference_key("pair", "a-b", "c")
    second = reference_key("pair", "a", "b-c")
    verify(first != second, "Flay reference cache keys ignored argument boundaries")
  end

  def self.reference_cache_path(key)
    directory = ENV["FLEEK_REFERENCE_CACHE"]
    return unless directory

    digest = key.each_byte.reduce(2_166_136_261) { |value, byte| ((value ^ byte) * 16_777_619) & 4_294_967_295 }
    "#{directory}/#{digest}"
  end

  def self.read_reference_cache(path)
    status_path = "#{path}.status"
    output_path = "#{path}.out"
    error_path = "#{path}.err"
    key_path = "#{path}.key"
    [Integer(File.read(status_path), 10), File.read(output_path), File.read(error_path), File.read(key_path)]
  end

  # :reek:TooManyStatements
  def self.write_reference_cache(path, result)
    status_path = "#{path}.status"
    output_path = "#{path}.out"
    error_path = "#{path}.err"
    key_path = "#{path}.key"
    status = result[0].to_s
    File.delete(status_path) if File.file?(status_path)
    File.write(output_path, result[1])
    File.write(error_path, result[2])
    File.write(key_path, result[3])
    File.write(status_path, status)
  end

  def self.run_fleek_pair_with_missing(first, second, missing)
    run_fleek_sources(first, second, missing)
  end

  def self.run_fleek_with_nested(first, second, nested)
    run_fleek_sources(first, second, nested)
  end

  # :reek:ControlParameter
  def self.verify(condition, message)
    raise message unless condition
  end

  def self.includes_all?(output, fields)
    fields.all? { |field| output.include?(field) }
  end

  def self.verify_output(observation, expectation)
    message = expectation.message
    verify(observation[0] == expectation.status, "#{message}: exit status differed")
    expectation.fields.each { |field| verify(observation[1].index(field) != nil, "#{message}: missing #{field}") }
  end

  def self.verify_class_method_pair(path, second_line, description)
    actual = run(Input.new(path, "fleek", ""))
    reference = run(Input.new(path, "flay", ""))
    verify_output(reference, OutputExpectation.new(0, ["Similar code found in :defn (mass = 32)", "#{path}:2", "#{path}:#{second_line}"], "#{description} Flay reference changed"))
    verify_output(actual, OutputExpectation.new(2, ["Status: findings", "#{path}:2,#{path}:#{second_line}", "mass=32 score=32"], "#{description} candidates were not analyzed"))
  end

  def self.class_method_actual_expectation(path, expectation)
    kind = expectation.kind
    score = expectation.score
    mass = expectation.mass
    line = expectation.second_line
    OutputExpectation.new(2, ["kind=\"#{kind}\"", "locations=\"#{path}:#{expectation.first_line || 2},#{path}:#{line}\"", "mass=#{mass} score=#{score}", "direct methods or one direct class under a sole nested-module chain", "positional parameters with supported literal defaults", "bounded case/when/if/else/unless branches", "boolean AND/OR expressions", "yield and return expressions with supported values", "local-variable assignments", "Total duplication score: #{score}"], expectation.message)
  end

  def self.class_method_reference_expectation(path, expectation)
    line = expectation.second_line
    score = expectation.score
    fields = [expectation.reference_group, "#{path}:#{expectation.first_line || 2}", "#{path}:#{line}", "Total score (lower is better) = #{score}"]
    OutputExpectation.new(0, fields, expectation.message)
  end

  def self.verify_class_method_parity(path, expectation_name)
    expectation = CLASS_METHOD_EXPECTATIONS.fetch(expectation_name)
    actual = run(Input.new(path, "fleek", ""))
    reference = run(Input.new(path, "flay", ""))
    verify_output(actual, class_method_actual_expectation(path, expectation))
    verify_output(reference, class_method_reference_expectation(path, expectation))
  end

  def self.verify_class_method_no_group(path, description = "optional-parameter count mismatch was grouped")
    actual = run(Input.new(path, "fleek", ""))
    reference = run(Input.new(path, "flay", ""))
    verify_output(actual, OutputExpectation.new(0, ["Total duplication score: 0", "Status: complete"], description))
    verify_output(reference, OutputExpectation.new(0, ["Total score (lower is better) = 0"], "Flay grouped mismatched optional-parameter counts"))
  end
end

DuplicationProcess.verify_reference_cache_key_boundaries

similar_path = "test/fixtures/duplication_methods.rb"
similar = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "fleek", ""))
reference = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "flay", ""))
reference_group = reference[1].include?("Similar code found in :defn (mass = 32)")
reference_locations = reference[1].include?("#{similar_path}:1") && reference[1].include?("#{similar_path}:18")
DuplicationProcess.verify(reference[0] == 0, "reference exit differed: #{reference[0]}")
DuplicationProcess.verify(reference_group && reference_locations && reference[1].include?("Total score (lower is better) = 32"), "reference did not select the expected similar method group")
similar_group = similar[1].include?("Group: check=\"flay:StructuralDuplication\" node=\"defn\" kind=\"similar\"")
similar_locations = similar[1].include?("locations=\"#{similar_path}:1,#{similar_path}:18\"")
similar_fields = similar[1].include?("mass=32 score=32") && similar[1].include?("Total duplication score: 32") && similar[1].include?("File duplication score: \"#{similar_path}\" score=32")
similar_state = similar[1].include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded") && similar[1].include?("Status: findings")
DuplicationProcess.verify(similar[0] == 2 && similar_group && similar_locations && similar_fields && similar_state && similar[2].empty?, "similar method group report differed")

different_path = "test/fixtures/duplication_different_shapes.rb"
different = DuplicationProcess.run(DuplicationProcess::Input.new(different_path, "fleek", ""))
different_reference = DuplicationProcess.run(DuplicationProcess::Input.new(different_path, "flay", ""))
different_reports_clean = different[0] == 0 && different[1].include?("Total duplication score: 0") && different[1].include?("File duplication score: \"#{different_path}\" score=0") && different[1].include?("Status: complete")
different_reference_clean = different_reference[0] == 0 && different_reference[1].include?("Total score (lower is better) = 0")
DuplicationProcess.verify(different_reports_clean && different_reference_clean, "different method shapes were grouped")

argument_calls_path = "test/fixtures/duplication_methods_call_arguments.rb"
argument_calls = DuplicationProcess.run(DuplicationProcess::Input.new(argument_calls_path, "fleek", "--mass", 3))
argument_calls_reference = DuplicationProcess.run(DuplicationProcess::Input.new(argument_calls_path, "flay", "--mass", 3))
argument_calls_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{argument_calls_path}:1,#{argument_calls_path}:7\" mass=16 score=16",
  "Total duplication score: 16", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
argument_calls_reference_fields = ["Similar code found in :defn (mass = 16)", "#{argument_calls_path}:1", "#{argument_calls_path}:7", "Total score (lower is better) = 16"]
DuplicationProcess.verify_output(argument_calls_reference, DuplicationProcess::OutputExpectation.new(0, argument_calls_reference_fields,
  "Flay argument-call method reference changed"))
DuplicationProcess.verify_output(argument_calls, DuplicationProcess::OutputExpectation.new(2, argument_calls_fields,
  "top-level methods with argument calls differed from Flay"))

required_parameters_path = "test/fixtures/duplication_methods_required_parameters.rb"
required_parameters = DuplicationProcess.run(DuplicationProcess::Input.new(required_parameters_path, "fleek", "--mass", 3))
required_parameters_reference = DuplicationProcess.run(DuplicationProcess::Input.new(required_parameters_path, "flay", "--mass", 3))
required_parameters_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{required_parameters_path}:1,#{required_parameters_path}:6\" mass=14 score=14",
  "Total duplication score: 14", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
required_parameters_reference_fields = ["Similar code found in :defn (mass = 14)", "#{required_parameters_path}:1", "#{required_parameters_path}:6", "Total score (lower is better) = 14"]
DuplicationProcess.verify_output(required_parameters_reference, DuplicationProcess::OutputExpectation.new(0, required_parameters_reference_fields,
  "Flay required-parameter method reference changed"))
DuplicationProcess.verify_output(required_parameters, DuplicationProcess::OutputExpectation.new(2, required_parameters_fields,
  "top-level required-parameter methods differed from Flay"))

required_arities_path = "test/fixtures/duplication_methods_required_parameter_arities.rb"
required_arities = DuplicationProcess.run(DuplicationProcess::Input.new(required_arities_path, "fleek", "--mass", 3))
required_arities_reference = DuplicationProcess.run(DuplicationProcess::Input.new(required_arities_path, "flay", "--mass", 3))
required_arities_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{required_arities_path}:1,#{required_arities_path}:6\" mass=12 score=12",
  "Total duplication score: 12", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
required_arities_reference_fields = ["Similar code found in :defn (mass = 12)", "#{required_arities_path}:1", "#{required_arities_path}:6", "Total score (lower is better) = 12"]
DuplicationProcess.verify_output(required_arities_reference, DuplicationProcess::OutputExpectation.new(0, required_arities_reference_fields,
  "Flay required-arity method reference changed"))
DuplicationProcess.verify_output(required_arities, DuplicationProcess::OutputExpectation.new(2, required_arities_fields,
  "top-level methods with different required arities differed from Flay"))

optional_parameters_path = "test/fixtures/duplication_methods_optional_parameters.rb"
optional_parameters = DuplicationProcess.run(DuplicationProcess::Input.new(optional_parameters_path, "fleek", "--mass", 3))
optional_parameters_reference = DuplicationProcess.run(DuplicationProcess::Input.new(optional_parameters_path, "flay", "--mass", 3))
optional_parameters_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{optional_parameters_path}:1,#{optional_parameters_path}:8\" mass=52 score=52",
  "Total duplication score: 52", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
optional_parameters_reference_fields = ["Similar code found in :defn (mass = 52)", "#{optional_parameters_path}:1", "#{optional_parameters_path}:8", "Total score (lower is better) = 52"]
DuplicationProcess.verify_output(optional_parameters_reference, DuplicationProcess::OutputExpectation.new(0, optional_parameters_reference_fields,
  "Flay optional-parameter method reference changed"))
DuplicationProcess.verify_output(optional_parameters, DuplicationProcess::OutputExpectation.new(2, optional_parameters_fields,
  "top-level optional-parameter methods differed from Flay"))

optional_defaults_path = "test/fixtures/duplication_methods_optional_parameter_defaults.rb"
optional_defaults = DuplicationProcess.run(DuplicationProcess::Input.new(optional_defaults_path, "fleek", "--mass", 3))
optional_defaults_reference = DuplicationProcess.run(DuplicationProcess::Input.new(optional_defaults_path, "flay", "--mass", 3))
optional_defaults_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{optional_defaults_path}:1,#{optional_defaults_path}:8\" mass=52 score=52",
  "Total duplication score: 52", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
optional_defaults_reference_fields = ["Similar code found in :defn (mass = 52)", "#{optional_defaults_path}:1", "#{optional_defaults_path}:8", "Total score (lower is better) = 52"]
DuplicationProcess.verify_output(optional_defaults_reference, DuplicationProcess::OutputExpectation.new(0, optional_defaults_reference_fields,
  "Flay optional-default method reference changed"))
DuplicationProcess.verify_output(optional_defaults, DuplicationProcess::OutputExpectation.new(2, optional_defaults_fields,
  "top-level methods with different optional defaults differed from Flay"))

conditionals_path = "test/fixtures/duplication_methods_conditionals.rb"
conditionals = DuplicationProcess.run(DuplicationProcess::Input.new(conditionals_path, "fleek", "--mass", 3))
conditionals_reference = DuplicationProcess.run(DuplicationProcess::Input.new(conditionals_path, "flay", "--mass", 3))
conditionals_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{conditionals_path}:1,#{conditionals_path}:13\" mass=62 score=62",
  "Total duplication score: 62", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
conditionals_reference_fields = ["Similar code found in :defn (mass = 62)", "#{conditionals_path}:1", "#{conditionals_path}:13", "Total score (lower is better) = 62"]
DuplicationProcess.verify_output(conditionals_reference, DuplicationProcess::OutputExpectation.new(0, conditionals_reference_fields,
  "Flay conditional method reference changed"))
DuplicationProcess.verify_output(conditionals, DuplicationProcess::OutputExpectation.new(2, conditionals_fields,
  "top-level methods with conditionals differed from Flay"))

while_control_path = "test/fixtures/duplication_methods_while_control.rb"
while_control = DuplicationProcess.run(DuplicationProcess::Input.new(while_control_path, "fleek", "--mass", 3))
while_control_reference = DuplicationProcess.run(DuplicationProcess::Input.new(while_control_path, "flay", "--mass", 3))
while_control_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{while_control_path}:1,#{while_control_path}:7\" mass=10 score=10",
  "Total duplication score: 10", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
while_control_reference_fields = ["Similar code found in :defn (mass = 10)", "#{while_control_path}:1", "#{while_control_path}:7", "Total score (lower is better) = 10"]
DuplicationProcess.verify_output(while_control_reference, DuplicationProcess::OutputExpectation.new(0, while_control_reference_fields,
  "Flay while-control method reference changed"))
DuplicationProcess.verify_output(while_control, DuplicationProcess::OutputExpectation.new(2, while_control_fields,
  "top-level methods with while-control loops differed from Flay"))

until_control_path = "test/fixtures/duplication_methods_until_control.rb"
until_control = DuplicationProcess.run(DuplicationProcess::Input.new(until_control_path, "fleek", "--mass", 3))
until_control_reference = DuplicationProcess.run(DuplicationProcess::Input.new(until_control_path, "flay", "--mass", 3))
until_control_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{until_control_path}:1,#{until_control_path}:7\" mass=10 score=10",
  "Total duplication score: 10", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
until_control_reference_fields = ["Similar code found in :defn (mass = 10)", "#{until_control_path}:1", "#{until_control_path}:7", "Total score (lower is better) = 10"]
DuplicationProcess.verify_output(until_control_reference, DuplicationProcess::OutputExpectation.new(0, until_control_reference_fields,
  "Flay until-control method reference changed"))
DuplicationProcess.verify_output(until_control, DuplicationProcess::OutputExpectation.new(2, until_control_fields,
  "top-level methods with until-control loops differed from Flay"))

local_writes_path = "test/fixtures/duplication_methods_local_writes.rb"
local_writes = DuplicationProcess.run(DuplicationProcess::Input.new(local_writes_path, "fleek", "--mass", 3))
local_writes_reference = DuplicationProcess.run(DuplicationProcess::Input.new(local_writes_path, "flay", "--mass", 3))
local_writes_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{local_writes_path}:1,#{local_writes_path}:9\" mass=38 score=38",
  "Total duplication score: 38", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
local_writes_reference_fields = ["Similar code found in :defn (mass = 38)", "#{local_writes_path}:1", "#{local_writes_path}:9", "Total score (lower is better) = 38"]
DuplicationProcess.verify_output(local_writes_reference, DuplicationProcess::OutputExpectation.new(0, local_writes_reference_fields,
  "Flay local-write method reference changed"))
DuplicationProcess.verify_output(local_writes, DuplicationProcess::OutputExpectation.new(2, local_writes_fields,
  "top-level methods with local writes differed from Flay"))

local_write_names_path = "test/fixtures/duplication_methods_local_write_names.rb"
local_write_names = DuplicationProcess.run(DuplicationProcess::Input.new(local_write_names_path, "fleek", "--mass", 3))
local_write_names_reference = DuplicationProcess.run(DuplicationProcess::Input.new(local_write_names_path, "flay", "--mass", 3))
local_write_names_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{local_write_names_path}:1,#{local_write_names_path}:6\" mass=16 score=16",
  "Total duplication score: 16", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
local_write_names_reference_fields = ["Similar code found in :defn (mass = 16)", "#{local_write_names_path}:1", "#{local_write_names_path}:6", "Total score (lower is better) = 16"]
DuplicationProcess.verify_output(local_write_names_reference, DuplicationProcess::OutputExpectation.new(0, local_write_names_reference_fields,
  "Flay local-write identity reference changed"))
DuplicationProcess.verify_output(local_write_names, DuplicationProcess::OutputExpectation.new(2, local_write_names_fields,
  "top-level local-write identity differed from Flay"))

or_path = "test/fixtures/duplication_methods_or.rb"
or_methods = DuplicationProcess.run(DuplicationProcess::Input.new(or_path, "fleek", "--mass", 3))
or_reference = DuplicationProcess.run(DuplicationProcess::Input.new(or_path, "flay", "--mass", 3))
or_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{or_path}:1,#{or_path}:11\" mass=34 score=34",
  "Total duplication score: 34", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
or_reference_fields = ["Similar code found in :defn (mass = 34)", "#{or_path}:1", "#{or_path}:11", "Total score (lower is better) = 34"]
DuplicationProcess.verify_output(or_reference, DuplicationProcess::OutputExpectation.new(0, or_reference_fields,
  "Flay OR-expression method reference changed"))
DuplicationProcess.verify_output(or_methods, DuplicationProcess::OutputExpectation.new(2, or_fields,
  "top-level methods with OR expressions differed from Flay"))

and_path = "test/fixtures/duplication_methods_and.rb"
and_methods = DuplicationProcess.run(DuplicationProcess::Input.new(and_path, "fleek", "--mass", 3))
and_reference = DuplicationProcess.run(DuplicationProcess::Input.new(and_path, "flay", "--mass", 3))
and_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{and_path}:1,#{and_path}:11\" mass=34 score=34",
  "Total duplication score: 34", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
and_reference_fields = ["Similar code found in :defn (mass = 34)", "#{and_path}:1", "#{and_path}:11", "Total score (lower is better) = 34"]
DuplicationProcess.verify_output(and_reference, DuplicationProcess::OutputExpectation.new(0, and_reference_fields,
  "Flay AND-expression method reference changed"))
DuplicationProcess.verify_output(and_methods, DuplicationProcess::OutputExpectation.new(2, and_fields,
  "top-level methods with AND expressions differed from Flay"))

case_expression_path = "test/fixtures/duplication_methods_case_expression.rb"
case_expression = DuplicationProcess.run(DuplicationProcess::Input.new(case_expression_path, "fleek", "--mass", 3))
case_expression_reference = DuplicationProcess.run(DuplicationProcess::Input.new(case_expression_path, "flay", "--mass", 3))
case_expression_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{case_expression_path}:1,#{case_expression_path}:12\" mass=34 score=34",
  "Total duplication score: 34", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
case_expression_reference_fields = ["Similar code found in :defn (mass = 34)", "#{case_expression_path}:1", "#{case_expression_path}:12", "Total score (lower is better) = 34"]
DuplicationProcess.verify_output(case_expression_reference, DuplicationProcess::OutputExpectation.new(0, case_expression_reference_fields,
  "Flay case-expression method reference changed"))
DuplicationProcess.verify_output(case_expression, DuplicationProcess::OutputExpectation.new(2, case_expression_fields,
  "top-level methods with case expressions differed from Flay"))

case_condition_lengths_path = "test/fixtures/duplication_methods_case_condition_lengths.rb"
case_condition_lengths = DuplicationProcess.run(DuplicationProcess::Input.new(case_condition_lengths_path, "fleek", "--mass", 3))
case_condition_lengths_reference = DuplicationProcess.run(DuplicationProcess::Input.new(case_condition_lengths_path, "flay", "--mass", 3))
DuplicationProcess.verify_output(case_condition_lengths_reference, DuplicationProcess::OutputExpectation.new(0,
  ["Total score (lower is better) = 0"], "Flay differing case-condition lengths were grouped"))
DuplicationProcess.verify_output(case_condition_lengths, DuplicationProcess::OutputExpectation.new(0,
  ["Total duplication score: 0", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: complete"],
  "differing case-condition lengths were grouped"))

float_expression_path = "test/fixtures/duplication_methods_float_expression.rb"
float_expression = DuplicationProcess.run(DuplicationProcess::Input.new(float_expression_path, "fleek", "--mass", 3))
float_expression_reference = DuplicationProcess.run(DuplicationProcess::Input.new(float_expression_path, "flay", "--mass", 3))
float_expression_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{float_expression_path}:1,#{float_expression_path}:5\" mass=12 score=12",
  "Total duplication score: 12", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
float_expression_reference_fields = ["Similar code found in :defn (mass = 12)", "#{float_expression_path}:1", "#{float_expression_path}:5", "Total score (lower is better) = 12"]
DuplicationProcess.verify_output(float_expression_reference, DuplicationProcess::OutputExpectation.new(0, float_expression_reference_fields,
  "Flay float-expression method reference changed"))
DuplicationProcess.verify_output(float_expression, DuplicationProcess::OutputExpectation.new(2, float_expression_fields,
  "top-level methods with float literals differed from Flay"))

nil_expression_path = "test/fixtures/duplication_methods_nil_expression.rb"
nil_expression = DuplicationProcess.run(DuplicationProcess::Input.new(nil_expression_path, "fleek", "--mass", 3))
nil_expression_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nil_expression_path, "flay", "--mass", 3))
nil_expression_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{nil_expression_path}:1,#{nil_expression_path}:5\" mass=8 score=8",
  "Total duplication score: 8", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
nil_expression_reference_fields = ["Similar code found in :defn (mass = 8)", "#{nil_expression_path}:1", "#{nil_expression_path}:5", "Total score (lower is better) = 8"]
DuplicationProcess.verify_output(nil_expression_reference, DuplicationProcess::OutputExpectation.new(0, nil_expression_reference_fields,
  "Flay nil-expression method reference changed"))
DuplicationProcess.verify_output(nil_expression, DuplicationProcess::OutputExpectation.new(2, nil_expression_fields,
  "top-level methods with nil literals differed from Flay"))

unless_expression_path = "test/fixtures/duplication_methods_unless_expression.rb"
unless_expression = DuplicationProcess.run(DuplicationProcess::Input.new(unless_expression_path, "fleek", "--mass", 3))
unless_expression_reference = DuplicationProcess.run(DuplicationProcess::Input.new(unless_expression_path, "flay", "--mass", 3))
unless_expression_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{unless_expression_path}:1,#{unless_expression_path}:9\" mass=16 score=16",
  "Total duplication score: 16", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
unless_expression_reference_fields = ["Similar code found in :defn (mass = 16)", "#{unless_expression_path}:1", "#{unless_expression_path}:9", "Total score (lower is better) = 16"]
DuplicationProcess.verify_output(unless_expression_reference, DuplicationProcess::OutputExpectation.new(0, unless_expression_reference_fields,
  "Flay unless-expression method reference changed"))
DuplicationProcess.verify_output(unless_expression, DuplicationProcess::OutputExpectation.new(2, unless_expression_fields,
  "top-level methods with unless expressions differed from Flay"))

range_expression_path = "test/fixtures/duplication_methods_range_expression.rb"
range_expression = DuplicationProcess.run(DuplicationProcess::Input.new(range_expression_path, "fleek", "--mass", 3))
range_expression_reference = DuplicationProcess.run(DuplicationProcess::Input.new(range_expression_path, "flay", "--mass", 3))
range_expression_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{range_expression_path}:1,#{range_expression_path}:5\" mass=10 score=10",
  "Total duplication score: 10", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
range_expression_reference_fields = ["Similar code found in :defn (mass = 10)", "#{range_expression_path}:1", "#{range_expression_path}:5", "Total score (lower is better) = 10"]
DuplicationProcess.verify_output(range_expression_reference, DuplicationProcess::OutputExpectation.new(0, range_expression_reference_fields,
  "Flay range-expression method reference changed"))
DuplicationProcess.verify_output(range_expression, DuplicationProcess::OutputExpectation.new(2, range_expression_fields,
  "top-level methods with range literals differed from Flay"))

range_operator_path = "test/fixtures/duplication_methods_range_operator.rb"
range_operator = DuplicationProcess.run(DuplicationProcess::Input.new(range_operator_path, "fleek", "--mass", 3))
range_operator_reference = DuplicationProcess.run(DuplicationProcess::Input.new(range_operator_path, "flay", "--mass", 3))
range_operator_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{range_operator_path}:1,#{range_operator_path}:5\" mass=10 score=10",
  "Total duplication score: 10", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
range_operator_reference_fields = ["Similar code found in :defn (mass = 10)", "#{range_operator_path}:1", "#{range_operator_path}:5", "Total score (lower is better) = 10"]
DuplicationProcess.verify_output(range_operator_reference, DuplicationProcess::OutputExpectation.new(0, range_operator_reference_fields,
  "Flay range-operator method reference changed"))
DuplicationProcess.verify_output(range_operator, DuplicationProcess::OutputExpectation.new(2, range_operator_fields,
  "inclusive and exclusive range method candidates were treated as identical"))

conditional_return_path = "test/fixtures/duplication_methods_conditional_return.rb"
conditional_returns = DuplicationProcess.run(DuplicationProcess::Input.new(conditional_return_path, "fleek", "--mass", 3))
conditional_return_reference = DuplicationProcess.run(DuplicationProcess::Input.new(conditional_return_path, "flay", "--mass", 3))
conditional_return_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{conditional_return_path}:1,#{conditional_return_path}:9\" mass=44 score=44",
  "Total duplication score: 44", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
conditional_return_reference_fields = ["Similar code found in :defn (mass = 44)", "#{conditional_return_path}:1", "#{conditional_return_path}:9", "Total score (lower is better) = 44"]
DuplicationProcess.verify_output(conditional_return_reference, DuplicationProcess::OutputExpectation.new(0, conditional_return_reference_fields,
  "Flay conditional-return method reference changed"))
DuplicationProcess.verify_output(conditional_returns, DuplicationProcess::OutputExpectation.new(2, conditional_return_fields,
  "top-level methods with conditional returns differed from Flay"))

array_expression_path = "test/fixtures/duplication_methods_array_expression.rb"
array_expression = DuplicationProcess.run(DuplicationProcess::Input.new(array_expression_path, "fleek", "--mass", 3))
array_expression_reference = DuplicationProcess.run(DuplicationProcess::Input.new(array_expression_path, "flay", "--mass", 3))
array_expression_fields = ["node=\"defn\" kind=\"identical\" locations=\"#{array_expression_path}:1,#{array_expression_path}:5\" mass=38 score=76",
  "Total duplication score: 76", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
array_expression_reference_fields = ["IDENTICAL code found in :defn (mass*2 = 76)", "#{array_expression_path}:1", "#{array_expression_path}:5", "Total score (lower is better) = 76"]
DuplicationProcess.verify_output(array_expression_reference, DuplicationProcess::OutputExpectation.new(0, array_expression_reference_fields,
  "Flay top-level array-expression method reference changed"))
DuplicationProcess.verify_output(array_expression, DuplicationProcess::OutputExpectation.new(2, array_expression_fields,
  "top-level array-expression methods differed from Flay"))

hash_expression_path = "test/fixtures/duplication_methods_hash_expression.rb"
hash_expression = DuplicationProcess.run(DuplicationProcess::Input.new(hash_expression_path, "fleek", "--mass", 3))
hash_expression_reference = DuplicationProcess.run(DuplicationProcess::Input.new(hash_expression_path, "flay", "--mass", 3))
hash_expression_fields = ["node=\"defn\" kind=\"identical\" locations=\"#{hash_expression_path}:1,#{hash_expression_path}:6\" mass=60 score=120",
  "Total duplication score: 120", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
hash_expression_reference_fields = ["IDENTICAL code found in :defn (mass*2 = 120)", "#{hash_expression_path}:1", "#{hash_expression_path}:6", "Total score (lower is better) = 120"]
DuplicationProcess.verify_output(hash_expression_reference, DuplicationProcess::OutputExpectation.new(0, hash_expression_reference_fields,
  "Flay top-level hash-expression method reference changed"))
DuplicationProcess.verify_output(hash_expression, DuplicationProcess::OutputExpectation.new(2, hash_expression_fields,
  "top-level hash-expression methods differed from Flay"))

identical_path = "test/fixtures/duplication_identical.rb"
identical = DuplicationProcess.run(DuplicationProcess::Input.new(identical_path, "fleek", ""))
identical_reference = DuplicationProcess.run(DuplicationProcess::Input.new(identical_path, "flay", ""))
identical_reference_weighted = identical_reference[1].include?("IDENTICAL code found in :defn (mass*2 = 64)") && identical_reference[1].include?("Total score (lower is better) = 64")
identical_fields = ["kind=\"identical\"", "mass=32 score=64", "Total duplication score: 64", "File duplication score: \"#{identical_path}\" score=64"]
identical_report_weighted = identical_fields.all? { |field| identical[1].include?(field) }
DuplicationProcess.verify(identical[0] == 2 && identical_reference_weighted && identical_report_weighted, "identical group multiplier changed")

unsupported_path = "test/fixtures/duplication_unsupported.rb"
unsupported = DuplicationProcess.run(DuplicationProcess::Input.new(unsupported_path, "fleek", ""))
unsupported_state = unsupported[1].include?("Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded") && unsupported[1].include?("Status: incomplete")
DuplicationProcess.verify(unsupported[0] == 1 && unsupported_state && unsupported[2].include?("Partial results may omit Flay candidates"), "unsupported syntax implied complete analysis")

fuzzy = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "fleek", "--fuzzy"))
DuplicationProcess.verify(fuzzy[0] == 1 && fuzzy[2].include?("Unsupported Flay option: \"--fuzzy\""), "unsupported fuzzy request was accepted")

[[15, 2, 32], [16, 2, 32], [17, 0, 0]].each do |threshold, expected_status, expected_score|
  actual = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "fleek", "--mass", threshold))
  reference = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "flay", "--mass", threshold))
  actual_matches = actual[0] == expected_status && actual[1].include?("Total duplication score: #{expected_score}") && actual[1].include?("File duplication score: \"#{similar_path}\" score=#{expected_score}")
  reference_matches = reference[1].include?("Total score (lower is better) = #{expected_score}")
  DuplicationProcess.verify(actual_matches && reference_matches, "mass threshold #{threshold} differed")
end

invalid_mass_values = [nil, "0", "1", "2", "-1", "abc", "2147483648"]
invalid_mass_values.each do |value|
  invalid_mass = DuplicationProcess.run(DuplicationProcess::Input.new(similar_path, "fleek", "--mass", value))
  DuplicationProcess.verify(invalid_mass[0] == 1 && invalid_mass[2].include?("--mass requires an integer from 3 through 2147483647"), "invalid mass setting was accepted: #{value}")
end

first_file = "test/fixtures/duplication_file_a.rb"
second_file = "test/fixtures/duplication_file_b.rb"
cross_file = DuplicationProcess.run_fleek_pair(second_file, first_file)
cross_reference = DuplicationProcess.run_flay_pair(second_file, first_file)
cross_locations = "locations=\"#{first_file}:1,#{second_file}:1\""
cross_reference_locations = ["#{first_file}:1", "#{second_file}:1"]
cross_reference_matches = cross_reference_locations.all? { |location| cross_reference[1].include?(location) } && cross_reference[1].index(cross_reference_locations[0]) < cross_reference[1].index(cross_reference_locations[1])
cross_file_matches = cross_file[0] == 2 && DuplicationProcess.includes_all?(cross_file[1], [cross_locations, "kind=\"identical\"", "Total duplication score: 64", "File duplication score: \"#{first_file}\" score=32", "File duplication score: \"#{second_file}\" score=32"])
DuplicationProcess.verify(cross_file_matches, "cross-file report differed")
DuplicationProcess.verify(cross_reference_matches && cross_file[1].include?(cross_locations), "cross-file locations or ordering differed from Flay")
cross_reference_expectation = DuplicationProcess::OutputExpectation.new(0, ["IDENTICAL code found in :defn (mass*2 = 64)", "Total score (lower is better) = 64"], "cross-file reference differed from Flay")
DuplicationProcess.verify_output(cross_reference, cross_reference_expectation)

partial = DuplicationProcess.run_fleek_pair_with_missing(first_file, second_file, "test/fixtures/missing_duplication.rb")
partial_report = partial[0] == 1 && DuplicationProcess.includes_all?(partial[1], [cross_locations, "test/fixtures/missing_duplication.rb\" scope=failed", "Coverage: 3 selected; 2 analyzed; 1 failed; 0 excluded", "Status: incomplete"])
DuplicationProcess.verify(partial_report, "failed requested file hid remaining cross-file group")

nested_path = "test/fixtures/duplication_nested_scope.rb"
nested = DuplicationProcess.run_fleek_with_nested(first_file, second_file, nested_path)
nested_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_path, "flay", ""))
nested_reference_expectation = DuplicationProcess::OutputExpectation.new(0, ["Similar code found in :defn (mass = 32)", "#{nested_path}:2", "#{nested_path}:19", "Total score (lower is better) = 32"], "nested Flay reference changed")
DuplicationProcess.verify_output(nested_reference, nested_reference_expectation)
nested_fleek_expectation = DuplicationProcess::OutputExpectation.new(1, ["Status: incomplete"], "nested Flay candidates were silently omitted")
DuplicationProcess.verify_output(nested, nested_fleek_expectation)
DuplicationProcess.verify(nested[2].include?("unsupported Flay candidate syntax"), "nested Flay candidates were silently omitted")

class_methods_path = "test/fixtures/duplication_class_methods.rb"
class_methods_with_helper_path = "test/fixtures/duplication_class_methods_with_helper.rb"

rails_pair_path = "test/fixtures/duplication_class_methods_rails_pair.rb"
DuplicationProcess.verify_class_method_parity(rails_pair_path, :rails_pair)

multiple_classes_path = "test/fixtures/duplication_class_methods_across_classes.rb"
multiple_classes_actual = DuplicationProcess.run(DuplicationProcess::Input.new(multiple_classes_path, "fleek", ""))
multiple_classes_reference = DuplicationProcess.run(DuplicationProcess::Input.new(multiple_classes_path, "flay", ""))
multiple_classes_fields = ["kind=\"similar\"", "locations=\"#{multiple_classes_path}:8,#{multiple_classes_path}:17\"", "mass=48 score=48", "Total duplication score: 48", "Status: findings"]
DuplicationProcess.verify_output(multiple_classes_actual, DuplicationProcess::OutputExpectation.new(2, multiple_classes_fields, "class methods across classes were not compared"))
multiple_classes_reference_fields = ["Similar code found in :defn (mass = 48)", "#{multiple_classes_path}:8", "#{multiple_classes_path}:17", "Total score (lower is better) = 48"]
DuplicationProcess.verify_output(multiple_classes_reference, DuplicationProcess::OutputExpectation.new(0, multiple_classes_reference_fields, "Flay class-method group across classes changed"))

cross_class_group_path = "test/fixtures/duplication_class_methods_cross_class_group.rb"
cross_class_group_actual = DuplicationProcess.run(DuplicationProcess::Input.new(cross_class_group_path, "fleek", ""))
cross_class_group_reference = DuplicationProcess.run(DuplicationProcess::Input.new(cross_class_group_path, "flay", ""))
cross_class_group_reference_fields = ["Similar code found in :class (mass = 50)", "#{cross_class_group_path}:1", "#{cross_class_group_path}:10", "Total score (lower is better) = 50"]
DuplicationProcess.verify_output(cross_class_group_reference, DuplicationProcess::OutputExpectation.new(0, cross_class_group_reference_fields, "cross-class Flay group changed"))
cross_class_group_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{cross_class_group_path}:1,#{cross_class_group_path}:10\" mass=50 score=50", "Total duplication score: 50", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(cross_class_group_actual, DuplicationProcess::OutputExpectation.new(2, cross_class_group_actual_fields, "cross-class Flay group differed"))

modules_inside_classes_path = "test/fixtures/duplication_modules_inside_sibling_classes.rb"
modules_inside_classes_actual = DuplicationProcess.run(DuplicationProcess::Input.new(modules_inside_classes_path, "fleek", ""))
modules_inside_classes_reference = DuplicationProcess.run(DuplicationProcess::Input.new(modules_inside_classes_path, "flay", ""))
modules_inside_classes_fields = ["node=\"class\" kind=\"similar\" locations=\"#{modules_inside_classes_path}:1,#{modules_inside_classes_path}:12\" mass=52 score=52", "Total duplication score: 52", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
modules_inside_classes_reference_fields = ["Similar code found in :class (mass = 52)", "#{modules_inside_classes_path}:1", "#{modules_inside_classes_path}:12", "Total score (lower is better) = 52"]
DuplicationProcess.verify_output(modules_inside_classes_actual, DuplicationProcess::OutputExpectation.new(2, modules_inside_classes_fields, "module scopes inside sibling classes differed"))
DuplicationProcess.verify_output(modules_inside_classes_reference, DuplicationProcess::OutputExpectation.new(0, modules_inside_classes_reference_fields, "module scopes inside sibling classes changed in Flay"))

mixed_sibling_scopes_path = "test/fixtures/duplication_class_mixed_sibling_scopes.rb"
mixed_sibling_scopes_actual = DuplicationProcess.run(DuplicationProcess::Input.new(mixed_sibling_scopes_path, "fleek", ""))
mixed_sibling_scopes_reference = DuplicationProcess.run(DuplicationProcess::Input.new(mixed_sibling_scopes_path, "flay", ""))
mixed_sibling_scope_group = "node=\"class\" kind=\"similar\" locations=\"#{mixed_sibling_scopes_path}:2,#{mixed_sibling_scopes_path}:11\" mass=50 score=50"
DuplicationProcess.verify(mixed_sibling_scopes_actual[0] == 1 && mixed_sibling_scopes_actual[1].include?(mixed_sibling_scope_group) &&
  mixed_sibling_scopes_actual[1].include?("Total duplication score: 50") && mixed_sibling_scopes_actual[1].include?("Status: incomplete"),
  "mixed sibling scopes hid the independent Flay class group")
mixed_sibling_scopes_reference_fields = ["Similar code found in :class (mass = 50)", "#{mixed_sibling_scopes_path}:2", "#{mixed_sibling_scopes_path}:11", "Total score (lower is better) = 50"]
DuplicationProcess.verify_output(mixed_sibling_scopes_reference, DuplicationProcess::OutputExpectation.new(0, mixed_sibling_scopes_reference_fields, "mixed sibling scope Flay reference changed"))

nested_class_sibling_path = "test/fixtures/duplication_nested_class_sibling_wrappers.rb"
nested_class_sibling_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nested_class_sibling_path, "fleek", ""))
nested_class_sibling_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_class_sibling_path, "flay", ""))
nested_class_sibling_fields = ["node=\"class\" kind=\"similar\" locations=\"#{nested_class_sibling_path}:2,#{nested_class_sibling_path}:13\" mass=52 score=52", "Total duplication score: 52", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nested_class_sibling_actual, DuplicationProcess::OutputExpectation.new(2, nested_class_sibling_fields, "nested class sibling wrappers differed"))
nested_class_sibling_reference_fields = ["Similar code found in :class (mass = 52)", "#{nested_class_sibling_path}:2", "#{nested_class_sibling_path}:13", "Total score (lower is better) = 52"]
DuplicationProcess.verify_output(nested_class_sibling_reference, DuplicationProcess::OutputExpectation.new(0, nested_class_sibling_reference_fields, "nested class sibling wrapper Flay reference changed"))

cross_scope_group_path = "test/fixtures/duplication_class_cross_scope_group.rb"
cross_scope_group_actual = DuplicationProcess.run(DuplicationProcess::Input.new(cross_scope_group_path, "fleek", ""))
cross_scope_group_reference = DuplicationProcess.run(DuplicationProcess::Input.new(cross_scope_group_path, "flay", ""))
cross_scope_group_fields = ["node=\"class\" kind=\"similar\" locations=\"#{cross_scope_group_path}:1,#{cross_scope_group_path}:11\" mass=50 score=50", "Total duplication score: 50", "Status: findings"]
DuplicationProcess.verify_output(cross_scope_group_actual, DuplicationProcess::OutputExpectation.new(2, cross_scope_group_fields, "nested cross-scope class group differed"))
cross_scope_group_reference_fields = ["Similar code found in :class (mass = 50)", "#{cross_scope_group_path}:1", "#{cross_scope_group_path}:11", "Total score (lower is better) = 50"]
DuplicationProcess.verify_output(cross_scope_group_reference, DuplicationProcess::OutputExpectation.new(0, cross_scope_group_reference_fields, "nested cross-scope Flay group changed"))

multi_method_group_path = "test/fixtures/duplication_class_multi_method_group.rb"
multi_method_group_actual = DuplicationProcess.run(DuplicationProcess::Input.new(multi_method_group_path, "fleek", ""))
multi_method_group_reference = DuplicationProcess.run(DuplicationProcess::Input.new(multi_method_group_path, "flay", ""))
multi_method_group_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{multi_method_group_path}:1,#{multi_method_group_path}:15\" mass=62 score=62", "Total duplication score: 62", "Status: findings"]
DuplicationProcess.verify_output(multi_method_group_actual, DuplicationProcess::OutputExpectation.new(2, multi_method_group_actual_fields, "multi-method Flay class group differed"))
multi_method_group_reference_fields = ["Similar code found in :class (mass = 62)", "#{multi_method_group_path}:1", "#{multi_method_group_path}:15", "Total score (lower is better) = 62"]
DuplicationProcess.verify_output(multi_method_group_reference, DuplicationProcess::OutputExpectation.new(0, multi_method_group_reference_fields, "multi-method Flay class group changed"))

multi_method_module_path = "test/fixtures/duplication_module_multi_method_group.rb"
multi_method_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(multi_method_module_path, "fleek", ""))
multi_method_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(multi_method_module_path, "flay", ""))
multi_method_module_actual_fields = ["node=\"module\" kind=\"similar\" locations=\"#{multi_method_module_path}:1,#{multi_method_module_path}:15\" mass=62 score=62", "Total duplication score: 62", "Status: findings"]
DuplicationProcess.verify_output(multi_method_module_actual, DuplicationProcess::OutputExpectation.new(2, multi_method_module_actual_fields, "multi-method Flay module group differed"))
multi_method_module_reference_fields = ["Similar code found in :module (mass = 62)", "#{multi_method_module_path}:1", "#{multi_method_module_path}:15", "Total score (lower is better) = 62"]
DuplicationProcess.verify_output(multi_method_module_reference, DuplicationProcess::OutputExpectation.new(0, multi_method_module_reference_fields, "multi-method Flay module group changed"))

nested_module_path = "test/fixtures/duplication_nested_module_group.rb"
nested_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nested_module_path, "fleek", ""))
nested_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_module_path, "flay", ""))
nested_module_actual_fields = ["node=\"module\" kind=\"similar\" locations=\"#{nested_module_path}:1,#{nested_module_path}:11\" mass=34 score=34", "Total duplication score: 34", "Status: findings"]
DuplicationProcess.verify_output(nested_module_actual, DuplicationProcess::OutputExpectation.new(2, nested_module_actual_fields, "nested Flay module group differed"))
nested_module_reference_fields = ["Similar code found in :module (mass = 34)", "#{nested_module_path}:1", "#{nested_module_path}:11", "Total score (lower is better) = 34"]
DuplicationProcess.verify_output(nested_module_reference, DuplicationProcess::OutputExpectation.new(0, nested_module_reference_fields, "nested Flay module group changed"))

deep_nested_module_path = "test/fixtures/duplication_deep_nested_module_group.rb"
deep_nested_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(deep_nested_module_path, "fleek", ""))
deep_nested_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(deep_nested_module_path, "flay", ""))
deep_nested_module_actual_fields = ["node=\"module\" kind=\"similar\" locations=\"#{deep_nested_module_path}:1,#{deep_nested_module_path}:13\" mass=36 score=36", "Total duplication score: 36", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(deep_nested_module_actual, DuplicationProcess::OutputExpectation.new(2, deep_nested_module_actual_fields, "deep nested Flay module candidates differed"))
deep_nested_module_reference_fields = ["Similar code found in :module (mass = 36)", "#{deep_nested_module_path}:1", "#{deep_nested_module_path}:13", "Total score (lower is better) = 36"]
DuplicationProcess.verify_output(deep_nested_module_reference, DuplicationProcess::OutputExpectation.new(0, deep_nested_module_reference_fields, "deep nested Flay module group changed"))

eight_level_module_path = "test/fixtures/duplication_eight_level_module_group.rb"
eight_level_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(eight_level_module_path, "fleek", ""))
eight_level_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(eight_level_module_path, "flay", ""))
eight_level_module_fields = ["node=\"module\" kind=\"similar\" locations=\"#{eight_level_module_path}:1,#{eight_level_module_path}:23\" mass=46 score=46", "Total duplication score: 46", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(eight_level_module_actual, DuplicationProcess::OutputExpectation.new(2, eight_level_module_fields, "eight-level Flay module candidates differed"))
eight_level_module_reference_fields = ["Similar code found in :module (mass = 46)", "#{eight_level_module_path}:1", "#{eight_level_module_path}:23", "Total score (lower is better) = 46"]
DuplicationProcess.verify_output(eight_level_module_reference, DuplicationProcess::OutputExpectation.new(0, eight_level_module_reference_fields, "eight-level Flay module group changed"))

nine_level_module_path = "test/fixtures/duplication_nine_level_module_boundary.rb"
nine_level_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nine_level_module_path, "fleek", ""))
nine_level_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nine_level_module_path, "flay", ""))
nine_level_module_fields = ["node=\"module\" kind=\"similar\" locations=\"#{nine_level_module_path}:1,#{nine_level_module_path}:25\" mass=48 score=48", "Total duplication score: 48", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nine_level_module_actual, DuplicationProcess::OutputExpectation.new(2, nine_level_module_fields, "nine-level Flay module candidates differed"))
nine_level_module_reference_fields = ["Similar code found in :module (mass = 48)", "#{nine_level_module_path}:1", "#{nine_level_module_path}:25", "Total score (lower is better) = 48"]
DuplicationProcess.verify_output(nine_level_module_reference, DuplicationProcess::OutputExpectation.new(0, nine_level_module_reference_fields, "ninth-level Flay module group changed"))

ten_level_module_path = "test/fixtures/duplication_ten_level_module_boundary.rb"
ten_level_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(ten_level_module_path, "fleek", ""))
ten_level_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(ten_level_module_path, "flay", ""))
ten_level_module_fields = ["node=\"module\" kind=\"similar\" locations=\"#{ten_level_module_path}:1,#{ten_level_module_path}:27\" mass=50 score=50", "Total duplication score: 50", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(ten_level_module_actual, DuplicationProcess::OutputExpectation.new(2, ten_level_module_fields, "ten-level Flay module candidates differed"))
ten_level_module_reference_fields = ["Similar code found in :module (mass = 50)", "#{ten_level_module_path}:1", "#{ten_level_module_path}:27", "Total score (lower is better) = 50"]
DuplicationProcess.verify_output(ten_level_module_reference, DuplicationProcess::OutputExpectation.new(0, ten_level_module_reference_fields, "ten-level Flay module group changed"))

DuplicationProcess.verify_nested_scope_depth(DuplicationProcess::NestedScopeInput.new("module", 64, "Left", "alpha"))
DuplicationProcess.verify_nested_scope_depth(DuplicationProcess::NestedScopeInput.new("class", 64, "Left", "alpha"))

mixed_scope_kinds_path = "test/fixtures/duplication_mixed_scope_kinds.rb"
mixed_scope_kinds_actual = DuplicationProcess.run(DuplicationProcess::Input.new(mixed_scope_kinds_path, "fleek", ""))
mixed_scope_kinds_reference = DuplicationProcess.run(DuplicationProcess::Input.new(mixed_scope_kinds_path, "flay", ""))
mixed_scope_kinds_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{mixed_scope_kinds_path}:3,#{mixed_scope_kinds_path}:14\" mass=48 score=48", "Total duplication score: 48", "Status: findings"]
mixed_scope_kinds_reference_fields = ["Similar code found in :defn (mass = 48)", "#{mixed_scope_kinds_path}:3", "#{mixed_scope_kinds_path}:14", "Total score (lower is better) = 48"]
DuplicationProcess.verify_output(mixed_scope_kinds_actual, DuplicationProcess::OutputExpectation.new(2, mixed_scope_kinds_fields, "mixed class and module scopes were grouped incorrectly"))
DuplicationProcess.verify(!mixed_scope_kinds_actual[1].include?("node=\"class\""), "different class and module scope shapes formed a class group")
DuplicationProcess.verify_output(mixed_scope_kinds_reference, DuplicationProcess::OutputExpectation.new(0, mixed_scope_kinds_reference_fields, "mixed scope Flay reference changed"))

namespace_class_modules_path = "test/fixtures/duplication_namespace_classes_containing_modules.rb"
namespace_class_modules_actual = DuplicationProcess.run(DuplicationProcess::Input.new(namespace_class_modules_path, "fleek", ""))
namespace_class_modules_reference = DuplicationProcess.run(DuplicationProcess::Input.new(namespace_class_modules_path, "flay", ""))
namespace_class_modules_fields = ["node=\"module\" kind=\"similar\" locations=\"#{namespace_class_modules_path}:1,#{namespace_class_modules_path}:14\" mass=54 score=54", "Total duplication score: 54", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
namespace_class_modules_reference_fields = ["Similar code found in :module (mass = 54)", "#{namespace_class_modules_path}:1", "#{namespace_class_modules_path}:14", "Total score (lower is better) = 54"]
DuplicationProcess.verify_output(namespace_class_modules_actual, DuplicationProcess::OutputExpectation.new(2, namespace_class_modules_fields, "namespace class-with-module scope parity differed"))
DuplicationProcess.verify_output(namespace_class_modules_reference, DuplicationProcess::OutputExpectation.new(0, namespace_class_modules_reference_fields, "namespace class-with-module Flay reference changed"))

nested_namespace_class_path = "test/fixtures/duplication_nested_namespace_class_group.rb"
nested_namespace_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nested_namespace_class_path, "fleek", ""))
nested_namespace_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_namespace_class_path, "flay", ""))
nested_namespace_class_fields = ["node=\"module\" kind=\"similar\" locations=\"#{nested_namespace_class_path}:1,#{nested_namespace_class_path}:14\" mass=54 score=54", "Total duplication score: 54", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nested_namespace_class_actual, DuplicationProcess::OutputExpectation.new(2, nested_namespace_class_fields, "nested-namespace class group differed"))
nested_namespace_class_reference_fields = ["Similar code found in :module (mass = 54)", "#{nested_namespace_class_path}:1", "#{nested_namespace_class_path}:14", "Total score (lower is better) = 54"]
DuplicationProcess.verify_output(nested_namespace_class_reference, DuplicationProcess::OutputExpectation.new(0, nested_namespace_class_reference_fields, "nested-namespace class Flay group changed"))

eight_level_module_class_path = "test/fixtures/duplication_eight_level_nested_module_class_boundary.rb"
eight_level_module_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(eight_level_module_class_path, "fleek", ""))
eight_level_module_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(eight_level_module_class_path, "flay", ""))
eight_level_module_class_fields = ["node=\"module\" kind=\"similar\" locations=\"#{eight_level_module_class_path}:1,#{eight_level_module_class_path}:26\" mass=66 score=66", "Total duplication score: 66", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(eight_level_module_class_actual, DuplicationProcess::OutputExpectation.new(2, eight_level_module_class_fields, "eight-level nested-module class candidates differed"))
eight_level_module_class_reference_fields = ["Similar code found in :module (mass = 66)", "#{eight_level_module_class_path}:1", "#{eight_level_module_class_path}:26", "Total score (lower is better) = 66"]
DuplicationProcess.verify_output(eight_level_module_class_reference, DuplicationProcess::OutputExpectation.new(0, eight_level_module_class_reference_fields, "eight-level nested-module class Flay group changed"))

nine_level_module_class_path = "test/fixtures/duplication_nine_level_nested_module_class_boundary.rb"
nine_level_module_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nine_level_module_class_path, "fleek", ""))
nine_level_module_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nine_level_module_class_path, "flay", ""))
nine_level_module_class_fields = ["node=\"module\" kind=\"similar\" locations=\"#{nine_level_module_class_path}:1,#{nine_level_module_class_path}:28\" mass=68 score=68", "Total duplication score: 68", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nine_level_module_class_actual, DuplicationProcess::OutputExpectation.new(2, nine_level_module_class_fields, "nine-level nested-module class candidates differed"))
nine_level_module_class_reference_fields = ["Similar code found in :module (mass = 68)", "#{nine_level_module_class_path}:1", "#{nine_level_module_class_path}:28", "Total score (lower is better) = 68"]
DuplicationProcess.verify_output(nine_level_module_class_reference, DuplicationProcess::OutputExpectation.new(0, nine_level_module_class_reference_fields, "nine-level nested-module class Flay group changed"))

ten_level_module_class_path = "test/fixtures/duplication_ten_level_nested_module_class_boundary.rb"
ten_level_module_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(ten_level_module_class_path, "fleek", ""))
ten_level_module_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(ten_level_module_class_path, "flay", ""))
ten_level_module_class_fields = ["node=\"module\" kind=\"similar\" locations=\"#{ten_level_module_class_path}:1,#{ten_level_module_class_path}:30\" mass=70 score=70", "Total duplication score: 70", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(ten_level_module_class_actual, DuplicationProcess::OutputExpectation.new(2, ten_level_module_class_fields, "ten-level nested-module class candidates differed"))
ten_level_module_class_reference_fields = ["Similar code found in :module (mass = 70)", "#{ten_level_module_class_path}:1", "#{ten_level_module_class_path}:30", "Total score (lower is better) = 70"]
DuplicationProcess.verify_output(ten_level_module_class_reference, DuplicationProcess::OutputExpectation.new(0, ten_level_module_class_reference_fields, "ten-level nested-module class Flay group changed"))

eleven_level_module_class_path = "test/fixtures/duplication_eleven_level_nested_module_class_boundary.rb"
eleven_level_module_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(eleven_level_module_class_path, "fleek", ""))
eleven_level_module_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(eleven_level_module_class_path, "flay", ""))
eleven_level_module_class_fields = ["node=\"module\" kind=\"similar\" locations=\"#{eleven_level_module_class_path}:1,#{eleven_level_module_class_path}:32\" mass=72 score=72", "Total duplication score: 72", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(eleven_level_module_class_actual, DuplicationProcess::OutputExpectation.new(2, eleven_level_module_class_fields, "eleven-level nested-module class candidates differed"))
eleven_level_module_class_reference_fields = ["Similar code found in :module (mass = 72)", "#{eleven_level_module_class_path}:1", "#{eleven_level_module_class_path}:32", "Total score (lower is better) = 72"]
DuplicationProcess.verify_output(eleven_level_module_class_reference, DuplicationProcess::OutputExpectation.new(0, eleven_level_module_class_reference_fields, "eleven-level nested-module class Flay group changed"))

twelve_level_module_class_path = "test/fixtures/duplication_twelve_level_nested_module_class_boundary.rb"
twelve_level_module_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(twelve_level_module_class_path, "fleek", ""))
twelve_level_module_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(twelve_level_module_class_path, "flay", ""))
twelve_level_module_class_fields = ["node=\"module\" kind=\"similar\" locations=\"#{twelve_level_module_class_path}:1,#{twelve_level_module_class_path}:34\" mass=74 score=74", "Total duplication score: 74", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(twelve_level_module_class_actual, DuplicationProcess::OutputExpectation.new(2, twelve_level_module_class_fields, "twelve-level nested-module class candidates differed"))
twelve_level_module_class_reference_fields = ["Similar code found in :module (mass = 74)", "#{twelve_level_module_class_path}:1", "#{twelve_level_module_class_path}:34", "Total score (lower is better) = 74"]
DuplicationProcess.verify_output(twelve_level_module_class_reference, DuplicationProcess::OutputExpectation.new(0, twelve_level_module_class_reference_fields, "twelve-level nested-module class Flay group changed"))

thirteen_level_module_class_path = "test/fixtures/duplication_thirteen_level_nested_module_class_boundary.rb"
thirteen_level_module_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(thirteen_level_module_class_path, "fleek", ""))
thirteen_level_module_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(thirteen_level_module_class_path, "flay", ""))
thirteen_level_module_class_fields = ["node=\"module\" kind=\"similar\" locations=\"#{thirteen_level_module_class_path}:1,#{thirteen_level_module_class_path}:36\" mass=76 score=76", "Total duplication score: 76", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(thirteen_level_module_class_actual, DuplicationProcess::OutputExpectation.new(2, thirteen_level_module_class_fields, "thirteen-level nested-module class candidates differed"))
thirteen_level_module_class_reference_fields = ["Similar code found in :module (mass = 76)", "#{thirteen_level_module_class_path}:1", "#{thirteen_level_module_class_path}:36", "Total score (lower is better) = 76"]
DuplicationProcess.verify_output(thirteen_level_module_class_reference, DuplicationProcess::OutputExpectation.new(0, thirteen_level_module_class_reference_fields, "thirteen-level nested-module class Flay group changed"))

fourteen_level_module_class_path = "test/fixtures/duplication_fourteen_level_nested_module_class_boundary.rb"
fourteen_level_module_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(fourteen_level_module_class_path, "fleek", ""))
fourteen_level_module_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(fourteen_level_module_class_path, "flay", ""))
fourteen_level_module_class_fields = ["node=\"module\" kind=\"similar\" locations=\"#{fourteen_level_module_class_path}:1,#{fourteen_level_module_class_path}:38\" mass=78 score=78", "Total duplication score: 78", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(fourteen_level_module_class_actual, DuplicationProcess::OutputExpectation.new(2, fourteen_level_module_class_fields, "fourteen-level nested-module class candidates differed"))
fourteen_level_module_class_reference_fields = ["Similar code found in :module (mass = 78)", "#{fourteen_level_module_class_path}:1", "#{fourteen_level_module_class_path}:38", "Total score (lower is better) = 78"]
DuplicationProcess.verify_output(fourteen_level_module_class_reference, DuplicationProcess::OutputExpectation.new(0, fourteen_level_module_class_reference_fields, "fourteen-level nested-module class Flay group changed"))

fifteen_level_module_class_path = "test/fixtures/duplication_fifteen_level_nested_module_class_boundary.rb"
fifteen_level_module_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(fifteen_level_module_class_path, "fleek", ""))
fifteen_level_module_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(fifteen_level_module_class_path, "flay", ""))
fifteen_level_module_class_fields = ["node=\"module\" kind=\"similar\" locations=\"#{fifteen_level_module_class_path}:1,#{fifteen_level_module_class_path}:40\" mass=80 score=80", "Total duplication score: 80", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(fifteen_level_module_class_actual, DuplicationProcess::OutputExpectation.new(2, fifteen_level_module_class_fields, "fifteen-level nested-module class candidates differed"))
fifteen_level_module_class_reference_fields = ["Similar code found in :module (mass = 80)", "#{fifteen_level_module_class_path}:1", "#{fifteen_level_module_class_path}:40", "Total score (lower is better) = 80"]
DuplicationProcess.verify_output(fifteen_level_module_class_reference, DuplicationProcess::OutputExpectation.new(0, fifteen_level_module_class_reference_fields, "fifteen-level nested-module class Flay group changed"))

nested_class_path = "test/fixtures/duplication_nested_class_group.rb"
nested_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nested_class_path, "fleek", ""))
nested_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_class_path, "flay", ""))
nested_class_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{nested_class_path}:1,#{nested_class_path}:12\" mass=52 score=52", "Total duplication score: 52", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nested_class_actual, DuplicationProcess::OutputExpectation.new(2, nested_class_actual_fields, "nested-class group was not analyzed"))
nested_class_reference_fields = ["Similar code found in :class (mass = 52)", "#{nested_class_path}:1", "#{nested_class_path}:12", "Total score (lower is better) = 52"]
DuplicationProcess.verify_output(nested_class_reference, DuplicationProcess::OutputExpectation.new(0, nested_class_reference_fields, "nested-class Flay group changed"))

deep_nested_class_path = "test/fixtures/duplication_deep_nested_class_boundary.rb"
deep_nested_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(deep_nested_class_path, "fleek", ""))
deep_nested_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(deep_nested_class_path, "flay", ""))
deep_nested_class_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{deep_nested_class_path}:1,#{deep_nested_class_path}:14\" mass=54 score=54", "Total duplication score: 54", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(deep_nested_class_actual, DuplicationProcess::OutputExpectation.new(2, deep_nested_class_actual_fields, "three-level nested-class group was not analyzed"))
deep_nested_class_reference_fields = ["Similar code found in :class (mass = 54)", "#{deep_nested_class_path}:1", "#{deep_nested_class_path}:14", "Total score (lower is better) = 54"]
DuplicationProcess.verify_output(deep_nested_class_reference, DuplicationProcess::OutputExpectation.new(0, deep_nested_class_reference_fields, "deep nested-class Flay group changed"))

deeper_nested_class_path = "test/fixtures/duplication_deeper_nested_class_boundary.rb"
deeper_nested_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(deeper_nested_class_path, "fleek", ""))
deeper_nested_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(deeper_nested_class_path, "flay", ""))
deeper_nested_class_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{deeper_nested_class_path}:1,#{deeper_nested_class_path}:16\" mass=56 score=56", "Total duplication score: 56", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(deeper_nested_class_actual, DuplicationProcess::OutputExpectation.new(2, deeper_nested_class_actual_fields, "four-level nested-class group differed"))
deeper_nested_class_reference_fields = ["Similar code found in :class (mass = 56)", "#{deeper_nested_class_path}:1", "#{deeper_nested_class_path}:16", "Total score (lower is better) = 56"]
DuplicationProcess.verify_output(deeper_nested_class_reference, DuplicationProcess::OutputExpectation.new(0, deeper_nested_class_reference_fields, "four-level nested-class Flay group changed"))

five_level_nested_class_path = "test/fixtures/duplication_five_level_nested_class_boundary.rb"
five_level_nested_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(five_level_nested_class_path, "fleek", ""))
five_level_nested_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(five_level_nested_class_path, "flay", ""))
five_level_nested_class_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{five_level_nested_class_path}:1,#{five_level_nested_class_path}:18\" mass=58 score=58", "Total duplication score: 58", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(five_level_nested_class_actual, DuplicationProcess::OutputExpectation.new(2, five_level_nested_class_actual_fields, "five-level nested-class candidates differed"))
five_level_nested_class_reference_fields = ["Similar code found in :class (mass = 58)", "#{five_level_nested_class_path}:1", "#{five_level_nested_class_path}:18", "Total score (lower is better) = 58"]
DuplicationProcess.verify_output(five_level_nested_class_reference, DuplicationProcess::OutputExpectation.new(0, five_level_nested_class_reference_fields, "five-level nested-class Flay group changed"))

six_level_nested_class_path = "test/fixtures/duplication_six_level_nested_class_boundary.rb"
six_level_nested_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(six_level_nested_class_path, "fleek", ""))
six_level_nested_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(six_level_nested_class_path, "flay", ""))
six_level_nested_class_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{six_level_nested_class_path}:1,#{six_level_nested_class_path}:20\" mass=60 score=60", "Total duplication score: 60", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(six_level_nested_class_actual, DuplicationProcess::OutputExpectation.new(2, six_level_nested_class_actual_fields, "six-level nested-class candidates differed"))
six_level_nested_class_reference_fields = ["Similar code found in :class (mass = 60)", "#{six_level_nested_class_path}:1", "#{six_level_nested_class_path}:20", "Total score (lower is better) = 60"]
DuplicationProcess.verify_output(six_level_nested_class_reference, DuplicationProcess::OutputExpectation.new(0, six_level_nested_class_reference_fields, "six-level nested-class Flay group changed"))

seven_level_nested_class_path = "test/fixtures/duplication_seven_level_nested_class_boundary.rb"
seven_level_nested_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(seven_level_nested_class_path, "fleek", ""))
seven_level_nested_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(seven_level_nested_class_path, "flay", ""))
seven_level_nested_class_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{seven_level_nested_class_path}:1,#{seven_level_nested_class_path}:22\" mass=62 score=62", "Total duplication score: 62", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(seven_level_nested_class_actual, DuplicationProcess::OutputExpectation.new(2, seven_level_nested_class_actual_fields, "seven-level nested-class candidates differed"))
seven_level_nested_class_reference_fields = ["Similar code found in :class (mass = 62)", "#{seven_level_nested_class_path}:1", "#{seven_level_nested_class_path}:22", "Total score (lower is better) = 62"]
DuplicationProcess.verify_output(seven_level_nested_class_reference, DuplicationProcess::OutputExpectation.new(0, seven_level_nested_class_reference_fields, "seven-level nested-class Flay group changed"))

eight_level_nested_class_path = "test/fixtures/duplication_eight_level_nested_class_boundary.rb"
eight_level_nested_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(eight_level_nested_class_path, "fleek", ""))
eight_level_nested_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(eight_level_nested_class_path, "flay", ""))
eight_level_nested_class_fields = ["node=\"class\" kind=\"similar\" locations=\"#{eight_level_nested_class_path}:1,#{eight_level_nested_class_path}:24\" mass=64 score=64", "Total duplication score: 64", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(eight_level_nested_class_actual, DuplicationProcess::OutputExpectation.new(2, eight_level_nested_class_fields, "eight-level nested-class candidates differed"))
eight_level_nested_class_reference_fields = ["Similar code found in :class (mass = 64)", "#{eight_level_nested_class_path}:1", "#{eight_level_nested_class_path}:24", "Total score (lower is better) = 64"]
DuplicationProcess.verify_output(eight_level_nested_class_reference, DuplicationProcess::OutputExpectation.new(0, eight_level_nested_class_reference_fields, "eight-level nested-class Flay group changed"))

nine_level_nested_class_path = "test/fixtures/duplication_nine_level_nested_class_boundary.rb"
nine_level_nested_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nine_level_nested_class_path, "fleek", ""))
nine_level_nested_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nine_level_nested_class_path, "flay", ""))
nine_level_nested_class_fields = ["node=\"class\" kind=\"similar\" locations=\"#{nine_level_nested_class_path}:1,#{nine_level_nested_class_path}:26\" mass=66 score=66", "Total duplication score: 66", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nine_level_nested_class_actual, DuplicationProcess::OutputExpectation.new(2, nine_level_nested_class_fields, "nine-level nested-class candidates differed"))
nine_level_nested_class_reference_fields = ["Similar code found in :class (mass = 66)", "#{nine_level_nested_class_path}:1", "#{nine_level_nested_class_path}:26", "Total score (lower is better) = 66"]
DuplicationProcess.verify_output(nine_level_nested_class_reference, DuplicationProcess::OutputExpectation.new(0, nine_level_nested_class_reference_fields, "nine-level nested-class Flay group changed"))

ten_level_nested_class_path = "test/fixtures/duplication_ten_level_nested_class_boundary.rb"
ten_level_nested_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(ten_level_nested_class_path, "fleek", ""))
ten_level_nested_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(ten_level_nested_class_path, "flay", ""))
ten_level_nested_class_fields = ["node=\"class\" kind=\"similar\" locations=\"#{ten_level_nested_class_path}:1,#{ten_level_nested_class_path}:28\" mass=68 score=68", "Total duplication score: 68", "scope=partial", "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"]
DuplicationProcess.verify_output(ten_level_nested_class_actual, DuplicationProcess::OutputExpectation.new(2, ["node=\"class\" kind=\"similar\" locations=\"#{ten_level_nested_class_path}:1,#{ten_level_nested_class_path}:28\" mass=68 score=68", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"], "ten-level nested-class candidates differed"))
ten_level_nested_class_reference_fields = ["Similar code found in :class (mass = 68)", "#{ten_level_nested_class_path}:1", "#{ten_level_nested_class_path}:28", "Total score (lower is better) = 68"]
DuplicationProcess.verify_output(ten_level_nested_class_reference, DuplicationProcess::OutputExpectation.new(0, ten_level_nested_class_reference_fields, "ten-level nested-class Flay group changed"))

nested_class_siblings_path = "test/fixtures/duplication_nested_class_siblings.rb"
nested_class_siblings_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nested_class_siblings_path, "fleek", ""))
nested_class_siblings_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_class_siblings_path, "flay", ""))
nested_class_siblings_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{nested_class_siblings_path}:1,#{nested_class_siblings_path}:23\" mass=104 score=104", "Total duplication score: 104", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nested_class_siblings_actual, DuplicationProcess::OutputExpectation.new(2, nested_class_siblings_actual_fields, "nested-class siblings group differed"))
nested_class_siblings_reference_fields = ["Similar code found in :class (mass = 104)", "#{nested_class_siblings_path}:1", "#{nested_class_siblings_path}:23", "Total score (lower is better) = 104"]
DuplicationProcess.verify_output(nested_class_siblings_reference, DuplicationProcess::OutputExpectation.new(0, nested_class_siblings_reference_fields, "nested-class siblings Flay group changed"))

nested_sibling_methods_path = "test/fixtures/duplication_nested_class_sibling_methods.rb"
nested_sibling_methods_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nested_sibling_methods_path, "fleek", ""))
nested_sibling_methods_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_sibling_methods_path, "flay", ""))
nested_sibling_methods_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{nested_sibling_methods_path}:1,#{nested_sibling_methods_path}:29\" mass=118 score=118", "Total duplication score: 118", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nested_sibling_methods_actual, DuplicationProcess::OutputExpectation.new(2, nested_sibling_methods_actual_fields, "multi-method nested class siblings group differed"))
nested_sibling_methods_reference_fields = ["Similar code found in :class (mass = 118)", "#{nested_sibling_methods_path}:1", "#{nested_sibling_methods_path}:29", "Total score (lower is better) = 118"]
DuplicationProcess.verify_output(nested_sibling_methods_reference, DuplicationProcess::OutputExpectation.new(0, nested_sibling_methods_reference_fields, "multi-method nested class siblings Flay group changed"))

nested_wrapped_siblings_path = "test/fixtures/duplication_nested_wrapped_class_siblings.rb"
nested_wrapped_siblings_actual = DuplicationProcess.run(DuplicationProcess::Input.new(nested_wrapped_siblings_path, "fleek", ""))
nested_wrapped_siblings_reference = DuplicationProcess.run(DuplicationProcess::Input.new(nested_wrapped_siblings_path, "flay", ""))
nested_wrapped_siblings_actual_fields = ["node=\"class\" kind=\"similar\" locations=\"#{nested_wrapped_siblings_path}:1,#{nested_wrapped_siblings_path}:35\" mass=158 score=158", "Total duplication score: 158", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(nested_wrapped_siblings_actual, DuplicationProcess::OutputExpectation.new(2, nested_wrapped_siblings_actual_fields, "nested wrapped class siblings group differed"))
nested_wrapped_siblings_reference_fields = ["Similar code found in :class (mass = 158)", "#{nested_wrapped_siblings_path}:1", "#{nested_wrapped_siblings_path}:35", "Total score (lower is better) = 158"]
DuplicationProcess.verify_output(nested_wrapped_siblings_reference, DuplicationProcess::OutputExpectation.new(0, nested_wrapped_siblings_reference_fields, "nested wrapped class siblings Flay group changed"))

qualified_namespace_class_path = "test/fixtures/duplication_qualified_namespace_class_group.rb"
qualified_namespace_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_class_path, "fleek", ""))
qualified_namespace_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_class_path, "flay", ""))
qualified_namespace_class_fields = ["node=\"module\" kind=\"similar\" locations=\"#{qualified_namespace_class_path}:1,#{qualified_namespace_class_path}:12\" mass=56 score=56", "Total duplication score: 56", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(qualified_namespace_class_actual, DuplicationProcess::OutputExpectation.new(2, qualified_namespace_class_fields, "qualified-namespace class group differed"))
qualified_namespace_class_reference_fields = ["Similar code found in :module (mass = 56)", "#{qualified_namespace_class_path}:1", "#{qualified_namespace_class_path}:12", "Total score (lower is better) = 56"]
DuplicationProcess.verify_output(qualified_namespace_class_reference, DuplicationProcess::OutputExpectation.new(0, qualified_namespace_class_reference_fields, "qualified-namespace class Flay group changed"))

qualified_namespace_multiple_classes_path = "test/fixtures/duplication_qualified_namespace_multiple_classes.rb"
qualified_namespace_multiple_classes_actual = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_multiple_classes_path, "fleek", ""))
qualified_namespace_multiple_classes_reference = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_multiple_classes_path, "flay", ""))
qualified_namespace_multiple_classes_fields = ["node=\"module\" kind=\"similar\" locations=\"#{qualified_namespace_multiple_classes_path}:1,#{qualified_namespace_multiple_classes_path}:21\" mass=106 score=106", "Total duplication score: 106", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(qualified_namespace_multiple_classes_actual, DuplicationProcess::OutputExpectation.new(2, qualified_namespace_multiple_classes_fields, "multiple qualified-namespace class group differed"))
qualified_namespace_multiple_classes_reference_fields = ["Similar code found in :module (mass = 106)", "#{qualified_namespace_multiple_classes_path}:1", "#{qualified_namespace_multiple_classes_path}:21", "Total score (lower is better) = 106"]
DuplicationProcess.verify_output(qualified_namespace_multiple_classes_reference, DuplicationProcess::OutputExpectation.new(0, qualified_namespace_multiple_classes_reference_fields, "multiple qualified-namespace class Flay group changed"))

qualified_namespace_multi_method_path = "test/fixtures/duplication_qualified_namespace_multi_method_class_boundary.rb"
qualified_namespace_multi_method_actual = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_multi_method_path, "fleek", ""))
qualified_namespace_multi_method_reference = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_multi_method_path, "flay", ""))
qualified_namespace_multi_method_fields = ["node=\"module\" kind=\"similar\" locations=\"#{qualified_namespace_multi_method_path}:1,#{qualified_namespace_multi_method_path}:19\" mass=104 score=104", "Total duplication score: 104", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(qualified_namespace_multi_method_actual, DuplicationProcess::OutputExpectation.new(2, qualified_namespace_multi_method_fields, "multi-method qualified class group differed"))
qualified_namespace_multi_method_reference_fields = ["Similar code found in :module (mass = 104)", "#{qualified_namespace_multi_method_path}:1", "#{qualified_namespace_multi_method_path}:19", "Total score (lower is better) = 104"]
DuplicationProcess.verify_output(qualified_namespace_multi_method_reference, DuplicationProcess::OutputExpectation.new(0, qualified_namespace_multi_method_reference_fields, "multi-method qualified-class Flay group changed"))

qualified_namespace_multiple_multi_method_path = "test/fixtures/duplication_qualified_namespace_multiple_multi_method_classes.rb"
qualified_namespace_multiple_multi_method_actual = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_multiple_multi_method_path, "fleek", ""))
qualified_namespace_multiple_multi_method_reference = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_multiple_multi_method_path, "flay", ""))
qualified_namespace_multiple_multi_method_fields = ["node=\"module\" kind=\"similar\" locations=\"#{qualified_namespace_multiple_multi_method_path}:1,#{qualified_namespace_multiple_multi_method_path}:23\" mass=42 score=42", "Total duplication score: 42", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(qualified_namespace_multiple_multi_method_actual, DuplicationProcess::OutputExpectation.new(2, qualified_namespace_multiple_multi_method_fields, "multiple multi-method qualified classes group differed"))
qualified_namespace_multiple_multi_method_reference_fields = ["Similar code found in :module (mass = 42)", "#{qualified_namespace_multiple_multi_method_path}:1", "#{qualified_namespace_multiple_multi_method_path}:23", "Total score (lower is better) = 42"]
DuplicationProcess.verify_output(qualified_namespace_multiple_multi_method_reference, DuplicationProcess::OutputExpectation.new(0, qualified_namespace_multiple_multi_method_reference_fields, "multiple multi-method qualified classes Flay group changed"))

qualified_namespace_depth_path = "test/fixtures/duplication_qualified_namespace_depth_boundary.rb"
qualified_namespace_depth_actual = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_depth_path, "fleek", ""))
qualified_namespace_depth_reference = DuplicationProcess.run(DuplicationProcess::Input.new(qualified_namespace_depth_path, "flay", ""))
qualified_namespace_depth_fields = {first_group: "Group: check=\"flay:StructuralDuplication\" node=\"module\" kind=\"similar\" locations=\"#{qualified_namespace_depth_path}:23,#{qualified_namespace_depth_path}:34\" mass=68 score=68", second_group: "Group: check=\"flay:StructuralDuplication\" node=\"module\" kind=\"similar\" locations=\"#{qualified_namespace_depth_path}:1,#{qualified_namespace_depth_path}:12\" mass=66 score=66", score: "Total duplication score: 134", coverage: "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", status: "Status: findings"}.values
DuplicationProcess.verify_output(qualified_namespace_depth_actual, DuplicationProcess::OutputExpectation.new(2, qualified_namespace_depth_fields, "qualified-namespace depth boundary differed"))
qualified_namespace_depth_reference_fields = "Similar code found in :module (mass = 68)|#{qualified_namespace_depth_path}:23|#{qualified_namespace_depth_path}:34|Similar code found in :module (mass = 66)|#{qualified_namespace_depth_path}:1|#{qualified_namespace_depth_path}:12|Total score (lower is better) = 134".split("|")
DuplicationProcess.verify_output(qualified_namespace_depth_reference, DuplicationProcess::OutputExpectation.new(0, qualified_namespace_depth_reference_fields, "qualified-namespace depth Flay groups changed"))

clean_scope_path = "test/fixtures/duplication_class_scopes_clean.rb"
clean_scope_actual = DuplicationProcess.run(DuplicationProcess::Input.new(clean_scope_path, "fleek", ""))
clean_scope_reference = DuplicationProcess.run(DuplicationProcess::Input.new(clean_scope_path, "flay", ""))
clean_scope_fields = ["Total duplication score: 0", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: complete"]
DuplicationProcess.verify_output(clean_scope_actual, DuplicationProcess::OutputExpectation.new(0, clean_scope_fields, "clean nested scope candidate parity differed"))
DuplicationProcess.verify_output(clean_scope_reference, DuplicationProcess::OutputExpectation.new(0, ["Total score (lower is better) = 0"], "clean nested scope Flay reference changed"))

module_group_path = "test/fixtures/duplication_module_group.rb"
module_group_actual = DuplicationProcess.run(DuplicationProcess::Input.new(module_group_path, "fleek", ""))
module_group_reference = DuplicationProcess.run(DuplicationProcess::Input.new(module_group_path, "flay", ""))
module_group_actual_fields = ["node=\"module\" kind=\"similar\" locations=\"#{module_group_path}:1,#{module_group_path}:20\" mass=34 score=34", "Total duplication score: 34", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(module_group_actual, DuplicationProcess::OutputExpectation.new(2, module_group_actual_fields, "cross-module Flay group differed"))
module_group_reference_fields = ["Similar code found in :module (mass = 34)", "#{module_group_path}:1", "#{module_group_path}:20", "Total score (lower is better) = 34"]
DuplicationProcess.verify_output(module_group_reference, DuplicationProcess::OutputExpectation.new(0, module_group_reference_fields, "Flay cross-module group changed"))

module_identical_path = "test/fixtures/duplication_module_identical_group.rb"
module_identical_actual = DuplicationProcess.run(DuplicationProcess::Input.new(module_identical_path, "fleek", ""))
module_identical_reference = DuplicationProcess.run(DuplicationProcess::Input.new(module_identical_path, "flay", ""))
module_identical_fields = ["node=\"module\" kind=\"identical\" locations=\"#{module_identical_path}:1,#{module_identical_path}:20\" mass=34 score=68", "Total duplication score: 68", "Status: findings"]
DuplicationProcess.verify_output(module_identical_actual, DuplicationProcess::OutputExpectation.new(2, module_identical_fields, "identical Flay module group differed"))
module_identical_reference_fields = ["IDENTICAL code found in :module (mass*2 = 68)", "#{module_identical_path}:1", "#{module_identical_path}:20", "Total score (lower is better) = 68"]
DuplicationProcess.verify_output(module_identical_reference, DuplicationProcess::OutputExpectation.new(0, module_identical_reference_fields, "Flay identical module group changed"))

namespace_class_path = "test/fixtures/duplication_class_methods_namespace.rb"
namespace_class_actual = DuplicationProcess.run(DuplicationProcess::Input.new(namespace_class_path, "fleek", ""))
namespace_class_reference = DuplicationProcess.run(DuplicationProcess::Input.new(namespace_class_path, "flay", ""))
namespace_class_actual_fields = ["kind=\"similar\"", "locations=\"#{namespace_class_path}:3,#{namespace_class_path}:10\"", "mass=48 score=48", "Total duplication score: 48", "Status: findings"]
DuplicationProcess.verify_output(namespace_class_actual, DuplicationProcess::OutputExpectation.new(2, namespace_class_actual_fields, "simple namespace class methods were not analyzed"))
namespace_class_reference_fields = ["Similar code found in :defn (mass = 48)", "#{namespace_class_path}:3", "#{namespace_class_path}:10", "Total score (lower is better) = 48"]
DuplicationProcess.verify_output(namespace_class_reference, DuplicationProcess::OutputExpectation.new(0, namespace_class_reference_fields, "Flay namespace class-method group changed"))

empty_namespace_path = "test/fixtures/duplication_empty_namespace_classes.rb"
empty_namespace_actual = DuplicationProcess.run(DuplicationProcess::Input.new(empty_namespace_path, "fleek", ""))
empty_namespace_reference = DuplicationProcess.run(DuplicationProcess::Input.new(empty_namespace_path, "flay", ""))
DuplicationProcess.verify_output(empty_namespace_actual, DuplicationProcess::OutputExpectation.new(0, ["Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Total duplication score: 0", "Status: complete"], "empty namespaced classes were not analyzed cleanly"))
DuplicationProcess.verify_output(empty_namespace_reference, DuplicationProcess::OutputExpectation.new(0, ["Total score (lower is better) = 0"], "Flay empty namespaced classes changed"))

empty_module_path = "test/fixtures/duplication_empty_module.rb"
empty_module_actual = DuplicationProcess.run(DuplicationProcess::Input.new(empty_module_path, "fleek", ""))
empty_module_reference = DuplicationProcess.run(DuplicationProcess::Input.new(empty_module_path, "flay", ""))
DuplicationProcess.verify_output(empty_module_actual, DuplicationProcess::OutputExpectation.new(0, ["Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Total duplication score: 0", "Status: complete"], "empty modules were not analyzed cleanly"))
DuplicationProcess.verify_output(empty_module_reference, DuplicationProcess::OutputExpectation.new(0, ["Total score (lower is better) = 0"], "Flay empty module changed"))

partial_candidates_path = "test/fixtures/duplication_class_methods_partial_candidates.rb"
partial_candidates_actual = DuplicationProcess.run(DuplicationProcess::Input.new(partial_candidates_path, "fleek", ""))
partial_candidates_reference = DuplicationProcess.run(DuplicationProcess::Input.new(partial_candidates_path, "flay", ""))
partial_candidates_fields = ["kind=\"similar\"", "locations=\"#{partial_candidates_path}:4,#{partial_candidates_path}:15\"", "mass=48 score=48", "Total duplication score: 48", "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"]
DuplicationProcess.verify_output(partial_candidates_actual, DuplicationProcess::OutputExpectation.new(1, partial_candidates_fields, "supported class methods were hidden by unsupported callbacks"))
partial_candidates_reference_fields = ["Similar code found in :defn (mass = 48)", "#{partial_candidates_path}:4", "#{partial_candidates_path}:15", "Total score (lower is better) = 48"]
DuplicationProcess.verify_output(partial_candidates_reference, DuplicationProcess::OutputExpectation.new(0, partial_candidates_reference_fields, "Flay class methods with callbacks changed"))

partial_rails_path = "test/fixtures/duplication_class_methods_partial_rails.rb"
partial_rails_actual = DuplicationProcess.run(DuplicationProcess::Input.new(partial_rails_path, "fleek", ""))
partial_rails_reference = DuplicationProcess.run(DuplicationProcess::Input.new(partial_rails_path, "flay", ""))
partial_rails_expected = ["#{partial_rails_path}\" scope=partial", "locations=\"#{partial_rails_path}:4,#{partial_rails_path}:11\"", "mass=48 score=48", "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"]
DuplicationProcess.verify_output(partial_rails_actual, DuplicationProcess::OutputExpectation.new(1, partial_rails_expected, "partial Rails class results were hidden or reported complete"))
DuplicationProcess.verify(partial_rails_actual[2].include?("Partial results may omit Flay candidates"), "partial Rails class results were not labeled")
DuplicationProcess.verify_output(partial_rails_reference, DuplicationProcess::OutputExpectation.new(0, ["Similar code found in :defn (mass = 48)", "#{partial_rails_path}:4", "#{partial_rails_path}:11"], "partial Rails Flay reference changed"))

rails_corpus_root = ENV["FLEEK_RAILS_CORPUS"]
if ENV["FLEEK_REQUIRE_RAILS_CORPUS"] == "1" && (!rails_corpus_root || rails_corpus_root.empty?)
  raise "FLEEK_RAILS_CORPUS is required for the pinned Rails controller contract"
end
if rails_corpus_root && !rails_corpus_root.empty?
  rails_controller_path = File.join(rails_corpus_root, "app/controllers/users_controller.rb")
  raise "pinned Rails UsersController is missing: #{rails_controller_path}" unless File.file?(rails_controller_path)
  rails_revision_process = Process.spawn("git", "-C", rails_corpus_root, "rev-parse", "HEAD", out: "/tmp/fleek-rails-revision-out", err: "/tmp/fleek-rails-revision-err")
  rails_revision = AnalysisRunner.observe(rails_revision_process, "/tmp/fleek-rails-revision-out", "/tmp/fleek-rails-revision-err")
  expected_rails_revision = "92ce7c470bc31952d7dc51cac15e577a948e479e"
  unless rails_revision[0] == 0 && rails_revision[1].strip == expected_rails_revision
    raise "pinned Rails corpus revision differed from #{expected_rails_revision}"
  end
  rails_file_process = Process.spawn("git", "-C", rails_corpus_root, "diff", "--quiet", expected_rails_revision, "--", "app/controllers/users_controller.rb", out: "/tmp/fleek-rails-file-out", err: "/tmp/fleek-rails-file-err")
  rails_file = AnalysisRunner.observe(rails_file_process, "/tmp/fleek-rails-file-out", "/tmp/fleek-rails-file-err")
  raise "pinned Rails UsersController has local modifications" unless rails_file[0] == 0
  rails_actual = DuplicationProcess.run(DuplicationProcess::Input.new(rails_controller_path, "fleek", ""))
  rails_reference = DuplicationProcess.run(DuplicationProcess::Input.new(rails_controller_path, "flay", ""))
  rails_fields = ["scope=partial", "locations=\"#{rails_controller_path}:51,#{rails_controller_path}:58\"", "mass=48 score=48", "Coverage: 1 selected; 0 analyzed; 1 failed; 0 excluded", "Status: incomplete"]
  DuplicationProcess.verify_output(rails_actual, DuplicationProcess::OutputExpectation.new(1, rails_fields, "pinned Rails controller Flay group or incomplete status differed"))
  DuplicationProcess.verify(rails_actual[2].include?("Partial results may omit Flay candidates"), "pinned Rails controller partial warning missing")
  rails_reference_fields = ["Similar code found in :defn (mass = 48)", "#{rails_controller_path}:51", "#{rails_controller_path}:58", "Total score (lower is better) = 48"]
  DuplicationProcess.verify_output(rails_reference, DuplicationProcess::OutputExpectation.new(0, rails_reference_fields, "pinned Rails Flay reference changed"))
end

DuplicationProcess.verify_class_method_pair(class_methods_path, 19, "class method")
DuplicationProcess.verify_class_method_pair(class_methods_with_helper_path, 19, "class helper")
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_required_parameters.rb", :required_parameters)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_parameter_arity.rb", :parameter_arity)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_parameter_names.rb", :parameter_names)
optional_parameters_path = "test/fixtures/duplication_class_methods_optional_parameters.rb"
DuplicationProcess.verify_class_method_parity(optional_parameters_path, :optional_parameters)
optional_defaults_path = "test/fixtures/duplication_class_methods_optional_parameter_defaults.rb"
DuplicationProcess.verify_class_method_parity(optional_defaults_path, :optional_parameter_defaults)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_optional_literal_defaults.rb", :optional_literal_defaults)
DuplicationProcess.verify_class_method_no_group("test/fixtures/duplication_class_methods_optional_parameter_counts.rb")
DuplicationProcess.verify_class_method_no_group("test/fixtures/duplication_class_methods_optional_parameter_count_candidates.rb")
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_module_methods.rb", :module_methods)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_conditionals.rb", :conditionals)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_unless.rb", :unless_branches)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_conditional_return.rb", :conditional_return)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_or.rb", :or_expression)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_local_writes.rb", :local_writes)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_local_write_names.rb", :local_write_names)
DuplicationProcess.verify_class_method_parity("test/fixtures/duplication_class_methods_candidate_capacity.rb", :candidate_capacity)

class_group_with_pair_path = "test/fixtures/duplication_class_methods_class_group_with_conditional_pair.rb"
class_group_with_pair_actual = DuplicationProcess.run(DuplicationProcess::Input.new(class_group_with_pair_path, "fleek", ""))
class_group_with_pair_reference = DuplicationProcess.run(DuplicationProcess::Input.new(class_group_with_pair_path, "flay", ""))
class_group_with_pair_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{class_group_with_pair_path}:20,#{class_group_with_pair_path}:32\" mass=62 score=62", "node=\"class\" kind=\"similar\" locations=\"#{class_group_with_pair_path}:1,#{class_group_with_pair_path}:10\" mass=50 score=50", "Total duplication score: 112", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(class_group_with_pair_actual, DuplicationProcess::OutputExpectation.new(2, class_group_with_pair_fields, "Flay class and independent method groups differed"))
class_method_group_position = class_group_with_pair_actual[1].index("node=\"defn\"")
class_group_position = class_group_with_pair_actual[1].index("node=\"class\"")
DuplicationProcess.verify(class_method_group_position < class_group_position, "Flay group ordering differed")
class_group_with_pair_reference_fields = ["Similar code found in :defn (mass = 62)", "#{class_group_with_pair_path}:20", "#{class_group_with_pair_path}:32", "Similar code found in :class (mass = 50)", "#{class_group_with_pair_path}:1", "#{class_group_with_pair_path}:10", "Total score (lower is better) = 112"]
DuplicationProcess.verify_output(class_group_with_pair_reference, DuplicationProcess::OutputExpectation.new(0, class_group_with_pair_reference_fields, "Flay groups with conditional class-method candidates changed"))

topology_path = "test/fixtures/duplication_class_methods_topology.rb"
DuplicationProcess.verify_class_method_no_group(topology_path, "different class method tree topology was grouped")

partial_path = "test/fixtures/duplication_class_methods_partial_match.rb"
partial_actual = DuplicationProcess.run(DuplicationProcess::Input.new(partial_path, "fleek", ""))
partial_reference = DuplicationProcess.run(DuplicationProcess::Input.new(partial_path, "flay", ""))
DuplicationProcess.verify_output(partial_actual, DuplicationProcess::OutputExpectation.new(1, ["Status: incomplete"], "partial class-method duplicate was silently skipped"))
DuplicationProcess.verify(partial_actual[2].include?("unsupported Flay candidate syntax"), "partial class-method duplicate was silently skipped")
partial_reference_fields = ["IDENTICAL code found in :call (mass*2 = 64)", "#{partial_path}:4", "#{partial_path}:9", "Total score (lower is better) = 64"]
DuplicationProcess.verify_output(partial_reference, DuplicationProcess::OutputExpectation.new(0, partial_reference_fields, "partial Flay group changed"))

class_identical_path = "test/fixtures/duplication_class_methods_identical.rb"
DuplicationProcess.verify_class_method_parity(class_identical_path, :identical)

ambiguous_class_methods = DuplicationProcess.run(DuplicationProcess::Input.new("test/fixtures/duplication_class_methods_ambiguous.rb", "fleek", ""))
ambiguous_class_methods_path = "test/fixtures/duplication_class_methods_ambiguous.rb"
ambiguous_class_methods_fields = ["node=\"defn\" kind=\"similar\" locations=\"#{ambiguous_class_methods_path}:2,#{ambiguous_class_methods_path}:19,#{ambiguous_class_methods_path}:36\" mass=48 score=48", "Total duplication score: 48", "File duplication score: \"#{ambiguous_class_methods_path}\" score=48", "Status: findings"]
DuplicationProcess.verify_output(ambiguous_class_methods, DuplicationProcess::OutputExpectation.new(2, ambiguous_class_methods_fields, "multiple Flay method candidates were not grouped"))

direct_sibling_path = "test/fixtures/duplication_class_direct_and_sibling_methods.rb"
direct_sibling_actual = DuplicationProcess.run(DuplicationProcess::Input.new(direct_sibling_path, "fleek", ""))
direct_sibling_fields = ["node=\"class\" kind=\"similar\" locations=\"#{direct_sibling_path}:13,#{direct_sibling_path}:22\" mass=50 score=50",
  "Total duplication score: 50", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
DuplicationProcess.verify_output(direct_sibling_actual, DuplicationProcess::OutputExpectation.new(2, direct_sibling_fields,
  "direct methods beside sibling classes differed from conservative Flay"))
direct_sibling_reference = DuplicationProcess.run(DuplicationProcess::Input.new(direct_sibling_path, "flay", ""))
DuplicationProcess.verify(direct_sibling_reference[0] == 0 && direct_sibling_reference[1].include?("Total score (lower is better) = 50"),
  "conservative Flay direct sibling reference changed")

liberal_path = direct_sibling_path
liberal_actual = DuplicationProcess.run(DuplicationProcess::Input.new(liberal_path, "fleek", "--liberal"))
liberal_reference = DuplicationProcess.run(DuplicationProcess::Input.new(liberal_path, "flay", "--liberal"))
liberal_fields = [
  "node=\"defn\" kind=\"identical\" locations=\"#{liberal_path}:6,#{liberal_path}:14,#{liberal_path}:23\" mass=72 score=216",
  "node=\"class\" kind=\"similar\" locations=\"#{liberal_path}:13,#{liberal_path}:22\" mass=50 score=50",
  "Total duplication score: 266",
  "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded",
  "Status: findings"
]
liberal_reference_fields = ["IDENTICAL code found in :defn (mass*3 = 216)", "Similar code found in :class (mass = 50)", "Total score (lower is better) = 266"]
DuplicationProcess.verify(liberal_reference[0] == 0 && DuplicationProcess.includes_all?(liberal_reference[1], liberal_reference_fields), "Flay liberal reference changed")
DuplicationProcess.verify_output(liberal_actual, DuplicationProcess::OutputExpectation.new(2, liberal_fields, "liberal pruning omitted retained method candidates"))

puts "Duplication contract: pass"
