class Parcel
  def price(item)
    item.price
    item.tax
    item.total
    item.shipping
    item.valid?
    self.shipping
  end
end
