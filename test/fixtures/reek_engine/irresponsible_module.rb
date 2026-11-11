module Outer
  class Undocumented
  end

  # Describes a documented class well.
  class Documented
  end

  Point = Struct.new(:x, :y)
  # Builds a widget type for tests.
  Widget = Class.new(Base)
  Value = Data.define(:amount)
  LIMIT = 10

  module Inner::Deep
    class Leaf; end
  end
end

module Mixed
  def helper; end
end

# :reek:IrresponsibleModule
class Suppressed
  class Child
  end
end

class Single # trailing comment here
end

# One
class Terse
end
