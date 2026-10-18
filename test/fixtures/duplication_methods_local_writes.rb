def current(name)
  title = Feed.title(name)
  rows = Feed.current_rows(title)
  count = Feed.row_count(rows)
  render(title, rows)
  render_count(count)
end

def archived(name)
  title = Feed.title(name)
  rows = Feed.archived_rows(title)
  count = Feed.row_count(rows)
  render(title, rows)
  render_count(count)
end
