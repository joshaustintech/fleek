class Parcel
  def dispatch(flag)
    if flag then ship end
    if flag then store end
  end
end

class Crate
  def dispatch(flag)
    if flag then pack end
    if flag then label end
  end
end
