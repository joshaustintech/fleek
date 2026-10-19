# ADR 0157: Exclude generated mutation outputs from worker copies

## Status

Accepted

## Context

The check runner copies the working tree for each isolated worker. Focused mutation runs leave disposable build/mutation-* binaries and reference caches in the ignored build directory. Those generated outputs are unrelated to source inputs but were copied into every later worker.

With pinned Spinel 2026.09.12, the current workspace build directory measured 108 MB. One full copy measured 0.799 seconds. Excluding mutation outputs reduced the copied build directory to 3.4 MB and the copy to 0.393 seconds. A focused mutation run confirmed the worker still receives the compiled application and all mapped contracts.

## Decision

Use rsync -a to preserve the complete working tree, including uncommitted files, while excluding only root-level build/mutation-* artifacts. Fail the runner if any such generated artifacts appear in a worker copy.

## Consequences

Worker isolation and uncommitted source visibility remain intact, while disposable mutants and caches are not multiplied across workers. The measured copy cost dropped by about half on this workspace. This does not change mutation compilation or contract selection costs.
