class Parcel
  def shadowed(value)
    items.each do |value|
      ship(value)
    end
  end

  def captured(value)
    items.each do |item|
      ship(value)
    end
  end

  def unused(value)
    items.each do |item|
      ship(item)
    end
  end
end
