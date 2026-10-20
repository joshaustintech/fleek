class MessageParserA
  def parse_message(value)
    begin
      "response: #{value}"
    rescue StandardError => error
      "failed: #{error}"
    ensure
      cleanup
    end
  end

  def parser_status
    active
  end
end
