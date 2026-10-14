# Fleek

Fleek is a native Ruby analysis CLI. The first slice exposes honest help and version output; analysis checks are not available yet, and unsupported checks fail.

Build and verify with the pinned Spinel executable and locked reference tools:

```sh
bundle install
SPINEL=/path/to/pinned-spinel/bin/spinel SPINEL_ROOT=/path/to/pinned-spinel make check
```

`make check` builds the native executable, runs CLI and mutation contracts, executes the locked Flay/Reek reference fixture, then requires zero Flay score and zero Reek warnings for project code. The CLI tests and mutation harness run as Spinel Ruby programs. For a manual mutation check, change the no-argument exit status in `bin/fleek.rb` from 1 to 0, run `SPINEL=/path/to/pinned-spinel/bin/spinel make test` and confirm it fails, restore the status, then rerun the test.

The Spinel release and its dependency identities are recorded in [the toolchain guide](docs/agents/spinel.md). Reference versions and transitive dependency checksums are locked in `Gemfile.lock`.
