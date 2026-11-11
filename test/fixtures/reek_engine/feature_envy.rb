# Feature envy fixtures covering receivers, ties, visibility and singleton contexts.
class Envious
  def totals(order)
    order.subtotal + order.tax + order.shipping + @rate
  end

  def tied(left, right)
    left.size + right.size + helper
  end

  def assigned
    item = Item.new
    item.name
    item.price
    total = 1
    total += item.weight
    @seen = true
  end

  def counting
    count = 0
    count += 1
    count += 2
    @total = count
  end

  def created(builder)
    builder.new
    builder.new
    builder.call
    helper
  end

  def nested(rows)
    rows.each { |row| row.save }
    rows.first
    rows.last
    super
  end

  def overridden(other)
    other.a + other.b + super(1)
  end

  # Delegates without using its own state.
  def plain(value)
    value.to_s + value.inspect
  end

  def self.single(list)
    list.first + list.last + list.size + new.size
  end

  class << self
    def ghost(list)
      list.first + list.last + helper
    end
  end

  private

  def hidden(other)
    other.a + other.b + other.c + @d
  end

  module_function

  def shared(other)
    other.a + other.b + other.c + @d
  end
end

module Helpers
  # Uses its receiver only once.
  def self.helper; end

  def mixed(target)
    target.a
    target.b
    self.c
    @d
  end

  # :reek:FeatureEnvy
  def silenced(target)
    target.a + target.b + @c
  end

  private def inline(target)
    target.a + target.b + @c
  end

  # :reek:FeatureEnvy
  private def quiet(target)
    target.a + target.b + @c
  end
end

module Refined
  refine String do
    def shout(other)
      other.upcase + other.strip + to_s
    end
  end
end
