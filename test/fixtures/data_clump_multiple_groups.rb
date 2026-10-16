class Shipment
  def prepare(origin, destination, weight); end
  def quote(origin, destination, weight); end
  def dispatch(origin, destination, weight); end
  def bill(account, amount, currency); end
  def invoice(account, amount, currency); end
  def refund(account, amount, currency); end
end
