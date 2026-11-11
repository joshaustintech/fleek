# Repeated conditional and data clump fixtures.
class Conditions
  def a
    return 1 if @ready
    block_given? ? 1 : 2
    case @kind
    when :x then 1
    end
  end

  def b
    puts "x" unless @ready
    yield if block_given?
    case @kind
    when :y then 2
    end
  end

  def c
    @ready ? 1 : 2
    if block_given?
      3
    elsif @ready
      4
    end
    case
    when @kind then 1
    end
    case @kind
    when :z then 3
    end
  end

  class << self
    def d(left, right, extra)
      left + right + extra
    end
  end

  def e(left, right, *rest, &block)
    left + right
  end

  def f(right, left)
    left + right
  end

  def g(left, right, extra)
    left + right + extra
  end

  def h(alpha, beta)
    alpha + beta
  end
end

module Clumpy
  def a(x, y, z); end
  def b(x, y, z); end
  def c(z, y, x); end
  def d(x, y); end
end

# :reek:DataClump { max_copies: 1, min_clump_size: 3 }
# :reek:RepeatedConditional { max_ifs: 1 }
class Configured
  def a(p, q, r); @on ? p : q; end
  def b(p, q, r); @on ? q : r; end
  def c(p, q); end
end
