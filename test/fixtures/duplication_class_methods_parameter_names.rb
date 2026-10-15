class Feed
  def current(resource)
    @heading = "Current"
    @stream = Stream.open(params[:token])
    @entries = @stream.current.list(limit: params[:limit])
    render "current", status: :unprocessable_entity
  end

  def current(entry)
    @heading = "Current"
    @stream = Stream.open(params[:token])
    @entries = @stream.current.list(limit: params[:limit])
    render "current", status: :unprocessable_entity
  end
end
