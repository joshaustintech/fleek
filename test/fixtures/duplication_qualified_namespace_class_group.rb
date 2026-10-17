module Current::Versioned
  class Feed
    def current
      @heading = "Current"
      @stream = Stream.open(params[:token])
      @entries = @stream.current.list(limit: params[:limit])
      render "current", status: :unprocessable_entity
    end
  end
end

module Archived::Versioned
  class Feed
    def archived
      @heading = "Archived"
      @stream = Stream.open(params[:token])
      @entries = @stream.archived.list(limit: params[:limit])
      render "archive", status: :unprocessable_entity
    end
  end
end
