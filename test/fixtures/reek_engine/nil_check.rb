# Nil check fixtures covering queries, comparisons, case branches and scopes.
class Checks
  def query(value)
    value.nil?
  end

  def compare(value)
    return if value == nil
    nil === value
  end

  def branch(value)
    case value
    when nil then 1
    when 0, nil then 2
    end
  end

  def safe(value)
    value&.nil?
  end

  def different(value)
    value != nil
  end

  def nested(value)
    Class.new { def inner(other) = other.nil? }
    value.to_s
  end

  def self.singleton(value)
    value.nil? || value.nil?
  end

  # :reek:NilCheck
  def silenced(value)
    value.nil?
  end

  def argument(value)
    value.equal?(nil)
  end
end

nil.nil?
