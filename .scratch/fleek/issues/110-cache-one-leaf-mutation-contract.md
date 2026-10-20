# 110: Reuse one unchanged leaf contract across mutation runs

**What to build:** Two focused mutation invocations can reuse one unchanged compiled native-parser contract from persistent local storage, while each still rebuilds and executes its mutant.

**Blocked by:** 109.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [ ] Limit opt-in caching to the existing native-parser public contract, which has no shared Ruby source dependencies. Use a local ignored cache and a conservative key covering the entire prepared contract-source bundle, compiler executable and runtime-header/library identities, compile options and relevant code-generation environment, platform and cache/rewrite format version. Cache no mutant executable or analyzer result.
- [ ] Copy verified cached executable bytes into each run's existing shared-contract directory; keep current temp-root rewriting and worker-relative runtime lookup intact. Misses compile through the existing path.
- [ ] Publish only successful complete builds by atomic replacement from unique temporary entries; store/verify executable digest. Missing, corrupt or incomplete entries rebuild safely. Concurrent same-key publishers must not expose partial binaries or delete another invocation's resources.
- [ ] Prove first miss then second hit via compile counts, unchanged public results and the same caught mutation. Source, compiler and flag changes miss; corrupt entry and failed compilation cannot produce a hit. Cached execution uses the new worker directory/temp root.
- [ ] Keep caching opt-in and leaf-only. Record cold/warm timings and the cache decision in an ADR; no general cache service or new dependency.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
