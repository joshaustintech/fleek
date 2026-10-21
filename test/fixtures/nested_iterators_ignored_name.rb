class Parcel
  def walk(rows)
    rows.each do |row|
      row.map do |item|
        item.each do |entry|
          ship(entry)
        end
      end
    end
  end
end
