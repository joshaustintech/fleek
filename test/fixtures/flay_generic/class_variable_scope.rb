class Registry
  @@entries = build_registry(:alpha, :beta, :gamma)

  def reset
    @@entries = build_registry(:alpha, :beta, :gamma)
  end
end
