def transform(required, optional = 1, *rest, mode:, strict: false, **options, &callback)
  items.map do |value, entry = 2|
    callback.call(value, entry, optional, mode, strict, rest, options)
  end
end

def transform(required, optional = 1, *rest, mode:, strict: false, **options, &callback)
  items.map do |value, entry = 2|
    callback.call(value, entry, optional, mode, strict, rest, options)
  end
end
