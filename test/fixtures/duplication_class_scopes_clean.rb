class CurrentFeed
  def current
    @heading = "Current"
    render "current"
  end
end

module Archive
  class Feed
    def archived
      @heading = "Archived"
      render "archive", status: :gone
    end
  end
end
