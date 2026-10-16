class Shipment
  def prepare(origin, destination, weight); end
  def quote(origin, destination, weight); end
  def dispatch(origin, destination, weight); end
  def transfer(extra:); end
end
