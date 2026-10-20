def prepare_report(mode = 1, region = 2, retry_count = 3, locale = 4)
  validate(record)
  normalize(record)
  annotate(record)
  write(record)
  collect(record)
  format(record)
  publish(record)
end

def publish_report(mode = 1, region = 2, retry_count = 3, locale = 4)
  validate(record)
  normalize(record)
  collect(record)
  format(record)
  publish(record)
end
