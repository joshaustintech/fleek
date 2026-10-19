def transform(items)
  items.map { |value = alternate_fallback| convert(items) }
end

def transform(items)
  items.map { |value = fallback_value| convert(items) }
end
