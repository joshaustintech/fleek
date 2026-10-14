# Fleek

Fleek is a native Ruby analysis CLI implemented in Spinel. Its first analysis check reproduces Reek's `ClassVariable` smell for a bounded Ruby source subset. Unsupported checks and source contexts fail explicitly.

Build and verify with the pinned Spinel executable and locked reference tools:

```sh
bundle install
SPINEL=/path/to/pinned-spinel/bin/spinel SPINEL_ROOT=/path/to/pinned-spinel make check
```

`make check` builds the native executable, compares selected ClassVariable findings with locked Reek, verifies the parser and CLI contracts, runs mutation checks, executes the locked Flay/Reek reference fixture, then requires zero Flay score and zero Reek warnings for project code. Explicit `.rb` paths and recursive directories are accepted by `build/fleek --checks reek:ClassVariable path.rb`. Hidden directories and directory symlinks are skipped during scans; `.rb` file symlinks are included; repeated explicit paths are analyzed repeatedly. An explicit directory symlink, non-Ruby path, missing/unreadable path, or input set with no Ruby sources is an error. Mixed good and failed inputs retain findings but report incomplete coverage and exit 1. See ADRs 0009–0011 for the check's limits and input policy. The parser probe is `build/fleek --parse-ruby4 path.rb`; its success reports parsing only, never that an analysis check ran.

The Spinel release and its dependency identities are recorded in [the toolchain guide](docs/agents/spinel.md). Parser scope and ClassVariable boundaries are recorded in [ADR 0008](docs/adr/0008-native-parser-prototype.md), [ADR 0009](docs/adr/0009-classvariable-native-slice.md), [ADR 0010](docs/adr/0010-classvariable-occurrence-groups.md), and [ADR 0011](docs/adr/0011-file-and-directory-scan-contract.md). Reference versions and transitive dependency checksums are locked in `Gemfile.lock`.
