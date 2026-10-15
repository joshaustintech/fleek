class CurrentFeed
  def fetch
    value = Feed.load
    Feed.check
    Feed.render
    Feed.record
    Feed.finish
    Feed.clean
    Feed.refresh
    Feed.publish
    Feed.archive
  end

  def noop
    Feed.noop
  end
end

class ArchivedFeed
  def fetch
    result = Feed.load
    Feed.check
    Feed.render
    Feed.record
    Feed.finish
    Feed.clean
    Feed.refresh
    Feed.publish
    Feed.archive
  end
end
