def format_response(value)
  begin
    "response: #{value}"
  rescue StandardError => error
    "failed: #{error}"
  ensure
    cleanup
  end
end

def render_response(source)
  begin
    "response: #{source}"
  rescue StandardError => exception
    "failed: #{exception}"
  ensure
    cleanup
  end
end
