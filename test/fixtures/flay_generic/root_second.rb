class ReceiptExporter
  def export(items, currency: "eur")
    items.select { |item| item.amount.positive? }.map { |item| [item.id, item.amount.round(2), currency] }
  end
end
