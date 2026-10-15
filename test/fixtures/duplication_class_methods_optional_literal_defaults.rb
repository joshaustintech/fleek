class Feed
  def page(resource, text = "default", symbol = :primary, enabled = true, disabled = false, missing = nil)
    resource.fetch(:value)
    resource.fetch(:name)
    render "page"
  end

  def home(resource, text = "default", symbol = :primary, enabled = true, disabled = false, missing = nil)
    resource.fetch(:value)
    resource.fetch(:name)
    render "home"
  end
end
