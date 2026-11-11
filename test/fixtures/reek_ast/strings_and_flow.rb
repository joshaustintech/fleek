class Report
  QUERY = "SELECT id FROM rows
           WHERE ready = :ready"

  def render(rows, name)
    header = <<~TEXT
      Report for #{name}
      Total rows: #{rows.size}
    TEXT
    plain = <<~TEXT
      static line
    TEXT
    /ready/ =~ name
    name =~ /#{rows.first}/
    rows.map { _1.to_s }
    @cache[name] ||= rows.first
    self.total += rows.size
    first, *rest = rows
    begin
      emit(header, plain, first, rest)
    rescue ArgumentError, TypeError => error
      retry if error
    rescue
      nil
    else
      done
    ensure
      close
    end
    value = compute rescue nil
    loop do
      break unless ready?
      next if rows.empty?
    end
  end
end
