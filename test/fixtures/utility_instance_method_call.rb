class Parcel
  def calculate(address)
    normalize(address)
  end

  def normalize(address)
    address.strip
  end
end
