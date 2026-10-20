def classify_entries(kind, entries)
  case kind
  when :single, :multiple
    entries.map { |entry| normalize(entry) }
  when :empty
    []
  else
    entries
  end
end

def select_records(mode, records)
  case mode
  when :first, :all
    records.map { |record| convert(record) }
  when :none
    []
  else
    records
  end
end
