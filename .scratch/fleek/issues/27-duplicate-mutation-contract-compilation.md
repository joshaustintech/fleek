# 27: Avoid recompiling immutable mutation contracts per shard

**What to fix:** Mutation shards compile the same public contract binaries independently, repeating deterministic compiler work without changing the tested source or harness.

**Status:** resolved
**Type:** bug
**Category:** bug
**Triage:** ready-for-agent

- [x] Compile each mutation-mapped public contract once per mutation run and reuse the immutable executable across isolated shards.
- [x] Preserve shard-local Fleek mutants, fixture working directories, reference caches, and complete mapped public contract execution for every mutant.
- [x] Fail closed if a shared contract binary is missing or fails to compile; do not silently fall back to reduced coverage.
- [x] Add a deterministic harness contract proving shards use the same compiled contract path while executing against their own working directories and temp roots.
- [x] Compare complete mutation and public gate verdicts against the current baseline; record before/after timings without wall-clock assertions.

## Diagnosis

Pinned Spinel `2026.09.12`, source `112bae85c1a25fc5399009a849f805bfe691426b`; command `make check JOBS=8`; baseline complete mutation gate 300.10s (ADR 0094); one `test/duplication_contract.rb -O 1` compile 4.64s and 4.74s. Three ranked causes: (1) repeated unchanged contract compilation; prediction: compile unique mapped contracts once and total compiler invocations fall while every mutation remains caught; (2) Flay reference subprocesses; prediction: disabling shard-local cache materially increases gate time (already measured 418.44s vs 300.10s before cache); (3) per-mutant Spinel native rebuild and mapped contract run; prediction: timing one isolated mutant separates their share, but removing the rebuild or reducing its assertions risks mutation coverage.

The repeated compile cause is fixed by compiling 13 unique mapped contract binaries once in bounded parallel batches. Precompile copies only mapped contracts and their shared helper; mapped contract sources rewrite `/tmp/` paths to consult runtime `FLEEK_TEMP_ROOT` and resolve `__dir__` from the worker checkout. Each shard keeps its own mutant source, binary, reference cache, working directory, and temp root; full mapped contracts still run for every mutant. The harness verifies the exact shared executable path, assigned working directory, and contract output under the shard's expected temp root. An initial file-lock approach was rejected: pinned Spinel lacks `File#flock`, and serialized runs cost more. Runtime temp-root isolation removes that collision while preserving shard parallelism.

## Answer

Confirmed. Pinned Spinel `2026.09.12`, `112bae85c1a25fc5399009a849f805bfe691426b`. Prior mutation-only baseline: 183 mutants, 300.10s. The initial shared-binary/serialized attempt measured 428.76s for full `make check`; mutation-only was 335.22s. Current command `make -B check JOBS=8` passes in 238.78s: pinned native rebuild, 18 public contracts, all 183 mutations, Flay score 0, Reek warnings 0. Thirteen unique contracts compile in bounded batches of eight; shared binaries pass the same executable-directory assertion and run against shard-specific checkouts/temp roots. Runtime temp-path probe and focused default-invocation mutation pass. No wall-clock threshold was added.

## Resolution

ADR 0099 records the chosen design and rejected lock attempt. Full gate improved from 428.76s to 238.78s (44.3%) while preserving all 183 mutations and 18 public contracts. The 300.10s mutation-only result is prior context, not a directly comparable full-gate measurement.
