class Parcel
  def choose(items, flag)
    items.each do |item|
      if flag
        ship(item)
      end
    end
    items.each do |item|
      if flag
        wait(item)
      end
    end
  end
end
