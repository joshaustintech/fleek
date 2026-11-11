# Module size fixtures for constants, instance variables, methods and module initializers.
# :reek:TooManyMethods { max_methods: 5 }
# :reek:TooManyConstants { max_constants: 3 }
class Large
  A = 1
  B = 2
  C = 3
  Item = Struct.new(:name)
  Other = Class.new

  def one
    @a = 1
    @b = 2
    @c ||= 3
    @d += 1
    @a = 4
  end

  def two
    @e = 5
    @f = 6
  end

  [2].each do
    D = 4
  end

  def three
  end

  def four; end
  def five; end

  class << self
    def six; end
  end

  def self.seven; end

  class Inner
    G = 7
    H = 8
    I = 9
    J = 10
    K = 11
    L = 12

    def a; @w = 1; @x = 2; @y = 3; @z = 4; @v = 5; end
  end
end

module Initializing
  def initialize
    @ready = true
  end

  module Nested
    attr_writer :initialize
  end

  module Singleton
    def self.initialize; end
  end
end

# :reek:TooManyMethods { max_methods: 1 }
class Configured
  def a; end
  def b; end
end

# :reek:TooManyConstants { max_constants: 1 }
module Limited
  X = 1
  Y = 2
end
