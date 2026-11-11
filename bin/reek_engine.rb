# Ports Reek 6.6.0's AST helpers, comment association and context tree (ADR 0257).
# Input is the annotated parser-gem AST emitted by Fleek's native translation.
# The code mirrors Reek and parser gem algorithms nearly line for line so parity stays reviewable,
# so their structure (mutable AST fields, nil checks, scanner loops) is kept rather than reshaped.
# :reek:Attribute
# :reek:ControlParameter
# :reek:DuplicateMethodCall
# :reek:LongParameterList
# :reek:FeatureEnvy
# :reek:NestedIterators
# :reek:NilCheck
# :reek:RepeatedConditional
# :reek:TooManyConstants
# :reek:TooManyInstanceVariables
# :reek:TooManyMethods
# :reek:TooManyStatements
# :reek:UtilityFunction
module ReekEngine
  ATOM = "atom".freeze

  # A parser-gem AST node, or an atom child such as a symbol, string, number or nil.
  class Node
    attr_reader :type, :children, :value, :line, :begin_pos, :end_pos, :heredoc
    attr_accessor :last_line, :comments, :key

    def initialize(type, value, location)
      @type = type
      @value = value
      @line = location[0]
      @begin_pos = location[1]
      @end_pos = location[2]
      @heredoc = location[3] == 1
      @children = []
      @last_line = 0
      @comments = []
      @key = ""
    end

    def atom?
      @type == ATOM
    end

    def nil_atom?
      atom? && @value == "nil"
    end

    def located?
      @begin_pos >= 0
    end

    def nodes
      @children.reject { |child| child.atom? }
    end

    # A symbol atom's name (":foo" or ":\"foo bar\"" -> "foo").
    def symbol_name
      text = @value[1, @value.length - 1]
      text.start_with?("\"") ? text[1, text.length - 2] : text
    end

    def child(index)
      @children[index]
    end

    # Reek::AST::Node#format_to_ruby over the original source.
    def format_to_ruby(source)
      return @value if atom?
      return @type unless located?
      lines = source.byteslice(@begin_pos, @end_pos - @begin_pos).split("\n").map { |line| line.strip }
      return lines.first.to_s if lines.length <= 1
      return lines.join("; ") if lines.length == 2
      "#{lines.first} ... #{lines.last}"
    end

    # Reek::AST::Node#leading_comment: comments that start before this node's first line.
    def leading_comment
      @comments.select { |comment| comment.line < @line }.map { |comment| comment.text }.join("\n")
    end

    # Body statements for module-like nodes (ModuleNodeBase#direct_children).
    def statements
      return @children if @type == "begin"
      [self]
    end
  end

  # A source comment from the native comment list.
  class Comment
    attr_reader :text, :begin_pos, :end_pos, :line, :last_line

    def initialize(text, range, lines)
      @text = text
      @begin_pos = range[0]
      @end_pos = range[1]
      @line = lines[0]
      @last_line = lines[1]
    end
  end

  # Line numbers for byte offsets.
  class LineIndex
    def initialize(source)
      @starts = [0]
      index = 0
      source.each_byte do |byte|
        index += 1
        @starts << index if byte == 10
      end
    end

    # The line containing offset (Parser::Source::Buffer#line_for_position).
    def line_for(offset)
      low = 0
      high = @starts.length - 1
      while low < high
        middle = (low + high + 1) / 2
        if @starts[middle] <= offset
          low = middle
        else
          high = middle - 1
        end
      end
      low + 1
    end
  end

  # Parses the annotated S-expression text: (type@line:begin:end[:h] child ...).
  class Reader
    def initialize(text)
      @text = text
      @position = 0
    end

    def read
      skip_spaces
      return nil if @position >= @text.length
      read_node
    end

    private

    def skip_spaces
      @position += 1 while @position < @text.length && @text[@position] == " "
    end

    def read_node
      @position += 1
      type_start = @position
      @position += 1 while @position < @text.length && !"@ )".include?(@text[@position])
      type = @text[type_start, @position - type_start]
      node = Node.new(type, "", read_location)
      loop do
        skip_spaces
        break if @text[@position] == ")"
        node.children << read_child
      end
      @position += 1
      node
    end

    def read_location
      return [0, -1, -1, 0] unless @text[@position] == "@"
      @position += 1
      parts = read_token.split(":")
      [parts[0].to_i, parts[1].to_i, parts[2].to_i, parts.length > 3 ? 1 : 0]
    end

    def read_child
      char = @text[@position]
      return read_node if char == "(" && letter?(@text[@position + 1])
      return read_until_close if char == "("
      return read_quoted(0) if char == "\""
      return read_quoted(1) if char == ":" && @text[@position + 1] == "\""
      atom(read_token)
    end

    # Reads up to the next space or closing parenthesis.
    def read_token
      start = @position
      @position += 1 while @position < @text.length && @text[@position] != " " && @text[@position] != ")"
      @text[start, @position - start]
    end

    def letter?(char)
      !char.nil? && char >= "a" && char <= "z"
    end

    def read_until_close
      start = @position
      @position += 1 while @text[@position] != ")"
      @position += 1
      atom(@text[start, @position - start])
    end

    def read_quoted(prefix)
      start = @position
      @position += prefix + 1
      while @text[@position] != "\""
        @position += 1 if @text[@position] == "\\"
        @position += 1
      end
      @position += 1
      atom(@text[start, @position - start])
    end

    def atom(value)
      Node.new(ATOM, value, [0, -1, -1, 0])
    end
  end

  # Parser::Source::Comment::Associator in its :eql mapping mode.
  class Associator
    POSTFIX_TYPES = %w[if while while_post until until_post masgn].freeze

    def initialize(root, comments)
      @root = root
      @comments = comments
      @index = 0
      @mapping = {}
    end

    def associate
      skip_directives
      visit(@root) if @root
      @mapping
    end

    private

    def current
      @comments[@index]
    end

    def skip_directives
      advance if current && current.text.start_with?("#!")
      advance if current && current.text.match?(/\A#\s*(-\*-|)\s*(frozen_string_literal|warn_indent|warn_past_scope):.*\1\z/)
      advance if current && current.text.match?(/\A#.*coding\s*[:=]\s*([\w.-]+)/)
    end

    def advance
      @index += 1
    end

    def visit(node)
      process_leading(node)
      return unless current
      if current.line <= node.last_line || node.heredoc
        children_in_source_order(node).each { |child| visit(child) }
        process_trailing(node)
      end
    end

    def children_in_source_order(node)
      located = node.nodes.select { |child| child.located? }
      return located unless POSTFIX_TYPES.include?(node.type)
      located.sort_by { |child| child.begin_pos }
    end

    def process_leading(node)
      return if node.type == "begin"
      associate_current(node) while current && current.end_pos <= node.begin_pos
    end

    def process_trailing(node)
      associate_current(node) while current && current.end_pos <= node.end_pos
      associate_current(node) while current && current.line == node.last_line
    end

    def associate_current(node)
      bucket = @mapping[node.key]
      bucket = @mapping[node.key] = [] if bucket.nil?
      bucket << current
      advance
    end
  end

  # Builds nodes, lines, structural keys and comments for one source.
  class Tree
    attr_reader :root, :source

    def initialize(text, comment_ranges, source)
      @source = source
      @lines = LineIndex.new(source)
      @root = Reader.new(text).read
      @comments = comment_ranges.split("\n").map { |record| comment(record) }
      return unless @root
      prepare(@root)
      dress(@root, Associator.new(@root, @comments).associate)
    end

    private

    def comment(record)
      range = record.split("\t").map { |value| value.to_i }
      text = @source.byteslice(range[0], range[1] - range[0]).sub(/\n\z/, "")
      Comment.new(text, range, [@lines.line_for(range[0]), @lines.line_for(range[1])])
    end

    # Sets last lines and Parser::AST::Node#eql? keys bottom-up.
    def prepare(node)
      node.children.each { |child| prepare(child) unless child.atom? }
      node.last_line = node.located? ? @lines.line_for(node.end_pos) : 0
      node.key = "(#{node.type} #{node.children.map { |child| child.atom? ? child.value : child.key }.join(" ")})"
    end

    # TreeDresser: every node receives the comments mapped to structurally equal nodes.
    def dress(node, mapping)
      found = mapping[node.key]
      node.comments = found unless found.nil?
      node.children.each { |child| dress(child, mapping) unless child.atom? }
    end
  end

  # Reek::Context::VisibilityTracker over string visibilities and symbol-atom names.
  class VisibilityTracker
    MODIFIERS = %w[private public protected module_function].freeze
    SINGLETON_MODIFIERS = { "public_class_method" => "public", "private_class_method" => "private" }.freeze
    attr_reader :tracked

    def initialize
      @tracked = "public"
    end

    def track(children, visibility, names)
      return unless MODIFIERS.include?(visibility)
      if names.empty?
        @tracked = visibility
      else
        children.each { |child| child.visibility = visibility if names.include?(child.name) }
      end
    end

    def track_singleton(children, visibility, names)
      return if names.empty?
      track(children, SINGLETON_MODIFIERS.fetch(visibility, ""), names)
    end
  end

  # Reek::Context::CodeContext and its subclasses, reduced to what ported detectors use.
  # Kinds: root, module (class, module, module-defining casgn), refinement, ghost (sclass),
  # method, singleton_method, send, attribute and singleton_attribute.
  class Context
    MODULE_KINDS = %w[module refinement ghost].freeze
    attr_reader :exp, :children, :kind, :parent_exp, :refs
    attr_accessor :parent, :statements, :visibility

    def initialize(kind, exp, parent_exp)
      @kind = kind
      @exp = exp
      @parent_exp = parent_exp
      @children = []
      @parent = nil
      @statements = 0
      @visibility = "public"
      @refs = {}
      @tracker = VisibilityTracker.new
    end

    def method_context?
      @kind == "method" || @kind == "singleton_method"
    end

    def module_context?
      @kind == "module"
    end

    # ModuleContext and its RefinementContext and GhostContext subclasses.
    def module_like?
      MODULE_KINDS.include?(@kind)
    end

    def singleton_method?
      @kind == "singleton_method"
    end

    def instance_method?
      @kind == "method" || @kind == "attribute"
    end

    # #method_context_class: ghosts define singleton methods; methods nest their own kind.
    def method_kind
      return "singleton_method" if @kind == "ghost"
      method_context? ? @kind : "method"
    end

    def attribute_kind
      @kind == "ghost" ? "singleton_attribute" : "attribute"
    end

    # The symbol atom naming a method or attribute, compared with visibility modifier arguments.
    def name
      first = @exp.child(@exp.type == "defs" ? 1 : 0)
      first.nil? || !first.atom? ? "-" : first.value
    end

    # GhostContext registers only its children, with its parent.
    def register_with_parent(parent)
      @parent = @kind == "ghost" ? parent : parent.append_child(self)
    end

    # #append_child_context: returns the child's parent after applying tracked visibility.
    def append_child(child)
      real = @kind == "ghost" ? @parent.append_child(child) : self
      child.apply_visibility(@tracker.tracked) if module_like?
      @children << child
      real
    end

    def apply_visibility(current)
      case @kind
      when "method", "attribute", "singleton_attribute" then @visibility = current
      when "singleton_method" then @visibility = current if @exp.type == "def"
      end
    end

    # ModuleContext#track_visibility and the GhostContext override.
    def track_visibility(visibility, names)
      if @kind == "ghost"
        @tracker.track(@children, visibility, names)
      else
        @tracker.track(@children.select { |child| child.instance_method? }, visibility, names)
        @tracker.track_singleton(@children.select { |child| child.singleton_method? }, visibility, names)
      end
    end

    # CodeContext#record_call_to: implicit or explicit self, or a local variable that is not sent new.
    def record_call_to(exp)
      receiver = exp.child(0)
      type = receiver.atom? ? "self" : receiver.type
      case type
      when "lvar", "lvasgn" then record(receiver.child(0).symbol_name, exp.line) unless exp.child(1).value == ":new"
      when "self" then record("self", exp.line)
      end
    end

    def record_use_of_self
      @kind == "ghost" ? @parent.record_use_of_self : record("self", 0)
    end

    def record(name, line)
      lines = @refs[name]
      lines = @refs[name] = [] if lines.nil?
      lines << line
    end

    # GhostContext#statement_counter belongs to its parent.
    def statement_counter
      @kind == "ghost" ? @parent.statement_counter : self
    end

    # #full_comment: methods fall back to their parent expression; attributes use their send.
    def full_comment
      return comment_of(@parent_exp) if @kind.end_with?("attribute")
      own = comment_of(@exp)
      own.empty? && method_context? ? comment_of(@parent_exp) : own
    end

    def comment_of(exp)
      exp.nil? ? "" : exp.comments.map { |found| found.text }.join("\n")
    end

    # Pre-order traversal like CodeContext#each.
    def each
      yield self
      @children.each { |child| child.each { |found| yield found } }
    end
  end

  # Reek::ContextBuilder: walks the AST creating root, module, ghost, method and send contexts.
  class ContextBuilder
    attr_reader :root

    def initialize(tree)
      @source = tree.source
      @root = Context.new("root", tree.root, nil)
      @current = @root
      build(tree.root, nil) if tree.root
    end

    private

    def build(exp, parent_exp)
      case exp.type
      when "module", "class" then inside(Context.new("module", exp, nil), exp)
      when "sclass" then inside(Context.new("ghost", exp, nil), exp)
      when "casgn" then defines_module?(exp) ? inside(Context.new("module", exp, nil), exp) : process(exp)
      when "def" then inside(Context.new(@current.method_kind, exp, parent_exp), exp) { count(exp.child(2)) }
      when "defs" then inside(Context.new("singleton_method", exp, parent_exp), exp) { count(exp.child(3)) }
      when "send" then process_send(exp)
      when "op_asgn"
        @current.record_call_to(exp)
        process(exp)
      when "ivar", "ivasgn", "self", "super", "zsuper"
        @current.record_use_of_self
        process(exp)
      else
        count_statements(exp)
        refinement?(exp) ? inside(Context.new("refinement", exp, nil), exp) : process(exp)
      end
    end

    # A refine block opens a RefinementContext.
    def refinement?(exp)
      return false unless exp.type == "block"
      call = exp.child(0)
      (call.type == "send" || call.type == "csend") && call.child(1).value == ":refine"
    end

    # #handle_send_for_modules and #handle_send_for_methods, after processing the arguments.
    def process_send(exp)
      process(exp)
      args = exp.children[2, exp.children.length - 2]
      if @current.module_like?
        @current.track_visibility(exp.child(1).symbol_name, args.map { |arg| symbol_value(arg.child(0)) })
        register_attributes(exp, args)
      elsif @current.method_context?
        Context.new("send", exp, nil).register_with_parent(@current)
        @current.record_call_to(exp)
      end
    end

    # A visibility argument's first child when it is a symbol (sym and def arguments).
    def symbol_value(first)
      first.nil? || !first.atom? || !first.value.start_with?(":") ? "" : first.value
    end

    # SendNode#attribute_writer?: attr_writer, attr_accessor, or attr with a trailing true.
    def register_attributes(exp, args)
      name = exp.child(1).value
      writable = !args.empty? && args.last.type == "true" && name == ":attr"
      return unless name == ":attr_writer" || name == ":attr_accessor" || writable
      args.each { |arg| Context.new(@current.attribute_kind, arg, exp).register_with_parent(@current) }
    end

    # StatementCounter updates made by ContextBuilder#process_* before descending.
    def count_statements(exp)
      children = exp.children
      case exp.type
      when "block" then count(exp.child(2))
      when "begin", "kwbegin" then count_list(children.length - 1)
      when "if" then count_list(count_value(exp.child(1)) + count_value(exp.child(2)) - 1)
      when "while", "until" then count_list(count_value(exp.child(1)) - 1)
      when "for" then count_list(count_value(exp.child(2)) - 1)
      when "rescue" then count_list(count_value(exp.child(0)) - 1)
      when "resbody" then count_list(children[1, children.length - 1].reject { |child| child.nil_atom? }.length)
      when "case" then count_list(count_value(children.last) - 1)
      when "when" then count(children.last)
      end
    end

    # StatementCounter#increase_by: a node counts one; nil adds nothing.
    def count_value(exp)
      exp.nil? || exp.nil_atom? ? 0 : 1
    end

    def count(exp)
      count_list(count_value(exp))
    end

    def count_list(amount)
      @current.statement_counter.statements += amount
    end

    def process(exp)
      exp.children.each { |child| build(child, exp) unless child.atom? }
    end

    def inside(context, exp)
      context.register_with_parent(@current)
      original = @current
      @current = context
      yield if block_given?
      process(exp)
      @current = original
    end


    # CasgnNode#defines_module?: Class.new / Struct.new / Data.define, with or without a block.
    def defines_module?(exp)
      value = exp.child(2)
      return false if value.nil? || value.atom?
      call = value.type == "block" ? value.child(0) : value
      return false unless call.type == "send"
      receiver = call.child(0)
      return false if receiver.atom? || receiver.type != "const"
      name = call.child(1).symbol_name
      simple = receiver.child(1).symbol_name
      (name == "new" && (simple == "Class" || simple == "Struct")) || (name == "define" && simple == "Data")
    end
  end

  # Module-like context names (ConstantDefiningNodeBase#full_name).
  class Names
    def initialize(source)
      @source = source
    end

    def full_name(context)
      return "" if context.kind == "root"
      return refined_name(context.exp) if context.kind == "refinement"
      parent = context.parent
      outer = parent.nil? ? "" : full_name(parent)
      exp = context.exp
      return outer if exp.nil?
      case exp.type
      when "def" then [outer, exp.child(0).symbol_name].reject { |part| part.empty? }.join("#")
      when "defs" then "#{outer.empty? ? "" : "#{outer}#"}#{receiver_name(exp.child(0))}.#{exp.child(1).symbol_name}"
      else joined(outer, local_name(exp))
      end
    end

    def joined(outer, name)
      return outer if name.empty?
      outer.empty? ? name : "#{outer}::#{name}"
    end

    # RefinementContext#full_name: the refined constant alone.
    def refined_name(exp)
      refined = exp.child(0).child(2)
      refined.nil? ? "" : refined.format_to_ruby(@source)
    end

    # SelfNode#name and ConstNode#name for singleton method receivers.
    def receiver_name(exp)
      exp.type == "self" ? "self" : exp.format_to_ruby(@source)
    end

    private

    def local_name(exp)
      return "" if exp.nil?
      case exp.type
      when "module", "class" then exp.child(0).format_to_ruby(@source)
      when "casgn" then exp.child(1).symbol_name
      else ""
      end
    end
  end

  # Reek::CodeComment#descriptive? with :reek: directives removed.
  def self.descriptive?(comment)
    sanitized = comment.gsub(/:reek:(\w+)(:?\s*)(\{.*?\})?/, "").gsub(/(#|\n|\s)+/, " ").strip
    sanitized.split(" ").length >= 2
  end

  # Reek::SmellDetectors::IrresponsibleModule over module, class and module-defining casgn contexts.
  def self.irresponsible_module(root, source)
    names = Names.new(source)
    records = []
    root.each do |context|
      next unless context.module_context?
      exp = context.exp
      next if suppressed?(context, "IrresponsibleModule")
      next if descriptive?(exp.leading_comment) || namespace_module?(exp)
      records << "#{exp.line}\t#{names.full_name(context)}\t\n"
    end
    records.join
  end

  # CodeContext#config_for: the nearest context whose directive options set enabled decides; a bare directive disables.
  def self.suppressed?(context, detector)
    directive_value(context, detector, "enabled") == "false"
  end

  # Runs one migrated detector over the context tree, returning finding records.
  def self.records(detector, root, source, settings)
    maximum = settings[0]
    return too_many_statements(root, source, maximum) if detector == "TooManyStatements"
    return nested_iterators(root, source, maximum, settings[2].to_s.split("\n")) if detector == "NestedIterators"
    return feature_envy(root, source) if detector == "FeatureEnvy"
    return utility_function(root, source, settings.length > 3 && settings[3] == true) if detector == "UtilityFunction"
    return nil_check(root, source) if detector == "NilCheck"
    return duplicate_method_call(root, source, maximum, settings[1].to_s.split("\n")) if detector == "DuplicateMethodCall"
    return control_parameter(root, source) if detector == "ControlParameter"
    return unused_parameters(root, source) if detector == "UnusedParameters"
    return boolean_parameter(root, source) if detector == "BooleanParameter"
    return long_parameter_list(root, source, maximum, settings[3].to_s.to_i) if detector == "LongParameterList"
    return long_yield_list(root, source, maximum) if detector == "LongYieldList"
    irresponsible_module(root, source)
  end

  # Reek::SmellDetectors::FeatureEnvy: the most referenced local receivers of instance methods using self.
  def self.feature_envy(root, source)
    names = Names.new(source)
    records = []
    root.each do |context|
      next unless context.kind == "method" && context.visibility != "module_function"
      next if suppressed?(context, "FeatureEnvy") || !depends_on_instance?(context.exp)
      envious_receivers(context.refs).each do |name|
        records << "#{context.refs[name].sort.join(", ")}\t#{names.full_name(context)}\t#{name}\n"
      end
    end
    records.join
  end

  # ObjectRefs#most_popular unless ObjectRefs#self_is_max?.
  def self.envious_receivers(refs)
    return [] if refs.empty?
    maximum = refs.values.map { |lines| lines.length }.max
    popular = refs.keys.select { |name| refs[name].length == maximum }
    popular.include?("self") ? [] : popular
  end

  # Reek::SmellDetectors::UtilityFunction over instance def contexts.
  def self.utility_function(root, source, public_only)
    names = Names.new(source)
    records = []
    root.each do |context|
      next unless context.kind == "method" && context.visibility != "module_function"
      exp = context.exp
      next if suppressed?(context, "UtilityFunction") || depends_on_instance?(exp)
      next if each_node(exp, ["send"], %w[class module]).empty?
      next if context.visibility != "public" && (directive_value(context, "UtilityFunction", "public_methods_only") == "true" || public_only)
      records << "#{exp.line}\t#{names.full_name(context)}\t\n"
    end
    records.join
  end

  # Reek::SmellDetectors::NilCheck: nil? queries, ==/=== against nil, and when nil, in method contexts.
  def self.nil_check(root, source)
    names = Names.new(source)
    records = []
    root.each do |context|
      next unless context.method_context?
      next if suppressed?(context, "NilCheck")
      exp = context.exp
      calls = each_node(exp, ["send"], %w[class module]).select { |call| nil_call?(call) }
      whens = each_node(exp, ["when"], %w[class module]).select { |found| found.children[0, found.children.length - 1].any? { |condition| condition.type == "nil" } }
      lines = (calls + whens).map { |node| node.line }
      records << "#{lines.sort.join(", ")}\t#{names.full_name(context)}\t\n" unless lines.empty?
    end
    records.join
  end

  # NilCallNodeDetector: a nil? query, or a comparison whose receiver or arguments include nil.
  def self.nil_call?(call)
    name = call.child(1).value
    return true if name == ":nil?"
    (name == ":==" || name == ":===") && call.children.any? { |participant| participant.type == "nil" }
  end

  # Reek::SmellDetectors::DuplicateMethodCall: structurally equal calls and blocks repeated in a method.
  def self.duplicate_method_call(root, source, maximum, allowed)
    names = Names.new(source)
    records = []
    root.each do |context|
      next unless context.method_context?
      next if suppressed?(context, "DuplicateMethodCall")
      limit = directive_integer(context, "DuplicateMethodCall", "max_calls")
      limit = maximum if limit.negative?
      patterns = directive_list(context, "DuplicateMethodCall", "allow_calls", allowed)
      collect_calls(context.exp).each do |group|
        call = group[0].format_to_ruby(source)
        next if group.length <= limit || patterns.any? { |pattern| call.match?(Regexp.new(pattern)) }
        records << "#{group.map { |node| node.line }.sort.join(", ")}\t#{names.full_name(context)}\t#{call}\t#{group.length}\n"
      end
    end
    records.join
  end

  # CallCollector#calls: occurrences grouped by node equality, sends before blocks, sorted by call text.
  def self.collect_calls(exp)
    groups = {}
    each_node(exp, ["send"], %w[mlhs class module]).each do |call|
      next if call.child(1).value == ":new" || (call.child(0).atom? && call.children.length == 2)
      record_call(groups, call)
    end
    each_node(exp, ["block"], %w[class module]).each { |block| record_call(groups, block) }
    groups.values
  end

  def self.record_call(groups, node)
    found = groups[node.key]
    found = groups[node.key] = [] if found.nil?
    found << node
  end

  # A list option from the nearest reek directive for the detector, or the configured list.
  def self.directive_list(context, detector, key, configured)
    current = context
    until current.nil?
      option = directive_options(current, detector).match(/\b#{key}:\s*\[([^\]]*)\]/)
      return option[1].split(",").map { |item| item.strip.delete("'\"") }.reject { |item| item.empty? } if option
      current = current.parent
    end
    configured
  end

  OPTIONAL_ARGUMENTS = %w[optarg kwoptarg].freeze

  # Reek::SmellDetectors::BooleanParameter: optional parameters defaulting to true or false.
  def self.boolean_parameter(root, source)
    names = Names.new(source)
    records = []
    method_contexts(root, "BooleanParameter").each do |context|
      parameters(context.exp).each do |parameter|
        next unless OPTIONAL_ARGUMENTS.include?(parameter.type) && %w[true false].include?(parameter.child(1).type)
        records << "#{context.exp.line}\t#{names.full_name(context)}\t#{parameter.child(0).symbol_name}\n"
      end
    end
    records.join
  end

  # Reek::SmellDetectors::LongParameterList: more arguments than max_params, with the initialize override.
  def self.long_parameter_list(root, source, maximum, initialize_maximum)
    names = Names.new(source)
    records = []
    method_contexts(root, "LongParameterList").each do |context|
      name = names.full_name(context)
      count = parameters(context.exp).reject { |parameter| parameter.type == "blockarg" }.length
      limit = directive_integer(context, "LongParameterList", "max_params")
      limit = name.include?("initialize") ? initialize_maximum : maximum if limit.negative?
      records << "#{context.exp.line}\t#{name}\t#{count}\n" if count > limit
    end
    records.join
  end

  # Reek::SmellDetectors::LongYieldList: each yield passing more than max_params arguments.
  def self.long_yield_list(root, source, maximum)
    names = Names.new(source)
    records = []
    method_contexts(root, "LongYieldList").each do |context|
      limit = directive_integer(context, "LongYieldList", "max_params")
      limit = maximum if limit.negative?
      each_node(context.exp, ["yield"], %w[class module]).each do |found|
        count = found.children.length
        records << "#{found.line}\t#{names.full_name(context)}\t#{count}\n" if count > limit
      end
    end
    records.join
  end

  # Method and singleton method contexts where the detector is not suppressed.
  def self.method_contexts(root, detector)
    found = []
    root.each { |context| found << context if context.method_context? && !suppressed?(context, detector) }
    found
  end

  SELF_TYPES = %w[self super zsuper ivar ivasgn send].freeze

  # MethodNodeBase#depends_on_instance?: self, super or instance variables, or a send without a receiver.
  def self.depends_on_instance?(exp)
    each_node(exp, SELF_TYPES, []).any? { |node| node.type != "send" || node.child(0).atom? }
  end

  CONDITIONAL_TYPES = %w[if case and or].freeze
  COMPARISON_CALLS = %w[:== :!= :=~].freeze

  # Reek::SmellDetectors::ControlParameter: parameters only used to choose a conditional branch.
  def self.control_parameter(root, source)
    names = Names.new(source)
    records = []
    root.each do |context|
      next unless context.method_context?
      next if suppressed?(context, "ControlParameter")
      exp = context.exp
      parameter_names(exp).each do |parameter|
        lines = control_matches(exp, parameter).map { |node| node.line }
        records << "#{lines.sort.join(", ")}\t#{names.full_name(context)}\t#{parameter[1, parameter.length - 1]}\n" unless lines.empty?
      end
    end
    records.join
  end

  ANONYMOUS_SPLATS = %w[forward_args forward_arg kwnilarg].freeze

  # Reek::SmellDetectors::UnusedParameters: named, unmarked parameters never read or assigned.
  def self.unused_parameters(root, source)
    names = Names.new(source)
    records = []
    root.each do |context|
      next unless context.method_context?
      next if suppressed?(context, "UnusedParameters")
      exp = context.exp
      body = exp.children.last
      next if !body.atom? && !each_node(body, ["zsuper"], []).empty?
      used = each_node(exp, %w[lvar lvasgn], %w[class module]).map { |node| node.child(0).value }
      parameters(exp).each do |parameter|
        next if parameter.type == "blockarg" || anonymous_splat?(parameter)
        name = parameter.child(0).value
        next if name[1, name.length - 1].start_with?("_") || used.include?(name)
        records << "#{exp.line}\t#{names.full_name(context)}\t#{name[1, name.length - 1]}\n"
      end
    end
    records.join
  end

  # ArgNodeBase#anonymous_splat?: unnamed rest arguments, argument forwarding and **nil.
  def self.anonymous_splat?(parameter)
    return true if ANONYMOUS_SPLATS.include?(parameter.type)
    name = parameter.child(0)
    name.nil? || !name.atom? || name.nil_atom?
  end

  # MethodNodeBase#parameters: argslist components, flattening destructured mlhs arguments.
  def self.parameters(exp)
    components(exp.child(exp.type == "defs" ? 2 : 1))
  end

  def self.components(node)
    return [node] unless node.type == "args" || node.type == "mlhs"
    node.nodes.flat_map { |child| components(child) }
  end

  # MethodNodeBase#parameter_names: each parameter's name atom, block arguments included.
  def self.parameter_names(exp)
    parameters(exp).map { |parameter| parameter.child(0) }.select { |name| !name.nil? && name.atom? && name.value.start_with?(":") }.map { |name| name.value }
  end

  # ControlParameterFinder#find_matches.
  def self.control_matches(node, parameter)
    return [] if legitimate_uses?(node, parameter)
    matches = conditional_nodes(node).flat_map { |nested| control_matches(nested, parameter) }
    condition = condition_of(node)
    condition.nil? ? matches : matches + each_node(condition, ["lvar"], []).select { |lvar| lvar.child(0).value == parameter }
  end

  # ControlParameterFinder#legitimate_uses?
  def self.legitimate_uses?(node, parameter)
    return true if call_in_condition?(node, parameter)
    return true if body_nodes(node, ["lvar"], CONDITIONAL_TYPES).any? { |lvar| lvar.child(0).value == parameter }
    conditional_nodes(node).any? { |nested| legitimate_uses?(nested, parameter) }
  end

  def self.conditional_nodes(node)
    body_nodes(node, CONDITIONAL_TYPES, [])
  end

  # CallInConditionFinder: a non-comparison call in the condition involving the parameter.
  def self.call_in_condition?(node, parameter)
    condition = condition_of(node)
    return false if condition.nil?
    each_node(condition, ["send"], []).any? do |call|
      !COMPARISON_CALLS.include?(call.child(1).value) && each_node(call, ["lvar"], []).any? { |lvar| lvar.child(0).value == parameter }
    end
  end

  # IfNode, CaseNode and LogicOperatorBase#condition; methods have none.
  def self.condition_of(node)
    return nil unless CONDITIONAL_TYPES.include?(node.type)
    condition = node.child(0)
    condition.nil? || condition.atom? ? nil : condition
  end

  # #body_nodes for method, if, case and logical-operator nodes.
  def self.body_nodes(node, types, ignoring)
    scope = ignoring | types
    case node.type
    when "def", "defs"
      body = node.children.last
      return [] if body.atom? || ignoring.include?(body.type)
      each_node(body, types, scope)
    when "if" then node.children[1, 2].reject { |child| child.atom? || ignoring.include?(child.type) }.flat_map { |child| each_node(child, types, scope) }
    when "case" then node.children[1, node.children.length - 1].reject { |child| child.atom? }.flat_map { |child| each_node(child, types, scope) }
    else
      branch = node.child(1)
      branch.atom? ? [] : each_node(branch, types, scope)
    end
  end

  # Reek::AST::Node#each_node (look_for): an ignored root is only left unsearched when it matches.
  def self.each_node(exp, types, ignoring, found = [])
    matched = types.include?(exp.type)
    found << exp if matched
    return found if matched && ignoring.include?(exp.type)
    exp.children.each { |child| look_for(child, types, ignoring, found) unless child.atom? }
    found
  end

  # Reek::AST::Node#look_for_recurse: matching nodes below, never entering ignored types.
  def self.look_for(exp, types, ignoring, found)
    found << exp if types.include?(exp.type)
    return if ignoring.include?(exp.type)
    exp.children.each { |child| look_for(child, types, ignoring, found) unless child.atom? }
  end

  # Reek::SmellDetectors::NestedIterators: one warning per nesting depth beyond the limit.
  def self.nested_iterators(root, source, maximum, ignored)
    names = Names.new(source)
    records = []
    root.each do |context|
      next unless context.method_context?
      next if suppressed?(context, "NestedIterators")
      limit = directive_integer(context, "NestedIterators", "max_allowed_nesting")
      limit = maximum if limit.negative?
      violations = scout(context.exp, 0, source, ignored).select { |pair| pair[1] > limit }
      violations.group_by { |pair| pair[1] }.each do |depth, group|
        records << "#{group.map { |pair| pair[0] }.join(", ")}\t#{names.full_name(context)}\t\t#{depth}\n"
      end
    end
    records.join
  end

  # NestedIterators#scout: [line, depth] for each innermost iterator under exp.
  def self.scout(exp, depth, source, ignored)
    return [] if exp.nil? || exp.atom?
    found = []
    blocks_under(exp).each do |iterator|
      nested_depth = ignored_iterator?(iterator, source, ignored) ? depth : depth + 1
      nested = scout(iterator.child(2), nested_depth, source, ignored) + scout(iterator.child(0), depth, source, ignored)
      found.concat(nested.empty? ? [[iterator.line, nested_depth]] : nested)
    end
    found
  end

  # Node#each_node([:block], [:block]): blocks below exp without entering them.
  def self.blocks_under(exp, found = [])
    if exp.type == "block"
      found << exp
    else
      exp.children.each { |child| blocks_under(child, found) unless child.atom? }
    end
    found
  end

  # Ignored iterators match a configured pattern or take no block arguments.
  def self.ignored_iterator?(iterator, source, ignored)
    call = iterator.child(0).format_to_ruby(source)
    ignored.any? { |pattern| call.match?(Regexp.new(pattern)) } || iterator.child(1).children.empty?
  end

  # Reek::SmellDetectors::TooManyStatements over method and singleton method contexts.
  def self.too_many_statements(root, source, maximum)
    names = Names.new(source)
    records = []
    root.each do |context|
      next unless context.method_context?
      next if suppressed?(context, "TooManyStatements")
      limit = directive_integer(context, "TooManyStatements", "max_statements")
      limit = maximum if limit.negative?
      count = context.statements
      records << "#{context.exp.line}\t#{names.full_name(context)}\t#{count}\t\n" if count > limit
    end
    records.join
  end

  # The value of an option from the nearest reek directive for the detector, or "".
  def self.directive_value(context, detector, key)
    current = context
    until current.nil?
      option = directive_options(current, detector).match(/\b#{key}:\s*(\w+)/)
      return option[1] if option
      current = current.parent
    end
    ""
  end

  # CodeComment#config for one context: the last directive naming the detector wins whole, and a bare one means enabled: false.
  def self.directive_options(context, detector)
    options = ""
    # Plain string split: pinned Spinel regexp splits are unreliable (ticket 147).
    context.full_comment.split(":reek:").drop(1).each do |segment|
      found = segment.match(/\A(\w+):?\s*(\{.*?\})?/)
      next unless found && found[1] == detector
      options = found[2].nil? ? "{ enabled: false }" : found[2]
    end
    options
  end

  # An integer option from the nearest reek directive for the detector, or -1.
  def self.directive_integer(context, detector, key)
    value = directive_value(context, detector, key)
    value.match?(/\A\d+\z/) ? value.to_i : -1
  end

  CONSTANT_TYPES = %w[casgn class module].freeze

  # ModuleContext#namespace_module?
  def self.namespace_module?(exp)
    return false if exp.type == "casgn"
    contents = exp.children.last
    return false if contents.nil? || contents.atom?
    children = contents.statements
    !children.empty? && children.all? { |child| CONSTANT_TYPES.include?(child.type) }
  end
end
