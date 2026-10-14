# Fixture for running the locked reference analyzers on shared Ruby syntax.
class ReferenceFixture
  def initialize
    @value = 0
  end

  def first
    @value = @value + 1
  end

  def second
    @value = @value + 1
  end
end
