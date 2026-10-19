# Validates local ticket documents and dependency graph.
# :reek:DataClump
# :reek:DuplicateMethodCall
# :reek:FeatureEnvy
# :reek:LongParameterList
# :reek:NilCheck
# :reek:TooManyStatements
# :reek:TooManyMethods
# :reek:UtilityFunction
class TicketDocuments
  STATUSES = %w[open claimed resolved].freeze
  TYPES = %w[research prototype grilling task].freeze
  CATEGORIES = %w[bug enhancement].freeze
  TRIAGE_STATES = %w[needs-triage needs-info ready-for-agent wontfix].freeze
  # Holds ticket count and validation diagnostics.
  Result = Struct.new(:count, :errors)

  def initialize(root)
    @root = root
    @tickets = {}
    @edges = {}
    @errors = []
  end

  def validate
    paths = Dir.glob("#{@root}/**/issues/*.md").sort
    paths.each { |path| read_ticket(path) }
    paths.each { |path| check_blockers(path) }
    check_cycles
    Result.new(paths.length, @errors.sort)
  end

  def read_ticket(path)
    content = File.read(path)
    filename_number = number_from_filename(path)
    heading_number = number_from_heading(content)
    error(path, "invalid ticket filename") if filename_number.nil?
    error(path, "invalid ticket heading") if heading_number.nil?
    if !filename_number.nil? && !heading_number.nil? && filename_number != heading_number
      error(path, "filename/heading number mismatch")
    end
    validate_fields(path, content)
    feature = File.dirname(File.dirname(path))
    @tickets[[feature, filename_number]] = path unless filename_number.nil?
    @edges[path] = blocker_references(path, content)
  end

  def number_from_filename(path)
    prefix = File.basename(path).split("-", 2)[0]
    return nil unless digits?(prefix) && prefix.length >= 2

    prefix.to_i
  end

  def number_from_heading(content)
    heading = content.lines[0].to_s.chomp
    return nil unless heading.start_with?("# ")

    number = heading[2..].split(":", 2)[0]
    digits?(number) ? number.to_i : nil
  end

  def validate_fields(path, content)
    title = content.lines[0].to_s.chomp.split(": ", 2)[1]
    error(path, "missing ticket title") if title.nil? || title.empty?
    description = field(content, "What to build") || field(content, "What to fix")
    error(path, "missing What to build or What to fix") if description.nil? || description.empty?
    validate_value(path, content, "Status", STATUSES)
    validate_value(path, content, "Type", TYPES)
    validate_value(path, content, "Category", CATEGORIES)
    validate_value(path, content, "Triage", TRIAGE_STATES)
    status = field(content, "Status")
    blockers = field(content, "Blocked by")
    error(path, "empty Blocked by") if !blockers.nil? && blockers.empty?
    if %w[open claimed].include?(status) && !content.include?("- [ ] ") && !content.include?("- [x] ")
      error(path, "missing acceptance criteria")
    end
  end

  def validate_value(path, content, name, allowed)
    value = field(content, name)
    if value.nil? || value.empty?
      error(path, "missing #{name}")
    elsif !allowed.include?(value)
      error(path, "invalid #{name.downcase} #{value}")
    end
  end

  def field(content, name)
    line = content.lines.find { |candidate| candidate.start_with?("**#{name}:**") }
    line && line["**#{name}:**".length..].strip
  end

  def blocker_references(path, content)
    value = field(content, "Blocked by")
    return [] if value.nil? || no_blockers?(value) || value.downcase.start_with?("every other unfinished ticket")

    value.split(/[;,]/).map { |entry| blocker_reference(path, entry.strip) }.compact
  end

  def no_blockers?(value)
    normalized = value.downcase
    normalized == "none" || normalized == "none (can start immediately)."
  end

  def blocker_reference(path, entry)
    feature = File.dirname(File.dirname(path))
    text = entry
    if text.start_with?("Default-check issue ")
      feature = "#{@root}/fleek-default-checks"
      text = text.sub("Default-check issue ", "")
    end
    text = text.sub("Ticket ", "").sub("issue ", "")
    token = text.split(/[^0-9]/, 2)[0]
    unless digits?(token)
      error(path, "invalid blocker reference #{entry}")
      return nil
    end
    [feature, token.to_i]
  end

  def check_blockers(path)
    targets = []
    (@edges[path] || []).each do |feature, number|
      target = @tickets[[feature, number]]
      if target.nil?
        error(path, "missing blocker #{number}")
      else
        targets << target
      end
    end
    @edges[path] = targets
  end

  def check_cycles
    visited = []
    active = []
    @edges.each_key do |path|
      next if visited.include?(path)

      visit(path, visited, active)
    end
  end

  def visit(path, visited, active)
    if active.include?(path)
      error(path, "dependency cycle")
      return
    end
    return if visited.include?(path)

    active << path
    (@edges[path] || []).each { |target| visit(target, visited, active) }
    active.delete(path)
    visited << path
  end

  def digits?(value)
    !value.nil? && !value.empty? && value.each_char.all? { |character| character >= "0" && character <= "9" }
  end

  def error(path, message)
    @errors << "#{path}: #{message}"
  end

end

# Owns command-line reporting for ticket validation.
# :reek:DuplicateMethodCall
class TicketDocumentsCommand
  def initialize(root)
    @root = root
  end

  def run
    result = TicketDocuments.new(@root).validate
    return report_errors(result.errors) unless result.errors.empty?

    puts "Ticket documents: #{result.count} valid"
    0
  end

  def report_errors(errors)
    errors.each { |message| warn message }
    1
  end
end

exit TicketDocumentsCommand.new(ARGV.fetch(0, ".scratch")).run
