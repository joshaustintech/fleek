class Outer::A
  class B
  end
  class C; end
  def work(x, *rest)
    local = 1
    [1].each { |item| puts item }
  end
end
