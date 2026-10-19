# ADR 0171: Bound generated contract work in parallel checks

## Status

Accepted

## Context

The generated descriptor contract compares every supported case through both Fleek and Flay. The check runner already runs up to eight isolated test or mutation workers. Inheriting `JOBS=8` inside the generated contract could add sixteen analyzer processes while those outer workers were active. The mutation suite also ran the optional-keyword-count mutation against a broad parameter contract, whose positional-count case could fail first and report an unrelated expected-failure message. Mutation workers require a non-mutation artifact in their isolated temp root to verify that contracts use the root.

## Decision

When `FLEEK_TEMP_ROOT` marks an isolated check worker, cap the generated contract's nested analyzer concurrency at two. Direct runs continue to honor `JOBS` (default four). Each contract run writes a compact descriptor inventory and verified result report into the worker temp root; direct runs remove the report, and the runner removes worker roots after completion.

Give optional-keyword-count its own public contract and map its mutant there. Keep the mutation failure message specific to that contract.

## Evidence

On the same generated catalog and local Spinel/Flay binaries, direct execution took 5.09 s with `JOBS=8`, 8.71 s with `JOBS=2`, and 13.06 s with `JOBS=1`. With `FLEEK_TEMP_ROOT=/tmp` and `JOBS=8`, the isolated-worker path took 8.92 s. That environment selects the same cap used by outer check workers. The direct 8-worker run is fastest without outer work, while the cap bounds nested fan-out to four analyzer processes when the runner schedules other workers.

The focused support, mass, and optional-keyword-count mutants pass with three mutation workers. The complete `make check JOBS=8` passed 60 workers, including tests, all mutation shards, Flay, Reek, and reference checks. Reek reports zero warnings. Flay reports its existing score 64 for the duplicate `CheckRunner::TESTS` and `CheckProfiles::DEFAULT_CHECKS` array shapes; this change contributes no new Flay findings.

## Consequences

The isolated check runner has bounded nested work while direct invocation retains higher standalone throughput. The optional-keyword mutation now fails at its intended assertion. The evidence report is limited to each disposable worker root and does not accumulate in the repository or ordinary temp directory.
