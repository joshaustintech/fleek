# 35: Avoid copying stale mutation outputs into every worker

**What to fix:** Check workers copy the full workspace, including ignored mutation binaries left by focused mutation runs. Those artifacts are not inputs to a worker and multiply workspace-copy cost.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Diagnosis

- Pinned Spinel: `2026.09.12`, source `112bae85c1a25fc5399009a849f805bfe691426b`.
- The workspace `build/` directory measured 108 MB; most contents were `build/mutation-*` executables and the mutation reference cache. The normal `build/fleek` executable measured 1.3 MB.
- `bin/check_runner.rb` copied the entire workspace once per worker with `cp -R .`. A copy measured 0.799 s and carried the 108 MB mutation artifacts.
- Copying the same workspace with `rsync -a --exclude=/build/mutation-*` measured 0.393 s; copied `build/` measured 3.4 MB. This removes about 21 seconds of serial copy work across the 52 workers in a full check, before accounting for overlap with running tasks.
- Separate phase measurements: 41 contract workers passed in 1:57; mutation precompile built 41 shared contracts in 35.58 s; all 285 mutants passed in 4:51.68 with eight workers. Eight same-contract mutants took 37.1 s with eight workers and 40.6 s with one, so retain parallel mutation execution.
- The prior 8:09 full-gate time overlapped a focused contract process and is not a clean baseline.

## Acceptance criteria

- [x] Worker copies exclude generated `build/mutation-*` outputs while preserving source files and `build/fleek`.
- [x] A deterministic runner invariant fails if a stale mutation artifact reaches a worker copy.
- [x] Full native checks and all configured mutations pass with eight isolated workers; Flay and Reek remain clean.
- [x] Record before/after copy and full-gate timings without wall-clock assertions.
- [x] Record the staging policy and measured trade-off in ADR 0157.

## Answer

CheckRunner now stages each full working-tree copy with `rsync -a`, excluding only root-level `build/mutation-*` outputs, then checks that none reached the worker. This preserves dirty and untracked source inputs and the compiled `build/fleek` executable. The red check failed against the old `cp -R` copy and passed after the filter.

On the pinned Spinel 2026.09.12 host, the source build directory measured 108 MB. One full copy took 0.799 s; the filtered copy measured 3.4 MB and took 0.393 s. The full gate passed in 6:33.24 with 52 workers, 285 caught mutants, Flay score 0, and Reek 0 warnings. An earlier 8:09 run overlapped another contract process, so it is not a clean timing baseline.

ADR 0157 records the staging policy. See the map and ADR 0157.
