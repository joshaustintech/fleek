class PrivateThing
  private

  def hidden
    1
  end

  public

  def visible
    send(:hidden)
  end
end
