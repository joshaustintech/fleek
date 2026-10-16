class Parcel
  def retrieve(address, urgent)
    if urgent
      address
    else
      :queued
    end
  end
end
