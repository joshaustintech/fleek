class Parcel
  def dispatch(target)
    respond_to?(target)
  end
end
