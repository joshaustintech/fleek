# Exercises Reek iterator nesting.
class Walker
  def two_deep(rows)
    rows.each do |row|
      row.cells.each { |cell| emit(cell) }
    end
  end

  def three_deep(rows)
    rows.each do |row|
      row.cells.each do |cell|
        cell.parts.map { |part| part.name }
      end
      row.tags.each { |tag| record(tag) }
    end
  end

  def chained(items)
    items.map { |item| item.value }.select { |value| value.ready? }
  end

  def in_call(groups)
    groups.map { |group| group.items.each { |item| emit(item) } }.each { |found| record(found) }
  end

  def ignored(rows)
    rows.tap { |list| list.each { |row| emit(row) } }
    Tempfile.create("x") { |file| rows.each { |row| file.write(row) } }
    rows.each { rows.each { |row| emit(row) } }
  end

  def self.singleton(rows)
    rows.each { |row| row.each { |cell| emit(cell) } }
  end

  # :reek:NestedIterators { max_allowed_nesting: 2 }
  def relaxed(rows)
    rows.each { |row| row.each { |cell| emit(cell) } }
  end

  # :reek:NestedIterators
  def silenced(rows)
    rows.each { |row| row.each { |cell| emit(cell) } }
  end
end
