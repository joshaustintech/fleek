class Parcel
  def at_default_limit(first, second, third)
    [1].each { |one, two, three, four| one }
  end

  def over_default_limit(first, second, third, fourth)
    [1].each { |one, two, three, four, five| one }
  end

  def over_configured_limit(first, second, third, fourth, fifth)
    [1].each { |one, two, three, four, five, six| one }
  end
end
