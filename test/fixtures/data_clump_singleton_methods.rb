class Shipment
  class << self
    def prepare(origin, destination, weight); end
    def quote(origin, destination, weight); end
    def dispatch(origin, destination, weight); end
    def audit(origin, destination, weight, ticket); end
    def stage(origin, destination, code, status); end
    def reserve(origin, destination, weight, ticket); end
  end

  def self.external(origin, destination, weight); end

  def instance_prepare(origin, destination, weight); end
  def instance_quote(origin, destination, weight); end
  def instance_dispatch(origin, destination, weight); end
end
