# Fleek 0.1.0 native archive receipt

## Artifact identity

- Archive: [`dist/fleek-0.1.0-macos-arm64.tar.gz`](../../dist/fleek-0.1.0-macos-arm64.tar.gz)
- SHA-256: `de453b0210372ca7a6501584a890f4005d19758681c9cf12fef8239c74f476f7`
- Platform: macOS arm64, tested on macOS 27.0.1 build 26A434.
- Executable: Mach-O 64-bit arm64; Fleek 0.1.0; Spinel 2026.09.12; Prism 1.9.0; references Flay 2.14.4 and Reek 6.6.0.
- Dynamic libraries: `/usr/lib/libSystem.B.dylib` only.
- Signature: ad hoc linker signature, no Team ID; not notarized.
- Notices: Fleek Apache License 2.0 and statically linked Prism MIT license are included.

## Extracted behavior

`make verify-macos-arm64-archive` creates and extracts the archive into a temporary directory. Its Spinel Ruby contract invokes the extracted executable with `PATH=` so Ruby, Flay, Reek, Spinel, and helper commands cannot be discovered by the child process. The contract checks architecture, dynamic linkage, signature, version, license notices, and exact CLI outcomes:

- Combined Flay and Reek checks on `examples/clean.rb`: exit 0, complete.
- Reek ClassVariable on `examples/finding.rb`: exit 2, finding at line 2 in `Counter` for `@@count`.
- Flay on `examples/incomplete.rb`: exit 1, partial source, similar `:defn` group at lines 4 and 15, mass/score 48, coverage 0/1 analyzed.

## Scope and distribution

The archive is a native install proof for the bounded supported checks. The pinned 25-file Rails corpus still yields the matching Flay score-48 group and clean Reek ClassVariable result, while Fleek reports Flay coverage 0/25 fully analyzed, 25 partial, overall incomplete, exit 1. See [the Rails parity receipt](rails-project-parity.md) and [ADR 0032](../adr/0032-first-native-archive-scope.md).

The executable has an ad hoc linker signature; no Developer ID signing or notarization is present. This artifact is committed to the source repository and has not been published to a downloadable release service or retrieved from one. Ticket 17 remains open for those checks.
