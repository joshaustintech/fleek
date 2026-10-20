def collect_items(items)
  if items
    items.map { |item| normalize(item) }
  else
    []
  end
end

def convert_items(items)
  if items
    items.map { |item| normalize(item); finish(item) }
  else
    {}
  end
end
