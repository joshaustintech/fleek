class InvoiceExporter
  def export(rows, currency: "usd")
    rows.select { |row| row.total.positive? }.map { |row| [row.id, row.total.round(2), currency] }
  end
end
class ReceiptExporter
  def export(items, currency: "eur")
    items.select { |item| item.amount.positive? }.map { |item| [item.id, item.amount.round(2), currency] }
  end
end
