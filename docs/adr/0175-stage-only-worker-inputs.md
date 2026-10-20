# ADR 0175: Stage only inputs required by isolated workers

## Status

Accepted

## Context

Each check worker receives a disposable copy of the current workspace. The runner must preserve dirty and untracked project inputs, the compiled baseline executable, hidden hooks and configuration, and independent mutable files. Root Git metadata and release archives do not feed the check tasks. The reusable mutation-reference cache is generated state, not a worker input; the existing `build/mutation-*` filter already removed it.

## Decision

Keep `rsync -a` staging the current working tree and centralize its exclusion policy in `WorkspaceStager`. Exclude root `.git`, root `dist`, `build/mutation-*`, and explicitly `build/mutation-reference-cache`. Retain `.githooks`, `.gitignore`, project instructions, source and fixture files, release source documents, and `build/fleek`. Do not hard-link or substitute a clean Git snapshot. Keep each worker's source and temporary roots separate.

## Evidence

The same source-to-destination `rsync -a --stats` probe before the policy change transferred 10,798,152 bytes across 1,180 files in 0.36s. With the new exclusions it transferred 5,559,480 bytes across 870 files in 0.26s: 5,238,672 fewer bytes (48.5%) and 0.10s less wall time. The after-probe included the ticket's new files, so the comparison is conservative.

The process-boundary staging contract builds a disposable source tree with an edited tracked source, a new untracked fixture, `.githooks/commit-msg`, `.gitignore`, project instructions, and `build/fleek`; all remain in the worker. `.git`, `dist`, and the reusable mutation cache sentinels are absent. Editing the worker copy leaves the source file unchanged. Removing the `dist` filter made the contract fail on its archive sentinel; the restored filter passes.

## Consequences

Worker input remains the live working tree, including untracked work, while each staged copy omits proven repository metadata and generated release/cache artifacts. `.githooks` remains because the commit identity contract invokes its hook. Release inputs under `release/` remain available for packaging workflows. Ticket 109's full `make check JOBS=4` passed 59 workers in 395.17 seconds; Flay score was 0, Reek warnings were 0, and all 124 ticket documents validated.
