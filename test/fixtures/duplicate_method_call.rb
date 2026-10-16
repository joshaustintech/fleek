class Parcel
  def dispatch
    send(:load)
    send(:load)
  end
end
