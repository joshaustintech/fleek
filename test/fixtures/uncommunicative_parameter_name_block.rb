class Worker
  def perform
    [1].each { |x| puts x }
    [2].each { |item| puts item }
  end
end
