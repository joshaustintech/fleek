class Current
  class Events
    def index
      @heading = "Current"
      @stream = Stream.open(params[:token])
      render "current", status: :ok
    end

    def refresh
      @stream = Stream.open(params[:token])
      render "refresh", status: :ok
    end
  end

  class Entries
    def index
      @heading = "Current"
      @stream = Stream.open(params[:token])
      render "current", status: :ok
    end

    def refresh
      @stream = Stream.open(params[:token])
      render "refresh", status: :ok
    end
  end
end

class Archived
  class Events
    def index
      @heading = "Archived"
      @stream = Stream.open(params[:token])
      render "archived", status: :ok
    end

    def refresh
      @stream = Stream.open(params[:token])
      render "refresh", status: :ok
    end
  end

  class Entries
    def index
      @heading = "Archived"
      @stream = Stream.open(params[:token])
      render "archived", status: :ok
    end

    def refresh
      @stream = Stream.open(params[:token])
      render "refresh", status: :ok
    end
  end
end
