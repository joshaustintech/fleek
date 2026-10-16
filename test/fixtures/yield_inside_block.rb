class Parcel
  def deliver
    [1].each { yield(:a, :b, :c, :d) }
  end
end
