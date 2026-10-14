# Fleek

Fleek is a native Ruby analysis CLI. The current parser prototype can report Ruby 4.0 parsing only; no analysis checks are available yet, and unsupported checks fail.

Build and verify with the pinned Spinel executable and locked reference tools:

```sh
bundle install
SPINEL=/path/to/pinned-spinel/bin/spinel SPINEL_ROOT=/path/to/pinned-spinel make check
```

`make check` builds the native executable, compares selected ClassVariable findings with locked Reek, verifies the parser and CLI contracts, runs mutation checks, executes the locked Flay/Reek reference fixture, then requires zero Flay score and zero Reek warnings for project code. The supported smell is explicitly selected with `build/fleek --checks reek:ClassVariable path.rb`. Its current bounded scope and unsupported contexts are recorded in ADRs 0009 and 0010. The parser probe is `build/fleek --parse-ruby4 path.rb`; its success reports parsing only, never that an analysis check ran.

The Spinel release and its dependency identities are recorded in [the toolchain guide](docs/agents/spinel.md). Parser scope and ClassVariable boundaries are recorded in [ADR 0008](docs/adr/0008-native-parser-prototype.md), [ADR 0009](docs/adr/0009-classvariable-native-slice.md), and [ADR 0010](docs/adr/0010-classvariable-occurrence-groups.md). Reference versions and transitive dependency checksums are locked in `Gemfile.lock`.
