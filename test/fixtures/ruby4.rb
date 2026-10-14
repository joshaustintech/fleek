# Comment remains available to the parser while the file stays inert.
class RubyFourExample
  def collect(value)
    value
      && true
  end
end
