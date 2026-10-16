class Workflow
  def supported
    first
    second
    third
    fourth
    fifth
    sixth
  end

  def unsupported
    if active?
      first
      second
      third
      fourth
      fifth
      sixth
    end
  end
end
