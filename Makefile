SPINEL ?= spinel
SPINEL_ROOT ?= $(dir $(SPINEL))..
export SPINEL SPINEL_ROOT
FLEEK = build/fleek

.PHONY: all test verify-spinel mutation reference flay reek check rails-controller-parity package-macos-arm64 verify-macos-arm64-archive

all: verify-spinel $(FLEEK)

$(FLEEK): bin/fleek.rb
	mkdir -p build
	CPATH=$(SPINEL_ROOT)/vendor/prism/include $(SPINEL) $< -o $@ --link $(SPINEL_ROOT)/build/libprism.a

verify-spinel:
	$(SPINEL) -E test/spinel_version_contract.rb $(SPINEL) $(SPINEL_ROOT)

test: verify-spinel $(FLEEK)
	$(SPINEL) -E test/cli_contract.rb
	$(SPINEL) -E test/text_report_contract.rb
	$(SPINEL) -E test/duplication_contract.rb
	$(SPINEL) -E test/combined_contract.rb
	$(SPINEL) -E test/language_extensions_contract.rb
	$(SPINEL) -E test/native_parser_contract.rb
	$(SPINEL) -E test/class_variable_contract.rb
	$(SPINEL) -E test/class_variable_scope_contract.rb
	$(SPINEL) -E test/analysis_runner.rb
	$(SPINEL) -E test/analysis_stdin_contract.rb
	$(SPINEL) -E test/analysis_inputs_contract.rb
	$(SPINEL) -E test/configuration_contract.rb

mutation: verify-spinel $(FLEEK)
	$(SPINEL) -E test/mutation_contract.rb
	$(SPINEL) -E test/cli_contract.rb

reference:
	bundle exec flay test/fixtures/reference.rb
	bundle exec reek test/fixtures/reference.rb

flay:
	bundle exec flay bin test/*.rb

reek:
	bundle exec reek bin test/*.rb

check: test mutation reference flay reek

rails-controller-parity: all
	FLEEK_REQUIRE_RAILS_CORPUS=1 $(SPINEL) -E test/duplication_contract.rb

package-macos-arm64: all
	mkdir -p build/fleek-0.1.0-macos-arm64/examples dist
	cp $(FLEEK) build/fleek-0.1.0-macos-arm64/fleek
	cp LICENSE build/fleek-0.1.0-macos-arm64/LICENSE-Fleek.txt
	cp $(SPINEL_ROOT)/vendor/prism/LICENSE.md build/fleek-0.1.0-macos-arm64/LICENSE-Prism.txt
	cp release/macos-arm64/README.txt build/fleek-0.1.0-macos-arm64/README.txt
	cp release/macos-arm64/examples/*.rb build/fleek-0.1.0-macos-arm64/examples/
	tar -czf dist/fleek-0.1.0-macos-arm64.tar.gz -C build fleek-0.1.0-macos-arm64/fleek fleek-0.1.0-macos-arm64/LICENSE-Fleek.txt fleek-0.1.0-macos-arm64/LICENSE-Prism.txt fleek-0.1.0-macos-arm64/README.txt fleek-0.1.0-macos-arm64/examples/clean.rb fleek-0.1.0-macos-arm64/examples/finding.rb fleek-0.1.0-macos-arm64/examples/incomplete.rb
	shasum -a 256 dist/fleek-0.1.0-macos-arm64.tar.gz > dist/fleek-0.1.0-macos-arm64.tar.gz.sha256

verify-macos-arm64-archive: package-macos-arm64
	$(SPINEL) -E test/archive_contract.rb
