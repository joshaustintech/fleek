module CurrentFeed
  def current
    @heading = "Current"
    @stream = Stream.open(params[:token])
    render "current", status: :unprocessable_entity
  end

  def archived
    @heading = "Archived"
    @stream = Stream.open(params[:token])
    render "archive", status: :unprocessable_entity
  end
end

module FeedArchive
  def current
    @heading = "Current"
    @stream = Stream.open(params[:token])
    render "current", status: :unprocessable_entity
  end

  def archived
    @heading = "Archived"
    @stream = Stream.open(params[:token])
    render "archive", status: :unprocessable_entity
  end
end
