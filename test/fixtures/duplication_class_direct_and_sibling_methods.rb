class ActivityFeed
  def refresh_all
    @heading = "Current"
  end

  def refresh
    @heading = "Current"
    @stream = Stream.open(params[:token])
    @entries = @stream.current.list(limit: params[:limit])
    render "current", status: :unprocessable_entity
  end

  class Current
    def refresh
      @heading = "Current"
      @stream = Stream.open(params[:token])
      @entries = @stream.current.list(limit: params[:limit])
      render "current", status: :unprocessable_entity
    end
  end

  class Archived
    def refresh
      @heading = "Current"
      @stream = Stream.open(params[:token])
      @entries = @stream.current.list(limit: params[:limit])
      render "current", status: :unprocessable_entity
    end
  end
end

