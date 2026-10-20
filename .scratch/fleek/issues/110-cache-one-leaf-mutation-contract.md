# 110: Reuse one unchanged leaf contract across mutation runs

**What to build:** Two focused mutation invocations can reuse one unchanged compiled native-parser contract from persistent local storage, while each still rebuilds and executes its mutant.

**Blocked by:** 109.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Limit opt-in caching to the existing native-parser public contract, which has no shared Ruby source dependencies. Use a local ignored cache and a conservative key covering the entire prepared contract-source bundle, compiler executable and runtime-header/library identities, compile options and relevant code-generation environment, platform and cache/rewrite format version. Cache no mutant executable or analyzer result.
- [x] Copy verified cached executable bytes into each run's existing shared-contract directory; keep current temp-root rewriting and worker-relative runtime lookup intact. Misses compile through the existing path.
- [x] Publish only successful complete builds by atomic replacement from unique temporary entries; store/verify executable digest. Missing, corrupt or incomplete entries rebuild safely. Concurrent same-key publishers must not expose partial binaries or delete another invocation's resources.
- [x] Prove first miss then second hit via compile counts, unchanged public results and the same caught mutation. Source, compiler and flag changes miss; corrupt entry and failed compilation cannot produce a hit. Cached execution uses the new worker directory/temp root.
- [x] Keep caching opt-in and leaf-only. Record cold/warm timings and the cache decision in an ADR; no general cache service or new dependency.

## Answer

Pinned Spinel 2026.09.12 (`112bae85c1a25fc5399009a849f805bfe691426b`), Flay 2.14.4, Reek 6.6.0. Caching is opt-in with `FLEEK_CACHE_NATIVE_PARSER_CONTRACT=true` and limited to the exact leaf `test/native_parser_contract.rb` with no dependencies. The ignored cache under `build/mutation-contract-cache/native-parser` contains only the public contract executable, never mutants or analyzer results.

Two uncached focused runs took 11.36s and 11.18s total, with 3.366s and 3.367s precompile. An enabled cold miss took 12.11s total (3.92s precompile); the immediate warm hit took 11.40s (3.29s precompile). Both runs caught `embedded NUL acceptance`. The warm hit avoided one compiler process and saved 0.63s in precompile; end-to-end gains are small on this host, so the feature remains opt-in.

`test/mutation_contract_cache_contract.rb` verifies miss/hit compile counts, source/compiler/runtime-header/runtime-library/flag invalidation, corrupt-entry rebuild, failed-build nonpublication followed by a miss, and two concurrent publishers yielding a complete digest-verified executable. The cached public contract passed the worker temp-root assertion, proving it ran in the new isolated worker. Full `make check JOBS=4` passed 60 workers in 398.90s with cache opt-in disabled; Flay score 0, Reek warnings 0, `make ticket-check` validated 124 documents, and `git diff --check` passed. ADR 0176 records the cache format and tradeoff.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
