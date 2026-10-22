module UsersHelper
  def gravatar_for(user, options = { size: ENV.fetch("SIZE") })
    options[:size]
  end
end
