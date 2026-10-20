class Report
  def write_report(record, mode = 1, region = 2, retry_count = 3, locale = 4)
    validate(record)
    normalize(record)
    annotate(record)
    write(record)
  end

  def publish_report(record, mode = 1, region = 2, retry_count = 3, locale = 4)
    validate(record)
    normalize(record)
    publish(record)
  end
end
