# Parameter list fixtures for boolean defaults, long parameter lists and long yields.
class Lists
  def flags(verbose = true, quiet = false, level = 1, strict: true, loose: nil)
    yield verbose, quiet, level, strict, loose
  end

  def initialize(a, b, c, d, e)
    @a = [a, b, c, d, e]
  end

  def initialize_copy(a, b, c, d, e, f)
    yield a, b, c
  end

  def long(a, b, c, d, &block)
    yield(a, b, *c, d)
    yield a
  end

  def splats(a, b, *, **)
    a + b
  end

  def self.singleton(a, b, c, d, flag = false)
    yield a, b, c, d
  end

  # :reek:LongParameterList { max_params: 5 }
  def configured(a, b, c, d, e)
    Class.new { def inner(a, b, c, d) = yield(a, b, c, d) }
  end

  # :reek:LongParameterList { enabled: false } :reek:LongParameterList { enabled: true }
  def repeated_enabled(a, b, c, d)
    a
  end

  # :reek:LongParameterList { enabled: true } :reek:LongParameterList
  def repeated_disabled(a, b, c, d)
    a
  end

  # :reek:LongYieldList { max_params: 4 }
  def allowed(a)
    yield a, a, a, a
  end
end
