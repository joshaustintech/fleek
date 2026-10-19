def assign(input)
  left, right = input
  consume(left, right)
end

def assign(input)
  left, middle, right = input
  consume(left, middle, right)
end
