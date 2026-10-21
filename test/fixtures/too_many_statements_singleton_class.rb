class Workflow
  class << self
    def clean_dispatch
      first
      second
      third
      fourth
      fifth
    end

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
