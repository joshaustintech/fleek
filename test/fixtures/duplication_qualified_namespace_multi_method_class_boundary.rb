module Current::Versioned
  class Feed
    def current
      @heading = "Current"
      @stream = Stream.open(params[:token])
      @entries = @stream.current.list(limit: params[:limit])
      render "current", status: :unprocessable_entity
    end

    def refresh
      @heading = "Refresh"
      @stream = Stream.open(params[:token])
      @entries = @stream.refresh.list(limit: params[:limit])
      render "refresh", status: :unprocessable_entity
    end
  end
end

module Previous::Versioned
  class Feed
    def previous
      @heading = "Previous"
      @stream = Stream.open(params[:token])
      @entries = @stream.previous.list(limit: params[:limit])
      render "previous", status: :unprocessable_entity
    end

    def reload
      @heading = "Reload"
      @stream = Stream.open(params[:token])
      @entries = @stream.reload.list(limit: params[:limit])
      render "reload", status: :unprocessable_entity
    end
  end
end
