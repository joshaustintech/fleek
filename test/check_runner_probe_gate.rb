# frozen_string_literal: true

root = ENV.fetch("FLEEK_PROBE_GATE_ROOT")
marker = ENV.fetch("FLEEK_PROBE_GATE_MARKER")
until File.exist?("#{root}/#{marker}")
end
