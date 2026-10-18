class ActivityFeed
  class Current
    def entries
      @heading = "Current"
      @stream = Stream.open(params[:token])
      @entries = @stream.current.list(limit: params[:limit])
      render "current", status: :unprocessable_entity
    end
  end

  class Archived
    def entries
      @heading = "Archived"
      @stream = Stream.open(params[:token])
      @entries = @stream.archived.list(limit: params[:limit])
      render "archive", status: :unprocessable_entity
    end
  end

  class Legacy
    def entries(*values)
      values
    end
    private
  end
end
