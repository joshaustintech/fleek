module Current
  module Versioned
    module Feed
      def current
        @heading = "Current"
        @stream = Stream.open(params[:token])
        render "current", status: :unprocessable_entity
      end
    end
  end
end

module Archived
  module Versioned
    module Feed
      def archived
        @heading = "Archived"
        @stream = Stream.open(params[:token])
        render "archive", status: :unprocessable_entity
      end
    end
  end
end
