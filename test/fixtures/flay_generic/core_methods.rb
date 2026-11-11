def summarize(items, limit = 10)
  total = 0
  index = 0
  while index < limit
    total = total + items[index] if items[index]
    index = index + 1
  end
  return total unless total.zero?
  @last = total
end

def accumulate(values, ceiling = 20)
  sum = 0
  cursor = 0
  while cursor < ceiling
    sum = sum + values[cursor] if values[cursor]
    cursor = cursor + 1
  end
  return sum unless sum.zero?
  @last = sum
end
