SPINEL ?= spinel
SPINEL_ROOT ?= $(dir $(SPINEL))..
FLEEK = build/fleek

.PHONY: all test verify-spinel mutation reference flay reek check

all: verify-spinel $(FLEEK)

$(FLEEK): bin/fleek.rb
	mkdir -p build
	$(SPINEL) $< -o $@

verify-spinel:
	$(SPINEL) -E test/spinel_version_contract.rb $(SPINEL) $(SPINEL_ROOT)

test: verify-spinel $(FLEEK)
	$(SPINEL) -E test/cli_contract.rb

mutation: verify-spinel $(FLEEK)
	$(SPINEL) -E test/mutation_contract.rb
	$(SPINEL) bin/fleek.rb -o $(FLEEK)
	$(SPINEL) -E test/cli_contract.rb

reference:
	bundle exec flay test/fixtures/reference.rb
	bundle exec reek test/fixtures/reference.rb

flay:
	bundle exec flay bin test/*.rb

reek:
	bundle exec reek bin test/*.rb

check: test mutation reference flay reek
