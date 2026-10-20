# 109: Stage only required workspace inputs for isolated workers

**What to build:** Every worker sees current dirty and untracked project inputs without repeatedly copying unrelated Git history, release archives or generated caches.

**Blocked by:** 108.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Measure copied bytes and staging time first. Extend the existing rsync exclusions only for proven non-input root artifacts: Git metadata, release archives and reusable contract-cache storage; retain required commit hooks, sources, fixtures, config, tracker documents and the baseline executable.
- [x] An isolated worker contract proves edited tracked and new untracked source/fixture inputs remain visible, required hidden hooks/config remain available, and excluded artifact sentinels do not arrive.
- [x] Keep source copies, compiler outputs and temporary files isolated; never hard-link mutable source or replace current workspace inputs with a clean Git snapshot.
- [x] Measure the same staging probe before/after. If an exclusion has a real consumer, retain that input and record why. Stop at this bounded staging filter.

## Answer

Pinned Spinel 2026.09.12; Flay 2.14.4; Reek 6.6.0. Before the change, `rsync -a --exclude=/build/mutation-* --stats ./ DEST` transferred 10,798,152 bytes across 1,180 files in 0.36s. After excluding root `.git` and `dist` while preserving the prior mutation filter, it transferred 5,559,480 bytes across 870 files in 0.26s. The contract cache was already excluded by the mutation glob; it is now explicit in the centralized policy. The same probe uses the live workspace as source, not a clean Git snapshot.

The RED staging contract failed when the `dist` exclusion was removed: `release archive sentinel reached worker`. GREEN verifies edited source, an untracked fixture, `.githooks/commit-msg`, `.gitignore`, project instructions, and `build/fleek` remain; `.git`, `dist`, and cache sentinels stay out; worker edits do not change the source. Full `make check JOBS=4` passed 59 workers in 395.17s; Flay score 0 and Reek warnings 0; `make ticket-check` validated 124 documents; `git diff --check` passed. ADR 0175 records why `.githooks` and `release/` remain.

## Execution boundary

One fresh Luna context; claim only this ticket and stop at its acceptance criteria. Use the pinned Spinel 2026.09.12 compiler and unchanged Flay 2.14.4 / Reek 6.6.0. Follow the performance-bugs workflow: reproduce before editing, rank causes, vary one factor, then compare outputs/statuses and phase costs. Every one-off helper must be pinned-Spinel Ruby; shell only invokes existing commands.

Code changes require a meaningful failing regression first, GREEN, relevant behavioral mutation evidence and the repository's complete pre-commit gates. Keep full mutation execution as the final correctness gate; no cached verdicts, disabled checks or relaxed reference expectations. Record exact commands, identities, timings, limitations and any exclusions in Answer. Evidence-only changes use tracker/link/diff checks and claim no implementation proof.

If an independent defect exceeds this slice, publish one bounded residual ticket and add it as a blocker to ticket 115 before stopping. New feature tickets must retain ticket 115 as a prerequisite until this harness handoff resolves. Existing parents and their claims remain unchanged.
