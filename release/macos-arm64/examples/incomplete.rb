class CurrentFeed
  before_action :authorize

  def current
    @heading = "Current"
    @stream = Stream.open(params[:token])
    @entries = @stream.current.list(limit: params[:limit])
    render "current", status: :unprocessable_entity
  end
end

class ArchivedFeed
  before_action :authorize, only: :archived

  def archived
    @heading = "Archived"
    @stream = Stream.open(params[:token])
    @entries = @stream.archived.list(limit: params[:limit])
    render "archive", status: :unprocessable_entity
  end
end
