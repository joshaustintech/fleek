class MethodObjectPrivateMethod
  private

  def hidden
    1
  end

  public

  def method_object
    method(:hidden)
  end
end
