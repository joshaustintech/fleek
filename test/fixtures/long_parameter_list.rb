class Parcel
  def send(address, payload, retries, delay)
    [address, payload, retries, delay]
  end
end
