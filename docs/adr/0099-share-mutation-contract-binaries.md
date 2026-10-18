# ADR 0099: Share immutable mutation contract binaries across shards

## Status

Accepted.

## Context

Each of eight isolated mutation shards compiles the same mapped public contracts. Contract binaries do not depend on the mutated Fleek source, but compile cost is substantial. A measured duplication contract compile took 4.64s and 4.74s with pinned Spinel at `-O 1`. PIT's coverage-guided test selection illustrates the value of avoiding unrelated test work; Fleek already maps each mutation to its relevant complete public CLI contract and must retain that behavior.

## Decision

Compile each unique mapped contract once per mutation run and reuse its immutable executable from all shards. Keep each shard's Fleek build, source copy, working directory, reference cache, and harness logs isolated. Copy only mapped contracts and their shared helper. Verify at the mutation seam that each shard uses the exact shared executable, runs in its assigned copy, and produces contract output under its assigned temp root. Fail closed on missing binaries, failed compilation, or failed cleanup.

## Consequences

Mutation evidence retains every configured mutant and its full mapped public contract while removing repeated contract compilation. During precompile, only mapped test sources are copied; their `/tmp/` paths rewrite to runtime `FLEEK_TEMP_ROOT`, and `__dir__` resolves to the worker checkout. Each shard supplies and asserts its own temp root, so shared binaries can execute concurrently without fixed-path collisions or locks. Contract compilation runs in batches bounded by `JOBS`. Gate records elapsed time as evidence; ordinary contracts assert no timing threshold.

The first shared-binary attempt used `File#flock` to protect fixed paths. Pinned Spinel does not implement that method, and serializing contract execution increased full-gate time. Runtime path isolation preserves parallel execution and removes that platform-specific lock.

## Evidence

See `.scratch/fleek/issues/27-duplicate-mutation-contract-compilation.md` for exact reproduction, baseline, and before/after gate timing. PIT informed the use of mutation-to-relevant-contract mapping; Fleek keeps its deterministic Spinel harness rather than adding a Java dependency. References: [PIT FAQ](https://pitest.org/faq/) and [PIT basic concepts](https://pitest.org/quickstart/basic_concepts/).
