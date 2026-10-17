module Current::Versioned
  class Feed
    def current
      @heading = "Current"
      @stream = Stream.open(params[:token])
      @entries = @stream.current.list(limit: params[:limit])
      render "current", status: :unprocessable_entity
    end
  end

  class Archive
    def archived
      @heading = "Archived"
      @stream = Stream.open(params[:token])
      @entries = @stream.archived.list(limit: params[:limit])
      render "archive", status: :unprocessable_entity
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
  end

  class Archive
    def stored
      @heading = "Stored"
      @stream = Stream.open(params[:token])
      @entries = @stream.stored.list(limit: params[:limit])
      render "stored", status: :unprocessable_entity
    end
  end
end
