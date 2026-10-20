def parse_response(value)
  begin
    /pre#{value}post/ =~ value
  rescue StandardError => error
    fallback(error)
  ensure
    cleanup
  end
end

def decode_response(source)
  begin
    /pre#{source}post/ =~ source
  rescue StandardError => exception
    fallback(exception)
  ensure
    cleanup
  end
end
