# Utility function fixtures covering instance state, visibility and singleton contexts.
class Utility
  def format(value)
    value.to_s
  end

  def constant
    42
  end

  def stateful(value)
    @value = value.to_s
  end

  def implicit(value)
    helper(value)
  end

  def explicit(value)
    self.class.name + value.to_s
  end

  def inherited(value)
    super
  end

  def nested_class(value)
    Class.new { def inside; puts; end }
    value.to_s
  end

  def self.singleton(value)
    value.to_s
  end

  class << self
    def ghost(value)
      value.to_s
    end
  end

  def inner(value)
    def deeper(other)
      other.to_s
    end
  end

  private

  def hidden(value)
    value.to_s
  end

  # :reek:UtilityFunction { public_methods_only: true }
  def quiet(value)
    value.to_s
  end

  module_function

  def shared(value)
    value.to_s
  end
end

# Methods with configured visibility.
# :reek:UtilityFunction { public_methods_only: true }
module Visibility
  def named(value)
    value.to_s
  end
  private :named

  def public_again(value)
    value.to_s
  end

  # :reek:UtilityFunction
  def silenced(value)
    value.to_s
  end

  protected def inline(value)
    value.to_s
  end

  def safe(value)
    value&.to_s
  end
end
