class CurrentFeed
  def entries
    @heading = "Current"
    @stream = Stream.open(params[:token])
    @entries = @stream.current.list(limit: params[:limit])
    render "current", status: :unprocessable_entity
  end
end

class ArchivedFeed
  def entries
    @heading = "Archived"
    @stream = Stream.open(params[:token])
    @entries = @stream.archived.list(limit: params[:limit])
    render "archive", status: :unprocessable_entity
  end
end

class ConditionalFeed
  def current(resource)
    @heading = "Current"
    @stream = Stream.open(resource[:token])
    @entries = @stream.current.list(limit: resource[:limit])
    render "current", status: :unprocessable_entity
    if resource.admin?
      @heading = "Admin"
    else
      @heading = "Member"
    end
  end

  def archived(entry)
    @heading = "Archived"
    @stream = Stream.open(entry[:token])
    @entries = @stream.archived.list(limit: entry[:limit])
    render "archive", status: :unprocessable_entity
    if entry.admin?
      @heading = "Admin"
    else
      @heading = "Member"
    end
  end
end
