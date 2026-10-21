class ToProcPrivateMethod
  private

  def hidden
    1
  end

  public

  def call_hidden
    method(:hidden).to_proc.call
  end
end
