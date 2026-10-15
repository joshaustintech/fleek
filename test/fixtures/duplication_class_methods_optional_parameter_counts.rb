class Feed
  def current(resource, limit = 10, offset = 0)
    resource.fetch(:limit, limit)
  end

  def current(resource, limit = 10)
    resource.fetch(:limit, limit)
  end
end
