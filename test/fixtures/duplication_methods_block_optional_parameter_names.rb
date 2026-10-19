def transform(items)
  items.map { |value = 1| convert(items) }
end

def transform(items)
  items.map { |record = 1| convert(items) }
end
