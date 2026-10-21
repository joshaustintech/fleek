class Fleet
  class Shipment
    def initialize
      @id = nil
      @status = nil
      @origin = nil
      @destination = nil
      @weight = nil
      @id ||= 1
    end

    def reference
      @weight
    end
  end

  class Parcel
    def initialize
      @id = nil
      @status = nil
      @tracking = nil
      @delivered = false
      @tracking = @tracking
    end
  end
end
