# frozen_string_literal: true

require_relative "analysis_runner"

# Protects the class-method-before-class-group ordering exposed by the public CLI.
class DuplicationGroupOrderContract
  PATH = "test/fixtures/duplication_class_methods_class_group_with_conditional_pair.rb"
  DEFN_GROUP = "node=\"defn\" kind=\"similar\" locations=\"#{PATH}:20,#{PATH}:32\" mass=62 score=62"
  CLASS_GROUP = "node=\"class\" kind=\"similar\" locations=\"#{PATH}:1,#{PATH}:10\" mass=50 score=50"
  REFERENCE_DEFN = "Similar code found in :defn (mass = 62)"
  REFERENCE_CLASS = "Similar code found in :class (mass = 50)"

  # :reek:TooManyStatements
  def self.run
    actual = invoke("fleek")
    reference = invoke("flay")
    verify_actual(actual)
    verify_reference(reference)
    verify_group_order(actual[1])
    puts "Duplication group order contract: pass"
  end

  # :reek:TooManyStatements
  def self.invoke(tool)
    root = ENV.fetch("FLEEK_TEMP_ROOT", "/tmp")
    output = "#{root}/duplication-group-order-#{tool}.out"
    error = "#{root}/duplication-group-order-#{tool}.err"
    process_id = if tool == "fleek"
      Process.spawn("build/fleek", "--checks", "flay:StructuralDuplication", PATH, out: output, err: error)
    else
      Process.spawn(ENV["BUNDLE"] || "bundle", "exec", "flay", PATH, out: output, err: error)
    end
    AnalysisRunner.observe(process_id, output, error)
  end

  # :reek:TooManyStatements
  def self.verify_actual(result)
    output = result[1]
    fields = [DEFN_GROUP, CLASS_GROUP, "Total duplication score: 112",
      "File duplication score: \"#{PATH}\" score=112", "Coverage: 1 selected; 1 analyzed; 0 failed; 0 excluded", "Status: findings"]
    raise "Flay group ordering differed: actual status changed" unless result[0] == 2
    fields.each { |field| raise "Flay group ordering differed: missing #{field}" unless output.include?(field) }
    raise "Flay group ordering differed: unexpected CLI error" unless result[2].empty?
  end

  def self.verify_reference(result)
    fields = [REFERENCE_DEFN, "#{PATH}:20", "#{PATH}:32", REFERENCE_CLASS, "#{PATH}:1", "#{PATH}:10",
      "Total score (lower is better) = 112"]
    AnalysisRunner.assert_report_contains(result, [0, fields, "Flay group ordering differed: pinned Flay reference changed"])
    raise "Flay group ordering differed: pinned Flay error" unless result[2].empty?
  end

  def self.verify_group_order(output)
    defn_position = output.index(DEFN_GROUP)
    class_position = output.index(CLASS_GROUP)
    raise "Flay group ordering differed" unless defn_position && class_position && defn_position < class_position
  end
end

DuplicationGroupOrderContract.run
