class Parcel
  def initialize(address, payload, retries, delay, queue)
    @address = address
    @payload = payload
    @retries = retries
    @delay = delay
    @queue = queue
  end
end
