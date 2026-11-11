# Uncommunicative name fixtures for methods, modules, parameters and variables.
module M
  class X1
    @a = 1

    def x(a, _b, _c, b2, *, camelCase: 1, &q)
      _c
      y = a
      z1 = y
      [1].each { |e, (f, g2)| e + f + g2 }
      ->(h) { h }
      @iVar = z1
      _ = 1
      camelCase + b2 + q.call
    end

    def m9; end
    def self.N; end
    def good_name(value) = value
    def ==(other) = other

    [1].each { |k| k }
  end

  # :reek:UncommunicativeModuleName { accept: ['M::Long::Q'] }
  module Long::Q
  end

  class Fine
    # :reek:UncommunicativeVariableName { accept: ['^x$'] }
    def accepted
      x = 1
      w = x
    end
  end
end
