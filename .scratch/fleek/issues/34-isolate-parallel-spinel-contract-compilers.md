# 34: Isolate parallel Spinel contract compilers

**What to fix:** Full mutation precompilation fails when multiple Spinel compiler processes share the default temporary directory. The linker attempts to use the mutation-contract directory itself as an executable target.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Reproduction

- Pinned Spinel: `2026.09.12` / source `112bae85c1a25fc5399009a849f805bfe691426b`.
- Run `FLEEK_PRECOMPILE_MUTATION_CONTRACTS=1` through `bin/check_runner.rb` with `JOBS=8`.
- Reproduced with two and four simultaneous compiler processes; compilation fails on `test/duplication_method_interpolated_string_contract.rb` with `ld: open() failed, errno=21 (Is a directory)` for the shared output directory.
- A serial precompile of all 40 mapped contracts passes in about 38 seconds. Two direct, simultaneous compiles to distinct output files pass, narrowing the collision to the mutation precompile's shared temp environment.

## Acceptance criteria

- [x] Each parallel Spinel compiler has a distinct temporary directory.
- [x] Full mapped contract precompilation passes with `JOBS=8` (40 contracts, about 30 seconds).
- [x] Eight mutation workers remain isolated and catch all configured non-equivalent mutants.
- [x] Full project gates pass; Flay score remains zero and Reek reports zero warnings.
- [x] Record the measured setup trade-off in [ADR 0155](../../../docs/adr/0155-isolate-parallel-mutation-contract-compilers.md).

## Answer

The harness now creates one Spinel `TMPDIR` per mapped contract under the precompile temp root and passes it to that compiler process. The 40-contract shared precompile passes with `JOBS=8` in about 30 seconds, while mutation execution still uses eight isolated workers. `make -B check JOBS=8` passes with 51 workers, all configured mutations caught, Flay score 0, and Reek 0 warnings. See ADR 0155.
