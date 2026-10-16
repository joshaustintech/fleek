class Parcel
  def choose(flag, other)
    if other
      flag && perform
    end
    if flag
      ship
    end
  end
end
