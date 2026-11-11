# Normalizes Flay and Fleek duplication groups as [node, kind, mass, score, locations].
module FlayGroups
  HEADER = /^\d+\) (Similar|IDENTICAL) code found in :(\w+) \(mass(\*(\d+))? = (\d+)\)$/

  def self.reference(output)
    groups = []
    output.lines.each { |line| reference_line(groups, line) }
    groups
  end

  def self.reference_line(groups, line)
    header = line.match(HEADER)
    if header
      groups << reference_group(header)
    elsif !groups.empty? && line.start_with?("  ")
      groups[-1][4] << line.strip
    end
  end

  def self.reference_group(header)
    score = header[5].to_i
    multiplier = (header[4] || "1").to_i
    [header[2], header[1] == "IDENTICAL" ? "identical" : "similar", score / multiplier, score, []]
  end

  def self.native(output)
    groups = []
    output.lines.each do |line|
      next unless line.start_with?("  Group: ")
      groups << [capture(line, / node="([^"]+)"/), capture(line, / kind="([^"]+)"/), capture(line, / mass=(\d+)/).to_i,
        capture(line, / score=(\d+)/).to_i, capture(line, / locations="([^"]+)"/).split(",")]
    end
    groups
  end

  def self.capture(text, pattern)
    match = text.match(pattern)
    match ? match[1] : ""
  end
end
