module Feed
  def page(resource)
    @heading = "Page"
    @stream = Stream.open(resource[:token])
    @entries = @stream.current.list(limit: resource[:limit])
    render "page", status: :unprocessable_entity
  end

  def home(resource)
    @heading = "Home"
    @stream = Stream.open(resource[:token])
    @entries = @stream.current.list(limit: resource[:limit])
    render "home", status: :unprocessable_entity
  end
end
