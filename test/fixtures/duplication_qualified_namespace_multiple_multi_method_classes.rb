module Current::Versioned
  class Feed
    def first
      @value = 1
    end

    def second
      @value = 2
    end
  end

  class Archive
    def stored
      @value = 3
    end

    def archived
      @value = 4
    end
  end
end

module Previous::Versioned
  class Feed
    def first
      @value = 5
    end

    def second
      @value = 6
    end
  end

  class Archive
    def stored
      @value = 7
    end

    def archived
      @value = 8
    end
  end
end
