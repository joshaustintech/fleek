class Parcel
  def price(items)
    self.refresh
    items.each do |item|
      item.price
      item.tax
      item.total
    end
  end

  def update(items)
    self.reset
    items.each do |item|
      item.price
      self.record(item)
      self.record(item)
    end
  end
end
