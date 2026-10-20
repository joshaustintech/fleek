def transform(required, optional = 1, *rest, mode:, strict: false, **options, &callback)
  items.map { |value| value }
end

def transform(required, mode:, &callback)
  items.each { |value| value + 1 }
end
