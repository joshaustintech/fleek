module Current::Api::V1::Versioned::Feeds::V2::Read::V3::Internal::Adapter::Backend::Gateway
  class Feed
    def current
      @heading = "Current"
      @stream = Stream.open(params[:token])
      @entries = @stream.current.list(limit: params[:limit])
      render "current", status: :unprocessable_entity
    end
  end
end

module Archived::Api::V1::Versioned::Feeds::V2::Read::V3::Internal::Adapter::Backend::Gateway
  class Feed
    def archived
      @heading = "Archived"
      @stream = Stream.open(params[:token])
      @entries = @stream.archived.list(limit: params[:limit])
      render "archive", status: :unprocessable_entity
    end
  end
end
