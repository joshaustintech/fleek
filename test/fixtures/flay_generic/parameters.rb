class Router
  def self.draw(path, (verb, name), *middleware, format: :html, strict:, **constraints, &block)
    $routes = nil
    @@count = 0
    Routes::Table.add(path, verb, name, *middleware, format, strict, constraints, &block)
  end

  def self.mount(target, (method, label), *stack, format: :json, strict:, **rules, &handler)
    $routes = nil
    @@count = 0
    Routes::Table.add(target, method, label, *stack, format, strict, rules, &handler)
  end
end
