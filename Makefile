SPINEL ?= spinel
SPINEL_ROOT ?= $(dir $(SPINEL))..
export SPINEL SPINEL_ROOT
ifneq ($(JOBS),)
export JOBS
endif
FLEEK = build/fleek
RUNTIME_REPETITIONS ?= 20

.PHONY: all setup-git test verify-spinel mutation reference flay reek check ticket-check rails-controller-parity rails-manifest-parity runtime-evidence package-macos-arm64 verify-macos-arm64-archive

all: verify-spinel $(FLEEK)

setup-git:
	git config core.hooksPath .githooks
	git config user.name "Josh Austin"
	git config user.email "83935880+joshaustintech@users.noreply.github.com"

$(FLEEK): bin/fleek.rb
	mkdir -p build
	CPATH=$(SPINEL_ROOT)/vendor/prism/include $(SPINEL) $< -o $@ --link $(SPINEL_ROOT)/build/libprism.a

verify-spinel:
	$(SPINEL) -E test/spinel_version_contract.rb $(SPINEL) $(SPINEL_ROOT)

test: verify-spinel $(FLEEK)
	$(SPINEL) -E bin/check_runner.rb test

mutation: verify-spinel $(FLEEK)
	$(SPINEL) -E bin/check_runner.rb mutation

reference:
	bundle exec flay test/fixtures/reference.rb
	bundle exec reek test/fixtures/reference.rb

flay:
	bundle exec flay bin test/*.rb

reek:
	bundle exec reek bin test/*.rb

check: verify-spinel $(FLEEK)
	$(SPINEL) -E bin/check_runner.rb check

ticket-check: verify-spinel
	$(SPINEL) -E bin/ticket_check.rb .scratch

rails-manifest-parity: all
	FLEEK_REQUIRE_RAILS_CORPUS=1 $(SPINEL) -E test/duplication_contract.rb
	FLEEK_REQUIRE_RAILS_CORPUS=1 $(SPINEL) -E test/rails_manifest_parity_contract.rb

rails-controller-parity: rails-manifest-parity

runtime-evidence: all
	$(SPINEL) -E test/runtime_evidence.rb --measure $(RUNTIME_REPETITIONS)

package-macos-arm64: all
	mkdir -p build/fleek-0.2.0-macos-arm64/examples dist
	cp $(FLEEK) build/fleek-0.2.0-macos-arm64/fleek
	cp LICENSE build/fleek-0.2.0-macos-arm64/LICENSE-Fleek.txt
	cp $(SPINEL_ROOT)/vendor/prism/LICENSE.md build/fleek-0.2.0-macos-arm64/LICENSE-Prism.txt
	cp release/macos-arm64/README.txt build/fleek-0.2.0-macos-arm64/README.txt
	cp release/macos-arm64/examples/*.rb build/fleek-0.2.0-macos-arm64/examples/
	tar -czf dist/fleek-0.2.0-macos-arm64.tar.gz -C build fleek-0.2.0-macos-arm64/fleek fleek-0.2.0-macos-arm64/LICENSE-Fleek.txt fleek-0.2.0-macos-arm64/LICENSE-Prism.txt fleek-0.2.0-macos-arm64/README.txt fleek-0.2.0-macos-arm64/examples/clean.rb fleek-0.2.0-macos-arm64/examples/finding.rb fleek-0.2.0-macos-arm64/examples/incomplete.rb fleek-0.2.0-macos-arm64/examples/module-methods.rb
	shasum -a 256 dist/fleek-0.2.0-macos-arm64.tar.gz > dist/fleek-0.2.0-macos-arm64.tar.gz.sha256

verify-macos-arm64-archive: package-macos-arm64
	$(SPINEL) -E test/archive_contract.rb
