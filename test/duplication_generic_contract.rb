require_relative "flay_groups"

# Compares the generic Flay sexp engine with pinned Flay 2.14.4 on whole-file fixtures.
# :reek:DuplicateMethodCall
# :reek:TooManyStatements
class FlayGenericContract
  # One CLI comparison: source paths plus shared Flay options.
  Case = Struct.new(:paths, :options)
  ROOT = "test/fixtures/flay_generic"
  CASES = [
    Case.new(["#{ROOT}/core_methods.rb"], ""),
    Case.new(["#{ROOT}/rails_model.rb"], ""),
    Case.new(["#{ROOT}/identical_classes.rb"], ""),
    Case.new(["#{ROOT}/namespaces.rb"], ""),
    Case.new(["#{ROOT}/parameters.rb"], ""),
    Case.new(["#{ROOT}/top_level.rb"], ""),
    Case.new(["#{ROOT}/top_level.rb"], "--liberal"),
    Case.new(["#{ROOT}/namespaces.rb"], "--liberal"),
    Case.new(["#{ROOT}/top_level.rb"], "--mass 20"),
    Case.new(["#{ROOT}/cross_file_first.rb", "#{ROOT}/cross_file_second.rb"], ""),
    Case.new(["#{ROOT}/root_first.rb", "#{ROOT}/root_second.rb"], ""),
    Case.new(["#{ROOT}/root_both.rb"], ""),
    Case.new(["#{ROOT}/logical_chain.rb"], "--mass 7"),
    Case.new(["#{ROOT}/unless_identity.rb"], "--mass 8"),
    Case.new(["#{ROOT}/class_variable_scope.rb"], "--mass 4"),
    Case.new(["#{ROOT}/liberal_pruning.rb"], "--liberal --mass 5"),
    Case.new(["#{ROOT}/core_methods.rb", "#{ROOT}/top_level.rb"], "--fuzzy 1")
  ].freeze

  def self.verify
    CASES.each { |item| verify_case(item) }
    puts "Generic Flay engine contract: pass"
  end

  def self.verify_case(item)
    label = "#{item.options} #{item.paths.join(" ")}"
    native = run(command(["build/fleek", "--checks", "flay:StructuralDuplication"], item), "/tmp/fleek-generic-out")
    reference = run(command([ENV["BUNDLE"] || "bundle", "exec", "flay"], item), "/tmp/flay-generic-out")
    count = item.paths.length
    coverage = "Coverage: #{count} selected; #{count} analyzed; 0 failed; 0 excluded"
    raise "generic engine left #{label} incomplete" unless native.index(coverage)
    expected = FlayGroups.reference(reference)
    raise "Flay reported no groups for #{label}" if expected.empty?
    actual = FlayGroups.native(native)
    raise "generic engine differed for #{label}: #{actual.inspect} != #{expected.inspect}" unless actual == expected
  end

  def self.command(prefix, item)
    arguments = prefix
    arguments.concat(item.options.split(" "))
    arguments.concat(item.paths)
    arguments
  end

  # Spinel 2026.09.12 rejects splatted spawn arguments, so dispatch on arity.
  # :reek:FeatureEnvy
  def self.run(arguments, output)
    error = "#{output}.err"
    process_id = case arguments.length
      when 4 then Process.spawn(arguments[0], arguments[1], arguments[2], arguments[3], out: output, err: error)
      when 5 then Process.spawn(arguments[0], arguments[1], arguments[2], arguments[3], arguments[4], out: output, err: error)
      when 6 then Process.spawn(arguments[0], arguments[1], arguments[2], arguments[3], arguments[4], arguments[5], out: output, err: error)
      else Process.spawn(arguments[0], arguments[1], arguments[2], arguments[3], arguments[4], arguments[5], arguments[6], out: output, err: error)
    end
    Process.waitpid2(process_id)
    File.read(output)
  end

end

FlayGenericContract.verify
