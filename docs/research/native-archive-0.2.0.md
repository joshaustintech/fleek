# Fleek 0.2.0 native archive receipt

## Artifact identity

- Release: [Fleek 0.2.0](https://github.com/joshaustintech/fleek/releases/tag/v0.2.0), tag `v0.2.0` at source commit `45b60d25bfa28c4ef5735c62fbc317644faa47b5`.
- Archive: [download](https://github.com/joshaustintech/fleek/releases/download/v0.2.0/fleek-0.2.0-macos-arm64.tar.gz), GitHub asset `RA_kwDOVJyNPM4mfIfe`, 471089 bytes.
- Archive SHA-256: `f27b518c877913b1383295aa8a0a2436e1352b5a8f39ad40af62ee002146a4fe`; the downloaded bytes matched the committed local archive byte-for-byte.
- Checksum sidecar: [download](https://github.com/joshaustintech/fleek/releases/download/v0.2.0/fleek-0.2.0-macos-arm64.tar.gz.sha256), GitHub asset `RA_kwDOVJyNPM4mfIfd`; downloaded sidecar SHA-256 `fa3f831a00c9f63cc54dbab5dc73a6d3c370a6694522eea3b74af5a66fa102fd`.
- The downloaded sidecar checksum passed against the downloaded archive.
- Platform: macOS arm64, tested on macOS 27.0.1 build 26A434. Executable is Mach-O arm64 and links only `/usr/lib/libSystem.B.dylib`.
- Executable: Fleek 0.2.0, Spinel 2026.09.12, Prism 1.9.0; reference versions Flay 2.14.4 and Reek 6.6.0.
- Signature: ad hoc linker signature, no Team ID; not notarized. Apache 2.0 and Prism MIT notices are included.

## Downloaded behavior

The release archive was downloaded from GitHub, checksum-verified, extracted, and tested on Apple Silicon. The extracted-runtime contract ran with an empty child `PATH`, so the CLI could not discover Ruby, Flay, Reek, Spinel, or helper commands. It verified architecture, dynamic linkage, signature, version, notices, help, and exact clean/finding/incomplete outcomes. The module-method Flay example reports mass/score 48 at lines 2 and 9 and exits 2. Clean complete analysis exits 0; incomplete Flay analysis exits 1.

The pinned Rails manifest comparison retains the matching Flay score-48 finding and clean Reek ClassVariable result. Fleek analyzes Reek completely on all 25 files; Flay marks all 25 partial and the combined invocation exits 1. Full Rails Flay parity is not claimed. Supported checks must be selected explicitly.

## Performance and verification

Twenty fresh-process runs on identical inputs and configurations passed semantic equivalence checks before timing. Fleek p95 was 3.854 ms for Flay versus 165.433 ms upstream, 6.432 ms for Reek on the pinned Rails corpus versus 358.990 ms, and 4.010 ms for combined checks versus 476.859 ms. Details and raw observations are in the [cold runtime receipt](cold-runtime-2026-10-15.md).

The repository's pinned Spinel full build/test, 93 mutation checks, Flay/Reek self-analysis, Rails manifest parity, and both specification and standards review axes passed for the release source and final documentation update.
