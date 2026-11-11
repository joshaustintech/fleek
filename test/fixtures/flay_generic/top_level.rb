SETTINGS = { host: "localhost", port: 3000, ssl: false, timeout: 30, pool: [1, 2, 3], tags: %w[a b] }
FALLBACK = { host: "example.com", port: 443, ssl: false, timeout: 60, pool: [4, 5, 6], tags: %w[c d] }
handler = ->(event) { puts(event.name) unless event.nil? && event.ignored? || event.payload[:skip] }
logger = ->(entry) { warn(entry.text) unless entry.nil? && entry.skipped? || entry.payload[:skip] }
$stdout.sync = true if ENV.fetch("MODE", "dev") != "test" && ENV["SYNC"] == "1" and not ENV.key?("NOSYNC")
$stderr.sync = true if ENV.fetch("MODE", "dev") != "test" && ENV["SYNC"] == "1" and not ENV.key?("NOSYNC")
puts(ENV.fetch("MODE", "dev").upcase, [1, 2, 3].sum, { key: :value }.size) if $DEBUG
puts(ENV.fetch("MODE", "dev").upcase, [1, 2, 3].sum, { key: :value }.size) if $DEBUG
