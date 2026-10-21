class CurrentFeed
  private :current

  def current
    @heading = "Current"
    @stream = Stream.open(params[:token])
    @entries = @stream.current.list(limit: params[:limit])
    render "current", status: :unprocessable_entity
  end
end

class ArchivedFeed
  private :archived

  def archived
    @heading = "Archived"
    @stream = Stream.open(params[:token])
    @entries = @stream.archived.list(limit: params[:limit])
    render "archive", status: :unprocessable_entity
  end
end
