class Feed
  before_action :load_stream

  def current
    @heading = "Current"
    @stream = Stream.open(params[:token])
    @entries = @stream.current.list(limit: params[:limit])
    render "current", status: :unprocessable_entity
  end

  def archived
    @heading = "Archived"
    @stream = Stream.open(params[:token])
    @entries = @stream.archived.list(limit: params[:limit])
    render "archive", status: :unprocessable_entity
  end

  def filtered(page)
    return unless page
    Stream.where(page: page)
  end
end
