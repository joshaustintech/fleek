# Unused parameter fixtures covering kinds, markers, splats, super and nesting.
class Params
  def plain(used, unused)
    used
  end

  def marked(_ignored, value)
    value
  end

  def splats(*, **, &block)
    1
  end

  def named_splats(*rest, **options)
    1
  end

  def keywords(required:, optional: 1)
    required
  end

  def assigned(value)
    value = 1
  end

  def inherited(value)
    super
  end

  def explicit_super(value)
    super()
  end

  def nested(outer)
    Class.new { def inner(other) = outer }
  end

  def destructured((first, second))
    first
  end

  def forwarded(...)
    1
  end

  def no_keywords(value, **nil)
    1
  end

  def self.singleton(value)
    1
  end

  # :reek:UnusedParameters
  def silenced(value)
    1
  end

  def blocks(items, factor)
    items.map { |item| item * factor }
  end
end
