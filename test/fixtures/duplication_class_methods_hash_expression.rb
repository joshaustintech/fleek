class CurrentFeed
  def entries
    return {token: params[:token], limit: params[:limit], state: params[:state],
      source: params[:source], mode: :current, page: params[:page], owner: params[:owner]}
  end
end

class ArchivedFeed
  def entries
    return {token: params[:token], limit: params[:limit], state: params[:state],
      source: params[:source], mode: :archived, page: params[:page], owner: params[:owner]}
  end
end
