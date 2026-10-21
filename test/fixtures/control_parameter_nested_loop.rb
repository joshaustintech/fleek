class Parcel
  def choose(items, flag)
    items.each do |item|
      if flag
        ship(item)
      else
        wait(item)
      end
    end
  end

  def choose_with_data(items, flag)
    items.each do |item|
      if flag
        ship(item)
      else
        wait(item)
      end
      log(flag)
    end
  end
end
