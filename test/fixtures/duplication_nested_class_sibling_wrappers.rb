class Dashboard
  class CurrentFeed
    class Reader
      def entries
        @heading = "Current"
        @stream = Stream.open(params[:token])
        @entries = @stream.current.list(limit: params[:limit])
        render "current", status: :unprocessable_entity
      end
    end
  end

  class ArchivedFeed
    class Reader
      def entries
        @heading = "Archived"
        @stream = Stream.open(params[:token])
        @entries = @stream.archived.list(limit: params[:limit])
        render "archive", status: :unprocessable_entity
      end
    end
  end
end
