def parse_response(value)
  begin
    /pre#{value}post/ =~ value
  rescue StandardError => error
    fallback(error)
  ensure
    cleanup
  end
end
# FLEEK_SOURCE_FILE_BOUNDARY
def parse_response(value)
  begin
    /pre#{value}post/ =~ value
  rescue StandardError => error
    fallback(error)
  ensure
    cleanup
  end
end
