class Parcel
  def at_default_limit
    [1].each { [2].each { yield(:a, :b, :c) } }
  end

  def over_default_limit
    [1].each { [2].each { yield(:a, :b, :c, :d) } }
  end

  def over_configured_limit
    [1].each { [2].each { yield(:a, :b, :c, :d, :e) } }
  end
end
