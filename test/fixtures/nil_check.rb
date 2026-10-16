class Parcel
  def retrieve(value)
    value.nil? ? :none : value
  end
end
