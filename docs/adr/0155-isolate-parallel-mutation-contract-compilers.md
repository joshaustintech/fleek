# ADR 0155: Isolate parallel mutation contract compilers

## Status

Accepted

## Context

Pinned Spinel 2026.09.12 failed repeatably while precompiling the 40 mapped mutation contracts with two, four, or eight compiler processes. The linker reported `errno=21 (Is a directory)` for the shared contract output directory while compiling `duplication_method_interpolated_string_contract.rb`. Serial compilation passed in about 38 seconds. The compiler uses `TMPDIR` for generated C and intermediate binaries; all concurrent precompile processes previously inherited the same system temp directory.

## Decision

Give each mapped contract compilation its own directory under the run-specific `FLEEK_TEMP_ROOT` and pass it as `TMPDIR` to that Spinel process. Keep precompilation bounded by `JOBS` and retain parallel mutation workers.

## Consequences

All 40 shared contract binaries now precompile successfully with `JOBS=8` in about 30 seconds, while preserving the existing public contract mapping and worker isolation. The temporary directories are contained under the precompile root and removed by the runner cleanup. Full project gates remain required.
