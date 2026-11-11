class InvoiceExporter
  def export(rows, currency: "usd")
    rows.select { |row| row.total.positive? }.map { |row| [row.id, row.total.round(2), currency] }
  end
end
