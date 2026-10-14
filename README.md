# Fleek

Fleek is a native Ruby analysis CLI. The current parser prototype can report Ruby 4.0 parsing only; no analysis checks are available yet, and unsupported checks fail.

Build and verify with the pinned Spinel executable and locked reference tools:

```sh
bundle install
SPINEL=/path/to/pinned-spinel/bin/spinel SPINEL_ROOT=/path/to/pinned-spinel make check
```

`make check` builds the native executable, tests the parser with Ruby 4.0 syntax and a Spinel FFI declaration, runs CLI and mutation contracts, executes the locked Flay/Reek reference fixture, then requires zero Flay score and zero Reek warnings for project code. Mutation checks exercise usage status, Ruby 4.0 grammar selection, source locations, and embedded NUL rejection. The CLI tests and mutation harness run as Spinel Ruby programs. The parser probe is `build/fleek --parse-ruby4 path.rb`; its success reports parsing only, never that an analysis check ran.

The Spinel release and its dependency identities are recorded in [the toolchain guide](docs/agents/spinel.md). Parser scope and limitations are recorded in [ADR 0008](docs/adr/0008-native-parser-prototype.md). Reference versions and transitive dependency checksums are locked in `Gemfile.lock`.
