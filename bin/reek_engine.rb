# Ports Reek 6.6.0's AST helpers, comment association and context tree (ADR 0257).
# Input is the annotated parser-gem AST emitted by Fleek's native translation.
# The code mirrors Reek and parser gem algorithms nearly line for line so parity stays reviewable,
# so their structure (mutable AST fields, nil checks, scanner loops) is kept rather than reshaped.
# :reek:Attribute
# :reek:DuplicateMethodCall
# :reek:FeatureEnvy
# :reek:NestedIterators
# :reek:NilCheck
# :reek:RepeatedConditional
# :reek:TooManyInstanceVariables
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

  # Reek::Context::CodeContext and its subclasses, reduced to what ported detectors use.
  class Context
    attr_reader :exp, :children, :kind
    attr_accessor :parent

    def initialize(kind, exp)
      @kind = kind
      @exp = exp
      @children = []
      @parent = nil
    end

    def register_with_parent(parent)
      parent.children << self
      @parent = parent
    end

    def module_context?
      @kind == "module"
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
      @root = Context.new("root", tree.root)
      @current = @root
      build(tree.root) if tree.root
    end

    private

    def build(exp)
      case exp.type
      when "module", "class" then inside("module", exp)
      when "sclass" then inside("ghost", exp)
      when "casgn" then defines_module?(exp) ? inside("module", exp) : process(exp)
      when "def", "defs" then inside(exp.type == "def" ? "method" : "singleton_method", exp)
      else process(exp)
      end
    end

    def process(exp)
      exp.children.each { |child| build(child) unless child.atom? }
    end

    def inside(kind, exp)
      context = Context.new(kind, exp)
      context.register_with_parent(@current)
      original = @current
      @current = context
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
      parent = context.parent
      outer = parent.nil? ? "" : full_name(parent)
      name = local_name(context.exp)
      return outer if name.empty?
      outer.empty? ? name : "#{outer}::#{name}"
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

  # CodeContext#config_for: a reek directive naming the detector (bare or enabled: false) on a context or any parent disables it.
  def self.suppressed?(context, detector)
    current = context
    until current.nil?
      exp = current.exp
      comment = exp.nil? ? "" : exp.comments.map { |found| found.text }.join("\n")
      directive = comment.match(/:reek:#{detector}\b(:?\s*)(\{.*?\})?/)
      return true if directive && (directive[2].nil? || directive[2].include?("enabled: false"))
      current = current.parent
    end
    false
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
