# Duplicate method call fixtures covering receivers, blocks, assignments and limits.
class Calls
  def repeated(params)
    params[:session].email
    params[:session].email
    params[:session][:remember] == "1"
  end

  def bare
    helper
    helper
    helper(1)
    helper(1)
  end

  def created
    Item.new
    Item.new
  end

  def blocks(items)
    items.each { |item| item.save }
    items.each { |item| item.save }
  end

  def multiline(record)
    record.update(
      name: "x")
    record.update(
      name: "x")
  end

  def assigned(record)
    a, b = record.pair, record.pair
    record.pair
  end

  def targets(record)
    record.a, record.b = 1, 2
    record.a, record.b = 3, 4
  end

  def nested(record)
    Class.new { def inner = record.size + record.size }
    record.size
  end

  # :reek:DuplicateMethodCall { max_calls: 2 }
  def limited(record)
    record.size + record.size
    record.name + record.name + record.name
  end

  # :reek:DuplicateMethodCall { allow_calls: ['record.size'] }
  def allowed(record)
    record.size + record.size
    record.name + record.name
  end

  def self.singleton(record)
    record.name + record.name
  end
end
