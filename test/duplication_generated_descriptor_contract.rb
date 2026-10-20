require_relative "analysis_runner"

# Compares generated method candidates with the supported Prism descriptor inventory.
# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:LongParameterList
# :reek:NestedIterators
# :reek:RepeatedConditional
# :reek:TooManyStatements
class FlayGeneratedDescriptorContract
  # Carries the Prism node and parameter forms for one generated candidate pair.
  Case = Struct.new(:node_types, :parameter_types, :name, :first_body, :second_body, :first_parameters, :second_parameters, :expected_node, :scope, :third_body, :third_parameters, :expected_candidates)
  # Carries the parsed Flay result fields compared by the public contract.
  Group = Struct.new(:kind, :mass, :score, :locations)
  # Carries isolated paths and expected locations for one contract run.
  Run = Struct.new(:id, :root, :directory, :paths, :expected_locations, :output_paths, :reference_output_paths, :evidence_path)
  MAX_NESTED_WORKERS = 2
  COMPOSED_NODE_TYPES = %w[PM_CALL_NODE PM_BLOCK_NODE PM_BLOCK_PARAMETERS_NODE PM_INTEGER_NODE PM_PARAMETERS_NODE PM_REQUIRED_PARAMETER_NODE PM_OPTIONAL_PARAMETER_NODE].freeze
  COMPOSED_PARAMETER_TYPES = %w[PM_REQUIRED_PARAMETER_NODE PM_OPTIONAL_PARAMETER_NODE PM_REQUIRED_KEYWORD_PARAMETER_NODE PM_OPTIONAL_KEYWORD_PARAMETER_NODE PM_REST_PARAMETER_NODE PM_KEYWORD_REST_PARAMETER_NODE PM_BLOCK_PARAMETER_NODE].freeze
  NODE_CASES = [
    Case.new(%w[PM_MULTI_WRITE_NODE PM_LOCAL_VARIABLE_TARGET_NODE], [], "multi-write", "first, second = [1, 2]", "third, fourth = [3, 4]", "", ""),
    Case.new(%w[PM_LOCAL_VARIABLE_READ_NODE], [], "local-read", "process(value)", "process(other)", "", ""),
    Case.new(%w[PM_LOCAL_VARIABLE_WRITE_NODE], [], "local-write", "value = 1", "other = 2", "", ""),
    Case.new(%w[PM_LOCAL_VARIABLE_OPERATOR_WRITE_NODE], [], "local-operator-write", "value += 1", "value -= 2", "", ""),
    Case.new(%w[PM_LOCAL_VARIABLE_AND_WRITE_NODE], [], "local-and-write", "value &&= true", "other &&= true", "", ""),
    Case.new(%w[PM_LOCAL_VARIABLE_OR_WRITE_NODE], [], "local-or-write", "value ||= 1", "value ||= 2", "", ""),
    Case.new(%w[PM_INSTANCE_VARIABLE_READ_NODE], [], "instance-read", "process(@value)", "process(@other)", "", ""),
    Case.new(%w[PM_INSTANCE_VARIABLE_WRITE_NODE], [], "instance-write", "@value = 1", "@other = 2", "", ""),
    Case.new(%w[PM_INSTANCE_VARIABLE_OPERATOR_WRITE_NODE], [], "instance-operator-write", "@value += 1", "@value -= 2", "", ""),
    Case.new(%w[PM_CLASS_VARIABLE_READ_NODE], [], "class-read", "process(@@value)", "process(@@other)", "", ""),
    Case.new(%w[PM_CLASS_VARIABLE_WRITE_NODE], [], "class-write", "@@value = 1", "@@other = 2", "", ""),
    Case.new(%w[PM_CLASS_VARIABLE_OPERATOR_WRITE_NODE], [], "class-operator-write", "@@value += 1", "@@value -= 2", "", ""),
    Case.new(%w[PM_CLASS_VARIABLE_AND_WRITE_NODE], [], "class-and-write", "@@value &&= true", "@@other &&= true", "", ""),
    Case.new(%w[PM_CLASS_VARIABLE_OR_WRITE_NODE], [], "class-or-write", "@@value ||= 1", "@@value ||= 2", "", ""),
    Case.new(%w[PM_MULTI_TARGET_NODE], [], "multi-target", "(first, second), third = [1, 2], 3", "(fourth, fifth), sixth = [4, 5], 6", "", ""),
    Case.new(%w[PM_CALL_NODE], [], "call", "process(value)", "render(other)", "", ""),
    Case.new(%w[PM_STRING_NODE], [], "string", 'process("first")', 'process("second")', "", ""),
    Case.new(%w[PM_INTERPOLATED_STRING_NODE PM_EMBEDDED_VARIABLE_NODE], [], "interpolated-variable", '"hello #{value}"', '"hello #{other}"', "(value)", "(other)"),
    Case.new(%w[PM_INTERPOLATED_STRING_NODE PM_EMBEDDED_STATEMENTS_NODE PM_CALL_NODE], [], "interpolated-statements", '"hello #{process(value)}"', '"hello #{render(other)}"', "(value)", "(other)"),
    Case.new(%w[PM_FLOAT_NODE], [], "float", "process(1.25)", "process(2.5)", "", ""),
    Case.new(%w[PM_RANGE_NODE], [], "range", "process(1...4)", "process(2..5)", "", ""),
    Case.new(%w[PM_SYMBOL_NODE], [], "symbol", "process(:first)", "process(:second)", "", ""),
    Case.new(%w[PM_INTEGER_NODE], [], "integer", "process(1)", "process(2)", "", ""),
    Case.new(%w[PM_TRUE_NODE], [], "true", "process(true)", "process(true)", "", ""),
    Case.new(%w[PM_FALSE_NODE], [], "false", "process(false)", "process(false)", "", ""),
    Case.new(%w[PM_NIL_NODE], [], "nil", "process(nil)", "process(nil)", "", ""),
    Case.new(%w[PM_AND_NODE], [], "and", "left && right", "first && second", "", ""),
    Case.new(%w[PM_OR_NODE], [], "or", "left || right", "first || second", "", ""),
    Case.new(%w[PM_CONSTANT_READ_NODE], [], "constant-read", "process(FirstValue)", "process(SecondValue)", "", ""),
    Case.new(%w[PM_CONSTANT_PATH_NODE], [], "constant-path", "process(First::Value)", "process(Second::Value)", "", ""),
    Case.new(%w[PM_KEYWORD_HASH_NODE], [], "keyword-hash", "process(value: 1)", "process(value: 2)", "", ""),
    Case.new(%w[PM_HASH_NODE PM_ASSOC_NODE], [], "hash", "process({value: 1})", "process({other: 2})", "", ""),
    Case.new(%w[PM_ARRAY_NODE], [], "array", "process([1, 2])", "process([3, 4])", "", ""),
    Case.new(%w[PM_CASE_NODE PM_WHEN_NODE], [], "case", "case value; when 1 then process(2); else process(3); end", "case other; when 4 then process(5); else process(6); end", "", ""),
    Case.new(%w[PM_WHILE_NODE], [], "while", "while ready; process(value); end", "while active; render(other); end", "", ""),
    Case.new(%w[PM_UNTIL_NODE], [], "until", "until ready; process(value); end", "until active; render(other); end", "", ""),
    Case.new(%w[PM_FOR_NODE], [], "for", "for value in values; process(value); end", "for other in others; render(other); end", "", ""),
    Case.new(%w[PM_SELF_NODE], [], "self", "process(self)", "render(self)", "", ""),
    Case.new(%w[PM_SPLAT_NODE], [], "splat", "process(*values)", "process(*others)", "", ""),
    Case.new(%w[PM_BLOCK_NODE PM_BLOCK_PARAMETERS_NODE], [], "block", "items.each { |value| process(value) }", "others.each { |item| render(item) }", "", ""),
    Case.new(%w[PM_PARAMETERS_NODE PM_REQUIRED_PARAMETER_NODE PM_OPTIONAL_PARAMETER_NODE], %w[PM_REQUIRED_PARAMETER_NODE PM_OPTIONAL_PARAMETER_NODE PM_REQUIRED_KEYWORD_PARAMETER_NODE PM_OPTIONAL_KEYWORD_PARAMETER_NODE PM_REST_PARAMETER_NODE PM_KEYWORD_REST_PARAMETER_NODE PM_BLOCK_PARAMETER_NODE], "method-parameters", "process(required)", "render(needed)", "(required, optional = 1, *rest, keyword:, optional_keyword: 2, **keywords, &callback)", "(needed, alternate = 3, *others, named:, other_keyword: 4, **options, &handler)"),
    Case.new(%w[PM_BLOCK_PARAMETERS_NODE PM_OPTIONAL_PARAMETER_NODE], %w[PM_BLOCK_PARAMETERS_NODE], "block-optional-parameter", "items.each { |optional = 1| process(optional) }", "others.each { |alternate = 2| render(alternate) }", "", ""),
    Case.new(%w[PM_INTERPOLATED_REGULAR_EXPRESSION_NODE], [], "interpolated-regexp", '/pre#{value}post/ =~ value', '/pre#{other}post/ =~ other', "(value)", "(other)"),
    Case.new(%w[PM_REGULAR_EXPRESSION_NODE], [], "regexp", "process(/value/)", "process(/other/)", "", ""),
    Case.new(%w[PM_RETURN_NODE], [], "return", "return process(value)", "return render(other)", "", ""),
    Case.new(%w[PM_YIELD_NODE], [], "yield", "yield(value)", "yield(other)", "", ""),
    Case.new(%w[PM_FORWARDING_SUPER_NODE], [], "forwarding-super", "super", "super", "(*args, **kwargs, &block)", "(*options, **keywords, &handler)"),
    Case.new(%w[PM_SUPER_NODE], [], "super", "super(value)", "super(other)", "(value)", "(other)"),
    Case.new(%w[PM_BREAK_NODE], [], "break", "items.each { break value }", "others.each { break other }", "", ""),
    Case.new(%w[PM_REDO_NODE], [], "redo", "items.each { redo }", "others.each { redo }", "", ""),
    Case.new(%w[PM_BEGIN_NODE], [], "begin", "begin; process(value); finish(value); end", "begin; render(other); complete(other); end", "", ""),
    Case.new(%w[PM_BEGIN_NODE PM_RESCUE_NODE PM_RETRY_NODE], [], "rescue", "begin; operation; rescue StandardError; retry; end", "begin; operation; rescue StandardError; retry; end", "", ""),
    Case.new(%w[PM_BEGIN_NODE PM_RESCUE_NODE PM_RETRY_NODE], [], "retry", "begin; process(value); rescue StandardError; retry; end", "begin; render(other); rescue RuntimeError; retry; end", "", ""),
    Case.new(%w[PM_BEGIN_NODE PM_ENSURE_NODE], [], "ensure", "begin; process(value); ensure; finish(value); end", "begin; render(other); ensure; complete(other); end", "", ""),
    Case.new(%w[PM_NEXT_NODE], [], "next", "items.each do |item|; next item if item; item; end", "items.each do |item|; next item if item; item; end", "", ""),
    Case.new(%w[PM_IF_NODE PM_ELSE_NODE], [], "if-else", "if ready then process(value) else finish(value) end", "if active then render(other) else complete(other) end", "", ""),
    Case.new(%w[PM_UNLESS_NODE], [], "unless", "unless ready then process(value) else finish(value) end", "unless active then render(other) else complete(other) end", "", ""),
    Case.new(%w[PM_LOCAL_VARIABLE_WRITE_NODE PM_LOCAL_VARIABLE_OPERATOR_WRITE_NODE PM_IF_NODE PM_ELSE_NODE PM_CALL_NODE PM_BLOCK_NODE PM_BLOCK_PARAMETERS_NODE PM_INTEGER_NODE PM_PARAMETERS_NODE PM_REQUIRED_PARAMETER_NODE PM_OPTIONAL_PARAMETER_NODE],
      %w[PM_REQUIRED_PARAMETER_NODE PM_OPTIONAL_PARAMETER_NODE PM_REQUIRED_KEYWORD_PARAMETER_NODE PM_BLOCK_PARAMETER_NODE], "composed-method",
      "current = process(required, mode); current += 1; if optional; items.map { |value, entry = 2| callback.call(process(value, current)) }; else; process(current, optional); end",
      "total = render(source, state); total += 2; if fallback; rows.map { |item, alternate = 4| handler.call(convert(item, total)) }; else; render(total, fallback); end",
      "(required, optional = 1, mode:, &callback)", "(source, fallback = 3, state:, &handler)", "defn"),
    Case.new(%w[PM_LOCAL_VARIABLE_WRITE_NODE PM_LOCAL_VARIABLE_OPERATOR_WRITE_NODE PM_IF_NODE PM_ELSE_NODE PM_CALL_NODE PM_BLOCK_NODE PM_BLOCK_PARAMETERS_NODE PM_INTEGER_NODE PM_PARAMETERS_NODE PM_REQUIRED_PARAMETER_NODE PM_OPTIONAL_PARAMETER_NODE],
      %w[PM_REQUIRED_PARAMETER_NODE PM_OPTIONAL_PARAMETER_NODE PM_REQUIRED_KEYWORD_PARAMETER_NODE PM_BLOCK_PARAMETER_NODE], "composed-class-method",
      "current = process(required, mode); current += 1; if optional; items.map { |value, entry = 2| callback.call(process(value, current)) }; else; process(current, optional); end",
      "total = render(source, state); total += 2; if fallback; rows.map { |item, alternate = 4| handler.call(convert(item, total)) }; else; render(total, fallback); end",
      "(required, optional = 1, mode:, &callback)", "(source, fallback = 3, state:, &handler)", "defn", "class"),
    Case.new(COMPOSED_NODE_TYPES, COMPOSED_PARAMETER_TYPES, "composed-class-signature-block",
      "rows.map { |value, fallback = 2| callback.call(process(value, optional)) }",
      "records.map { |item, alternate = 4| handler.call(process(item, fallback)) }",
      "(required, optional = 1, *rest, mode:, strict: false, **options, &callback)",
      "(source, fallback = 3, *tail, state:, safe: true, **settings, &handler)", "iter", "class"),
    Case.new(COMPOSED_NODE_TYPES, COMPOSED_PARAMETER_TYPES, "composed-class-three-signatures",
      "rows.map { |value, fallback = 2| callback.call(process(value, optional)) }",
      "records.map { |item, alternate = 4| handler.call(process(item, fallback)) }",
      "(required, optional = 1, *rest, mode:, strict: false, **options, &callback)",
      "(source, fallback = 3, *tail, state:, safe: true, **settings, &handler)", "iter", "class",
      "entries.map { |entry, backup = 6| receiver.call(process(entry, default)) }",
      "(input, default = 5, *extra, context:, enabled: nil, **keywords, &receiver)"),
    Case.new(COMPOSED_NODE_TYPES, COMPOSED_PARAMETER_TYPES, "composed-class-identical-block-trio",
      "rows.map { |value, fallback = 2| callback.call(process(value, optional)) }",
      "rows.map { |value, fallback = 2| callback.call(process(value, optional)) }",
      "(required, optional = 1, *rest, mode:, strict: false, **options, &callback)",
      "(required, optional = 1, *rest, mode:, safe: true, **options, &callback)", "iter", "class",
      "rows.map { |value, fallback = 2| callback.call(process(value, optional)) }",
      "(required, optional = 1, *rest, mode:, enabled: nil, **options, &callback)"),
    Case.new(COMPOSED_NODE_TYPES, COMPOSED_PARAMETER_TYPES, "composed-class-subset-block",
      "rows.map { |value, fallback = 2| callback.call(process(value, optional)) }",
      "records.map { |item, alternate = 4| handler.call(process(item, fallback)) }",
      "(required, optional = 1, *rest, mode:, strict: false, **options, &callback)",
      "(source, fallback = 3, *tail, state:, safe: true, **settings, &handler)", "iter", "class",
      "entries.each { |entry| receiver.process(entry, default) }",
      "(input, default = 5, *extra, context:, enabled: nil, **keywords, &receiver)", 2)
  ].freeze
  def self.verify
    root = ENV["FLEEK_TEMP_ROOT"] || "/tmp"
    run_id = Process.pid
    evidence_path = "#{root}/generated-descriptor-#{run_id}.report"
    File.write(evidence_path, NODE_CASES.map(&:name).join("\n") + "\n")
    verify_inventory
    verify_generated_candidates(root, evidence_path)
  ensure
    File.delete(evidence_path) if evidence_path && !ENV.key?("FLEEK_TEMP_ROOT") && File.file?(evidence_path)
  end

  def self.verify_inventory
    source = File.read("bin/fleek.rb")
    node_table = table_source(source, "fleek_duplication_node_rules", "#undef FLEEK_NAMED_NODE_RULE")
    parameter_table = table_source(source, "fleek_duplication_parameter_rules", "static const fleek_duplication_parameter_rule_t *")
    node_types = node_table.scan(/\[(PM_[A-Z_]+_NODE)\]\s*=\s*\{[^}]*\btrue\b/m).flatten
    node_types.concat(node_table.scan(/FLEEK_(?:NAMED|OPERATOR)_NODE_RULE\((PM_[A-Z_]+_NODE),/).flatten)
    parameter_types = parameter_table.scan(/\[(PM_[A-Z_]+_NODE)\]\s*=\s*\{\s*\.supported\s*=\s*true/).flatten
    assert_inventory("node", node_types.uniq, case_types(NODE_CASES, true))
    assert_inventory("parameter", parameter_types.uniq, case_types(NODE_CASES, false))
    assert_node_identity(node_table, "PM_RANGE_NODE", "RANGE")
    assert_node_identity(node_table, "PM_REGULAR_EXPRESSION_NODE", "REGULAR_EXPRESSION")
    assert_node_identity(node_table, "PM_INTERPOLATED_REGULAR_EXPRESSION_NODE", "INTERPOLATED_REGULAR_EXPRESSION")
  end

  def self.assert_node_identity(table, node, identity)
    entry = table.match(/\[#{node}\]\s*=\s*\{([^}]*)\}/m)
    unless entry && entry[1].include?("FLEEK_DUPLICATION_IDENTITY_#{identity}")
      raise "generated Flay node descriptor omits #{identity} identity for #{node}"
    end
  end

  def self.table_source(source, marker, ending)
    start = source.index(marker)
    finish = source.index(ending, start)
    raise "missing Flay descriptor table #{marker}" unless start && finish
    source[start...finish]
  end

  def self.case_types(cases, node_types)
    types = []
    cases.each do |item|
      types.concat(node_types ? item.node_types : item.parameter_types)
    end
    types.uniq
  end

  def self.assert_inventory(label, implementation, catalog)
    missing = implementation - catalog
    unexpected = catalog - implementation
    unless missing.empty? && unexpected.empty?
      raise "generated Flay #{label} descriptor inventory differs: missing=#{missing.join(',')} unexpected=#{unexpected.join(',')}"
    end
  end

  def self.verify_generated_candidates(root, evidence_path)
    run = Run.new(Process.pid, root, "#{root}/fleek-generated-descriptor-cases-#{Process.pid}", [], [], [], [], evidence_path)
    begin
      run.paths = write_candidates(run)
      native_results = run_cases(run, "descriptor", :fleek)
      reference_results = run_cases(run, "reference", :flay)
      verify_generated_reports(native_results, reference_results, run)
      verify_generated_boundaries(run)
      verify_multiple_block_groups(run)
    ensure
      cleanup_run(run)
    end
  end

  def self.write_candidates(run)
    Dir.mkdir(run.directory)
    paths = []
    NODE_CASES.each do |item|
      path = "#{run.directory}/#{item.name}.rb"
      source = "def transform#{item.first_parameters}\n  #{item.first_body}\nend\n\n"
      source << "def transform#{item.second_parameters}\n  #{item.second_body}\nend\n\n"
      source << "def transform#{item.third_parameters}\n  #{item.third_body}\nend\n\n" if item.third_body
      if item.scope == "class"
        source = "class ComposedMethods\n#{source.lines.map { |line| "  #{line}" }.join}end\n"
      end
      File.write(path, source)
      paths << path
      run.expected_locations << candidate_lines(path, item)
    end
    File.write(run.evidence_path, NODE_CASES.map do |item|
      "#{item.name}: nodes=#{item.node_types.join(',')} parameters=#{item.parameter_types.join(',')}"
    end.join("\n") + "\n")
    paths
  end

  def self.class_scoped?(item)
    item.scope == "class"
  end

  def self.iter_group?(item)
    item.expected_node == "iter"
  end

  def self.first_candidate_line(item)
    return 1 unless class_scoped?(item)

    iter_group?(item) ? 3 : 2
  end

  def self.second_candidate_line(item)
    return 5 unless class_scoped?(item)

    iter_group?(item) ? 7 : 6
  end

  def self.candidate_lines(path, item)
    count = item.expected_candidates || (item.third_body ? 3 : 2)
    first = class_scoped?(item) && iter_group?(item) ? 3 : first_candidate_line(item)
    (0...count).map { |index| "#{path}:#{first + index * 4}" }
  end

  def self.verify_generated_boundaries(run)
    clean = "#{run.directory}/clean.rb"
    class_clean = "#{run.directory}/class-clean.rb"
    boundary = "#{run.directory}/unsupported.rb"
    class_boundary = "#{run.directory}/class-unsupported.rb"
    File.write(clean, "def transform\n  process(value)\nend\n\ndef transform\n  return\nend\n")
    File.write(class_clean, "class ComposedMethods\n  def transform\n    process(value)\n  end\n\n  def transform\n    return\n  end\nend\n")
    File.write(boundary, "def transform(value = [])\n  process(value)\nend\n\ndef transform(value = [])\n  process(value)\nend\n")
    File.write(class_boundary, "class ComposedMethods\n  def transform(value = [])\n    process(value)\n  end\n\n  def transform(value = [])\n    process(value)\n  end\nend\n")
    FlayMethodCandidateContract.verify_no_group(clean, "generated-descriptor-#{run.id}-clean")
    FlayMethodCandidateContract.verify_no_group(class_clean, "generated-descriptor-#{run.id}-class-clean")
    FlayMethodCandidateContract.verify_unsupported(boundary, "generated-descriptor-#{run.id}-boundary", 24)
    FlayMethodCandidateContract.verify_unsupported(class_boundary, "generated-descriptor-#{run.id}-class-boundary", 24, "defn", [2, 6])
  end

  def self.verify_multiple_block_groups(run)
    path = "#{run.directory}/multiple-block-groups.rb"
    source = <<~RUBY
      class ComposedMethods
        def transform(strict: false)
          rows.map { |value, fallback = 1| value }
          records.select { |item, fallback = 1| process(item) }
        end

        def transform(safe: true)
          rows.map { |value, fallback = 1| value }
          records.select { |item, fallback = 1| process(item) }
        end
      end
    RUBY
    File.write(path, source)
    native = run_single_case(run, path, "multi-block-native", :fleek)
    reference = run_single_case(run, path, "multi-block-reference", :flay)
    native_groups = parse_native_groups(native[1], path, "iter")
    reference_groups = parse_reference_groups(reference[1], path, "iter")
    expected = [["#{path}:3", "#{path}:8"], ["#{path}:4", "#{path}:9"]]
    unless native[0] == 2 && native[2].empty? && reference[0].zero? && native_groups == reference_groups &&
        native_groups.map(&:locations).sort_by(&:first) == expected.sort_by(&:first) && native_groups.length == 2 &&
        native[1].include?("Status: findings") && native[1].include?("Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded")
      raise "composed class multiple-block groups differed: Flay status=#{reference[0]} groups=#{reference_groups.inspect} #{reference[1]} Fleek status=#{native[0]} groups=#{native_groups.inspect} #{native[1]}"
    end
    puts "generated-descriptor-#{run.id}-multiple-block-groups contract: pass"
  end

  def self.run_single_case(run, path, prefix, kind)
    output, error = worker_paths(run, prefix, 0)
    paths = reference_run?(kind) ? run.reference_output_paths : run.output_paths
    paths.concat([output, error])
    process_id = spawn_case(kind, path, output, error)
    _, status = Process.waitpid2(process_id)
    [status.exitstatus, File.read(output), File.read(error)]
  end

  def self.run_cases(run, prefix, kind)
    requested_jobs = ENV["JOBS"] ? Integer(ENV["JOBS"], 10) : 4
    raise "JOBS must be positive" unless requested_jobs.positive?
    jobs = ENV["FLEEK_TEMP_ROOT"] ? [requested_jobs, MAX_NESTED_WORKERS].min : requested_jobs
    pending = run.paths.each_with_index.to_a
    running = []
    results = Array.new(run.paths.length)
    output_paths = reference_run?(kind) ? run.reference_output_paths : run.output_paths
    while !pending.empty? || !running.empty?
      while running.length < jobs && !pending.empty?
        path, index = pending.shift
        output, error = worker_paths(run, prefix, index)
        output_paths.concat([output, error])
        process_id = spawn_case(kind, path, output, error)
        running << [process_id, index, output, error]
      end
      process_id, status = Process.waitpid2(-1)
      entry = running.find { |item| item[0] == process_id }
      raise "generated Flay worker exited unexpectedly: #{process_id}" unless entry
      running.delete(entry)
      _, index, output, error = entry
      results[index] = [status.exitstatus, File.read(output), File.read(error)]
    end
    results
  end

  def self.worker_paths(run, prefix, index)
    stem = "#{run.root}/fleek-generated-#{prefix}-#{Process.pid}-#{index}"
    ["#{stem}.out", "#{stem}.err"]
  end

  def self.spawn_case(kind, path, output, error)
    return FlayMethodCandidateContract.spawn_flay(path, output, error) if reference_run?(kind)

    FlayMethodCandidateContract.spawn_fleek(path, output, error)
  end

  def self.reference_run?(kind)
    kind == :flay
  end

  def self.verify_generated_reports(native_results, reference_results, run)
    reference_groups = []
    native_groups = []
    native_total = 0
    native_results.each_with_index do |result, index|
      status, output, error = result
      expected_node = NODE_CASES[index].expected_node || "defn"
      groups = parse_native_groups(output, run.paths[index], expected_node)
      verify_single_group(status, 2, error, groups, NODE_CASES[index].name, output)
      coverage = "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded"
      unless output.include?(coverage) && output.include?("Status: findings")
        raise "generated Flay case #{NODE_CASES[index].name} coverage differed: #{output}"
      end
      native_total += groups[0].score
      native_groups << groups[0]
    end
    reference_total = 0
    reference_results.each_with_index do |result, index|
      status, output, error = result
      expected_node = NODE_CASES[index].expected_node || "defn"
      groups = parse_reference_groups(output, run.paths[index], expected_node)
      verify_single_group(status, 0, error, groups, NODE_CASES[index].name, output)
      reported_total = capture(output, /Total score \(lower is better\) = (\d+)/, 1)
      unless reported_total && reported_total.to_i == groups[0].score
        raise "generated Flay total score differed for #{NODE_CASES[index].name}: #{output}"
      end
      reference_total += groups[0].score
      reference_groups << groups[0]
    end
    expected_count = NODE_CASES.length
    unless reference_groups.length == expected_count && native_groups.length == expected_count
      actual_locations = []
      reference_groups.each { |group| actual_locations << group.locations }
      missing = run.expected_locations - actual_locations
      raise "generated Flay descriptor group count differed: expected=#{expected_count} Flay=#{reference_groups.length} Fleek=#{native_groups.length} missing=#{missing.inspect}"
    end
    differences = []
    reference_groups.each_with_index do |reference, index|
      actual = native_groups[index]
      expected_locations = run.expected_locations[index]
      unless reference.locations == expected_locations && actual.locations == expected_locations && actual == reference
        differences << "#{expected_locations.first} Flay=#{reference.inspect} Fleek=#{actual.inspect}"
      end
    end
    unless differences.empty?
      raise "generated Flay descriptor results differed: #{differences.join('; ')}"
    end
    actual_locations = []
    reference_groups.each { |group| actual_locations << group.locations }
    unless run.expected_locations.length == expected_count && actual_locations == run.expected_locations
      raise "generated Flay descriptor ordering differed"
    end
    expected_total = 0
    reference_groups.each { |group| expected_total += group.score }
    unless native_total == expected_total && reference_total == expected_total
      raise "generated Flay total score differed: Fleek=#{native_total} Flay=#{reference_total}"
    end
    File.write(run.evidence_path, reference_groups.each_with_index.map do |group, index|
      "#{NODE_CASES[index].name}: #{group.kind} mass=#{group.mass} score=#{group.score} locations=#{group.locations.join(',')}"
    end.join("\n") + "\n")
  end

  def self.verify_single_group(status, expected_status, error, groups, name, output)
    return if status == expected_status && error.empty? && groups.length == 1

    raise "generated Flay case #{name} failed: #{output} #{error}"
  end

  def self.cleanup_run(run)
    Dir.glob("#{run.directory}/*.rb").each { |file| File.delete(file) }
    Dir.rmdir(run.directory) if Dir.exist?(run.directory)
    (run.output_paths + run.reference_output_paths).each { |file| File.delete(file) if File.file?(file) }
    File.delete(run.evidence_path) if !ENV.key?("FLEEK_TEMP_ROOT") && File.file?(run.evidence_path)
  end

  def self.parse_reference_groups(output, directory, node)
    groups = []
    current = nil
    output.lines.each do |line|
      header = line.match(/^\d+\) (Similar|IDENTICAL) code found in :#{node} \(mass(\*(\d+))? = (\d+)\)$/)
      if header
        mass = header[4].to_i
        multiplier = header[3] ? header[3].to_i : 1
        mass /= multiplier
        current = Group.new(header[1] == "IDENTICAL" ? "identical" : "similar", mass, mass * multiplier, [])
        groups << current
      elsif current && line.strip.start_with?("#{directory}:")
        current.locations << line.strip
      end
    end
    groups
  end

  def self.parse_native_groups(output, path, node)
    groups = []
    output.lines.each do |line|
      next unless line.include?("node=\"#{node}\"")
      locations = capture(line, /locations="([^"]+)"/, 1)
      next unless locations
      lines = []
      locations.split(",").each do |location|
        next unless location.start_with?("#{path}:")
        lines << location
      end
      groups << Group.new(capture(line, /kind="([^"]+)"/, 1), capture(line, / mass=(\d+)/, 1).to_i,
        capture(line, / score=(\d+)/, 1).to_i, lines)
    end
    groups
  end

  def self.capture(text, pattern, index)
    match = text.match(pattern)
    match ? match[index] : nil
  end
end

FlayGeneratedDescriptorContract.verify
