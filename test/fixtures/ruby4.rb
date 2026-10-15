# Comment remains available to the parser while the file stays inert.
class RubyFourExample
  @@count = 0

  def collect(value)
    value
      && true
  end
end
