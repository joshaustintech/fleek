# :reek:ClassVariable
class RubyFourSuppressed
  @@count = 0

  def collect(value)
    value
      && true
  end
end
