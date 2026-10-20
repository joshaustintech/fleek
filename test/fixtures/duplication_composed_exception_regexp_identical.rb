def parse_response(value)
  begin
    /pre#{value}post/ =~ value
  rescue StandardError => error
    fallback(error)
  ensure
    cleanup
  end
end

def parse_response(value)
  begin
    /pre#{value}post/ =~ value
  rescue StandardError => error
    fallback(error)
  ensure
    cleanup
  end
end
