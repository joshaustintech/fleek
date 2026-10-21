class Parcel
  def price(items)
    self.refresh
    items.each do |item|
      item.price
    end
    items.each do |item|
      item.tax
    end
  end
end
