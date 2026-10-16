class Parcel
  def dispatch(values)
    values.each do |value|
      value.each do |entry|
        ship(entry)
      end
    end
  end
end
