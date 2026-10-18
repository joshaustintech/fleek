def page(resource, limit = 10)
  @heading = "Page"
  @stream = Stream.open(resource[:token])
  @entries = @stream.current.list(limit: resource[:limit])
  render "page", status: :unprocessable_entity
end

def page(resource, limit = 20)
  @heading = "Page"
  @stream = Stream.open(resource[:token])
  @entries = @stream.current.list(limit: resource[:limit])
  render "page", status: :unprocessable_entity
end
