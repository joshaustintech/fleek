class Parcel
  def deliver
    yield :address, :payload, :retries, :delay
  end
end
