class CurrentFeed
  before_action :authorize do
    authorize_current
  end


  def current
    @heading = "Current"
    @stream = Stream.open(params[:token])
    @entries = @stream.current.list(limit: params[:limit])
    render "current", status: :unprocessable_entity
  end
end

class ArchivedFeed
  before_action :authorize do
    authorize_archived
  end


  def archived
    @heading = "Current"
    @stream = Stream.open(params[:token])
    @entries = @stream.current.list(limit: params[:limit])
    render "current", status: :unprocessable_entity
  end
end
