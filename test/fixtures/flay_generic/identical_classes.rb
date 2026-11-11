class FirstReport
  HEADERS = ["name", "total"].freeze

  def rows(records)
    records.map { |record| [record.name, record.total] }
  end
end

class SecondReport
  HEADERS = ["name", "total"].freeze

  def rows(records)
    records.map { |record| [record.name, record.total] }
  end
end
