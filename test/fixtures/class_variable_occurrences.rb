class Ledger
  @@total = 0

  def total
    @@total
  end

  def add(value)
    @@total += value
  end

  @@label = "ledger"
end
