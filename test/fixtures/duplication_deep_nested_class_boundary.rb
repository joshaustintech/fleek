class Current
  class Feed
    class Events
      def current
        @heading = "Current"
        @stream = Stream.open(params[:token])
        @entries = @stream.current.list(limit: params[:limit])
        render "current", status: :unprocessable_entity
      end
    end
  end
end

class Archived
  class Feed
    class Events
      def archived
        @heading = "Archived"
        @stream = Stream.open(params[:token])
        @entries = @stream.archived.list(limit: params[:limit])
        render "archive", status: :unprocessable_entity
      end
    end
  end
end
