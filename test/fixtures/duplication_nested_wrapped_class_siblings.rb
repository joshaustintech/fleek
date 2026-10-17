class Current
  class Events
    class V2
      def current
        @heading = "Current"
        @stream = Stream.open(params[:token])
        @entries = @stream.current.list(limit: params[:limit])
        render "current", status: :unprocessable_entity
      end

      def refresh
        @stream = Stream.open(params[:token])
        render "refresh", status: :ok
      end
    end
  end

  class Entries
    class V2
      def current
        @heading = "Current"
        @stream = Stream.open(params[:token])
        @entries = @stream.current.list(limit: params[:limit])
        render "current", status: :unprocessable_entity
      end

      def refresh
        @stream = Stream.open(params[:token])
        render "refresh", status: :ok
      end
    end
  end
end

class Archived
  class Events
    class V2
      def archived
        @heading = "Archived"
        @stream = Stream.open(params[:token])
        @entries = @stream.archived.list(limit: params[:limit])
        render "archive", status: :unprocessable_entity
      end

      def refresh
        @stream = Stream.open(params[:token])
        render "refresh", status: :ok
      end
    end
  end

  class Entries
    class V2
      def archived
        @heading = "Archived"
        @stream = Stream.open(params[:token])
        @entries = @stream.archived.list(limit: params[:limit])
        render "archive", status: :unprocessable_entity
      end

      def refresh
        @stream = Stream.open(params[:token])
        render "refresh", status: :ok
      end
    end
  end
end
