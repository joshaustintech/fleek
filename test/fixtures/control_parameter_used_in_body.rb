class Parcel
  def retrieve(address, urgent)
    puts urgent
    urgent ? address : :queued
  end
end
