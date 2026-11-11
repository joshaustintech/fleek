# Class API fixtures for attributes, instance variable assumptions, core subclasses, bang methods and manual dispatch.
class Api < Hash
  attr_accessor :name, "label"
  attr :flag, true
  attr_reader :read_only
  private attr_writer :hidden_inline
  private
  attr_writer :secret
  public
  attr_writer :visible
  private :visible

  class << self
    attr_accessor :registry
  end

  def initialize
    @name = nil
    @count ||= 0
  end

  def total
    @count + @missing + @missing
  end

  def cache
    @cached ||= @source
  end

  def save!
    true
  end

  def save
    false
  end

  def reset!
    @name = nil
  end

  def destroy!; end

  def dispatch(target)
    target.respond_to?(:call) && target.call
    respond_to?(:other) ? 1 : target&.respond_to?(:x)
  end

  def self.build!; end
end

List = Class.new(Array) do
  def flatten!; end
end

Text = Class.new(::String)

class Wrapped < ::Hash
end

# :reek:MissingSafeMethod { exclude: ['purge!'] }
class Purger
  def purge!; end
  def wipe!; end
end
