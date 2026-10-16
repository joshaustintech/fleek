class Parcel
  def send(address, retry_enabled: false)
    retry_enabled ? address : address
  end

  def retrieve(include_details = true)
    include_details ? :full : :summary
  end

  def self.queue(async: true)
    async ? :queued : :sent
  end
end
