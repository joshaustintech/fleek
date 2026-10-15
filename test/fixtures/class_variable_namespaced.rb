module ApplicationCable
  class Connection < Base
    @@count = 0

    def self.count
      @@count
    end
  end
end
