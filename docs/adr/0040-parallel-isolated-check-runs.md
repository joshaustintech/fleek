# ADR 0040: Run checks concurrently in isolated workers

## Status

Accepted.

## Context

The test contracts write fixed absolute paths under `/tmp`. Mutation checks edit `bin/fleek.rb`, delete and rebuild `build/fleek`, then run CLI contracts. Parallel execution in the checkout can therefore overwrite test evidence or produce a binary from another worker's mutant.

## Decision

Run independent checks in a worker pool bounded by the host's logical CPU count. Allow `JOBS` to lower the limit. Keep Spinel verification and the initial Fleek build as shared prerequisites. Execute each test contract and mutation shard in a private copy of the project and rewrite its temporary paths into a worker-specific namespace. Partition mutation labels deterministically so every configured mutation belongs to one shard.

`make test`, `make mutation`, and `make check` use the same scheduling policy. `make check` uses one pool for the test contracts, mutation shards, fixture reference checks, Flay, and Reek.

## Consequences

Concurrent workers cannot overwrite the checkout's source, build output, or test logs. Temporary project copies add disk I/O; `JOBS` provides a lower concurrency cap. The runner reports failed workers and removes copies after completion.

Validation: pinned Spinel 2026.09.12 `make check` passed with eight workers, 14 contracts, all 93 mutations caught, Flay score 0, and Reek 0 warnings. A simultaneous `make test` and filtered `make mutation` run also passed.
