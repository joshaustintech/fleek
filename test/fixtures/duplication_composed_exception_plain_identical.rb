def handle_exception(value)
  begin
    operation(value)
  rescue StandardError => error
    fallback(error)
  ensure
    cleanup
  end
end

def handle_exception(value)
  begin
    operation(value)
  rescue StandardError => error
    fallback(error)
  ensure
    cleanup
  end
end
