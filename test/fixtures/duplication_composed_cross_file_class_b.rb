class MessageParserA
  def parse_message(value)
    begin
      "message: #{value}"
    rescue StandardError => error
      "error: #{error}"
    ensure
      cleanup
    end
  end

  def parser_status
    active
  end
end
