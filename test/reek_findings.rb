# :reek:TooManyStatements
# Normalizes Reek and Fleek smell findings as sorted "path|[lines]:Smell: message" strings.
module ReekFindings
  def self.reference(output)
    findings = []
    path = ""
    output.lines.each do |line|
      header = line.match(/^(\S+) -- \d+ warnings?:/)
      if header
        path = header[1]
      elsif line.start_with?("  [")
        findings << "#{path}|#{strip_link(line.strip)}"
      end
    end
    findings.sort
  end

  def self.native(output)
    findings = []
    output.lines.each do |line|
      next unless line.include?("Finding: check=")
      source = line.match(/ source="([^"]+)"/)
      message = line.match(/ message="(.*)"$/)
      findings << "#{source[1]}|#{strip_link(message[1].gsub("\\\"", "\""))}" if source && message
    end
    findings.sort
  end

  def self.strip_link(text)
    text.sub(/ \[https:[^\]]*\]$/, "")
  end
end
