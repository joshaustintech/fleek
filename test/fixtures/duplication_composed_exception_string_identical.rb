def format_response(value)
  begin
    "response: #{value}"
  rescue StandardError => error
    "failed: #{error}"
  ensure
    cleanup
  end
end

def format_response(value)
  begin
    "response: #{value}"
  rescue StandardError => error
    "failed: #{error}"
  ensure
    cleanup
  end
end
