class Feed
  def current(resource)
    @heading = "Current"
    @stream = Stream.open(resource[:token])
    @entries = @stream.current.list(limit: resource[:limit])
    render "current", status: :unprocessable_entity
    unless resource.admin?
      @heading = "Member"
    else
      @heading = "Admin"
    end
  end

  def archived(entry)
    @heading = "Archived"
    @stream = Stream.open(entry[:token])
    @entries = @stream.archived.list(limit: entry[:limit])
    render "archive", status: :unprocessable_entity
    unless entry.admin?
      @heading = "Member"
    else
      @heading = "Admin"
    end
  end
end
