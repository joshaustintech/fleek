module ApplicationCable
  module Internal
    class Connection
      @@count = 0

      @@count += 1

      def self.current
        @@count
      end
    end
  end
end
