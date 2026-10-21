class Parcel
  # :reek:LongParameterList
  def archive(id, status, retries, delay)
  end

  # :reek:LongParameterList { enabled: false }
  def dispatch(id, status, retries, delay)
  end

  def deliver(id, status, retries, delay)
  end

  # :reek:LongParameterList { enabled: false } :reek:LongParameterList { enabled: true }
  def repeated_enabled(id, status, retries, delay)
  end

  # :reek:LongParameterList { enabled: true } :reek:LongParameterList { enabled: false }
  def repeated_disabled(id, status, retries, delay)
  end
end
