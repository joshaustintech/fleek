# frozen_string_literal: true

require_relative "mutation_contract_cache"

cache = MutationContractCache.new(ARGV.fetch(0))
exit 1 unless cache.publish(ARGV.fetch(1), ARGV.fetch(2), ARGV.fetch(3))
