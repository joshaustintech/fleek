class FirstBoundary
  def value(input)
    [input, __FILE__, input.to_s, (1..2)]
  end
end

class SecondBoundary
  def value(input)
    [input, __FILE__, input.to_s, (1..2)]
  end
end
