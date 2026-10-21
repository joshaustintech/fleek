class PublicSendPrivateMethod
  private

  def hidden
    1
  end

  public

  def call_hidden
    public_send(:hidden)
  end
end
