# Fleek

Fleek is a native macOS arm64 CLI, implemented in Spinel, that analyzes Ruby source with explicitly selected Flay structural-duplication and Reek ClassVariable checks. Analyzed Ruby source does not need to compile as Spinel. Fleek does not execute source or load the project’s dependencies.

## Install

Download [Fleek 0.2.0](https://github.com/joshaustintech/fleek/releases/tag/v0.2.0), verify the adjacent SHA-256 file, then extract the archive:

```sh
shasum -a 256 -c fleek-0.2.0-macos-arm64.tar.gz.sha256
tar -xzf fleek-0.2.0-macos-arm64.tar.gz
cd fleek-0.2.0-macos-arm64
./fleek --help
```

The executable is a native arm64 Mach-O and needs no Ruby, Flay, Reek, Spinel, project checkout, or network connection at runtime. It has an ad hoc linker signature and is not notarized.

## Run checks

Select every check explicitly. Fleek never treats an omitted or unsupported check as successfully run.

```sh
./fleek --checks flay:StructuralDuplication,reek:ClassVariable app/
./fleek --checks flay:StructuralDuplication lib/one.rb lib/two.rb
./fleek --checks reek:ClassVariable --stdin snippet.rb < snippet.rb
```

Exit status is 0 for complete clean analysis, 2 for complete analysis with findings, and 1 for invalid or incomplete analysis. Findings can remain visible when coverage is partial, but partial analysis exits 1. Reports separate duplication groups and smell findings, list selected checks and source coverage, and put diagnostics on stderr.

Flay supports bounded syntax: selected top-level parameterless methods and simple class or module methods with required positional parameters, plus documented bounded expressions and control flow. Unsupported candidates make coverage partial. Reek support is limited to ClassVariable with the documented configuration subset. Unsupported checks, options, settings, formats, and syntax are reported explicitly. See [the supported language and parity boundaries](docs/research/rails-project-parity.md) and [ADRs](docs/adr/).

The pinned 25-file Rails corpus demonstrates exact Flay group, mass, score, and locations plus clean Reek ClassVariable findings. Fleek reports all 25 Flay sources as partial because class-level declarations and other syntax remain unsupported; it reports 0/25 fully analyzed, warns about omitted candidates, and exits 1. This is useful partial coverage, not full Rails Flay parity.

## Build and verify

Fleek is implemented in Spinel 2026.09.12. Ruby input uses Ruby 4 grammar and need not be valid Spinel source. With the pinned compiler and locked reference bundle available:

```sh
bundle install
SPINEL=/path/to/pinned-spinel/bin/spinel SPINEL_ROOT=/path/to/pinned-spinel BUNDLE_PATH=/path/to/bundle make -B check
```

Run `make setup-git` once per clone to set the required author identity and enable the repository commit hook. The hook rejects other authors and writes the Codex co-author trailer on every commit.

The full check builds the native executable, runs CLI and reference contracts, proves behavioral mutations are caught, and requires zero Flay/Reek findings in Fleek’s own source. `make rails-manifest-parity` verifies identical pinned Rails inputs against upstream tools. `make runtime-evidence` records repeated cold-process comparisons after semantic equivalence passes.

The [Spinel toolchain guide](docs/agents/spinel.md), [runtime receipt](docs/research/cold-runtime-2026-10-15.md), [v0.2.0 archive receipt](docs/research/native-archive-0.2.0.md), [release notes](release/0.2.0.md), and [decision records](docs/adr/) describe reproducibility and known limits.
