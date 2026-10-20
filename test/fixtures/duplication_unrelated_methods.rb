def archive_report(record)
  archive(record)
end

def notify_report(record)
  queue(record)
end
