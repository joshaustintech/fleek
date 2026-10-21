class Parcel
  def archive
    :done
  end

  class << self
    def deliver!
      :done
    end

    def archive!
      :done
    end

    def archive
      :done
    end
  end
end
