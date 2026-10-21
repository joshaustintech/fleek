class Parcel
  def calculate(order, include_tax)
    if include_tax
      order.total(:net)
    else
      order.total(:net)
    end
    order.total(:gross)
  end
end
