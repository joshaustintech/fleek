class Marker
  def marker
    1
  end
end

class Feed
  def current
    @heading = "Current"
    @stream = Stream.open(params[:token])
    @entries = @stream.current.list(limit: params[:limit])
    render "current", status: :unprocessable_entity
  end
end

class ArchivedFeed
  def archived
    @heading = "Archived"
    @stream = Stream.open(params[:token])
    @entries = @stream.archived.list(limit: params[:limit])
    render "archive", status: :unprocessable_entity
  end

  def marker
    1
  end
end
