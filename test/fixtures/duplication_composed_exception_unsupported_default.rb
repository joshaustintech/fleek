class ComposedExceptionCandidates
  def parse_first(value)
    begin
      /pre#{value}post/ =~ value
    rescue StandardError => error
      fallback(error)
    ensure
      cleanup
    end
  end

  def parse_second(value)
    begin
      /pre#{value}post/ =~ value
    rescue StandardError => error
      fallback(error)
    ensure
      cleanup
    end
  end

  def parse_unsupported(value = [])
    process(value)
  end
end
