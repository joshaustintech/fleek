class Feed
  def current(resource, limit = 10)
    @heading = "Current"
    @stream = Stream.open(resource[:token])
    @entries = @stream.current.list(limit: resource[:limit])
    render "current", status: :unprocessable_entity
  end

  def archived(entry, limit = 10)
    @heading = "Archived"
    @stream = Stream.open(entry[:token])
    @entries = @stream.archived.list(limit: entry[:limit])
    render "archive", status: :unprocessable_entity
  end
end
