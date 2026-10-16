class Workflow
  def supported
    first
    second
    third
    fourth
    fifth
    sixth
  end

  class << self
    def dispatch
      first
      second
      third
      fourth
      fifth
      sixth
    end
  end
end
