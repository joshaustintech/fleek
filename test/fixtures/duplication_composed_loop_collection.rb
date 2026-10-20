def map_values(values)
  values.each do |value|
    Array(value).map { |item| { result: normalize(item) } }
  end
end

def convert_entries(entries)
  entries.each do |entry|
    Array(entry).map { |record| { result: convert(record) } }
  end
end
