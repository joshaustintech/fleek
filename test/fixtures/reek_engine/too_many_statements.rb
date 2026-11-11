# Exercises Reek statement counting.
class Counter
  def initialize
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
    f = 6
  end

  def branches(value)
    if value > 1
      first
      second
    elsif value.zero?
      third
    else
      fourth
      fifth
    end
    sixth
  end

  def cases(value)
    case value
    when 1 then one; two
    when 2 then three
    else four; five
    end
    six
  end

  def guarded
    begin
      load_data
      parse_data
    rescue ArgumentError => error
      report(error)
      retry_later
    ensure
      cleanup
    end
    finish
  end

  def loops(items)
    items.each { |item| emit(item); log(item) }
    while ready?
      step
      pause
    end
    for item in items
      record(item)
    end
    done
  end

  def sparse(value)
    case value
    when 1 then one
    end
    while ready?
    end
    two
    three
    four
    five
  end

  def self.builder
    one
    two
    three
    four
    five
    six
  end

  class << self
    def ghost
      one
      two
      three
      four
      five
      six
    end
  end

  # :reek:TooManyStatements { max_statements: 10 }
  def relaxed
    one
    two
    three
    four
    five
    six
  end

  # :reek:TooManyStatements
  def silenced
    one
    two
    three
    four
    five
    six
  end
end
