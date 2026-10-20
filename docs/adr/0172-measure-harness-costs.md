# ADR 0172: Measure harness costs before optimization

## Status

Accepted

## Context

Harness work needs a reproducible baseline before changing scheduling, precompile parallelism, worker staging, or contract reuse. The earlier temporary Spinel tree was incomplete: its binary identified the pinned release, but its runtime headers were absent. A fresh checkout of the pinned tag was built before collecting measurements.

## Decision

Use the full `make check` as correctness baseline and focused `FLEEK_MUTATIONS` runs as bounded cost probes. Measure worker staging, contract precompile, mutant compilation, and contract execution separately. Keep these measurements diagnostic; do not add wall-clock assertions to ordinary contracts or claim savings before a post-change comparison.

## Evidence

On macOS arm64, with 8 logical CPUs, Spinel `112bae85c1a25fc5399009a849f805bfe691426b` from tag object `00ce35bb96e489620358ffbc48791001a73778a5`, Flay 2.14.4, Reek 6.6.0, `JOBS=4`, and input revision `bebf4e8a98e1d854e9de5d97c24dbe258bb6ccd7`, full `make check` passed 56 workers in 452.93 seconds. Existing analyzer output was Flay score 64 (one group) and Reek 0 warnings; pinned reference checks passed.

Three isolated rsync staging probes each copied 10,619,348 bytes across 1,129 files in 0.32, 0.32, and 0.33 seconds. This excludes `/build/mutation-*`, matching the runner. Staging is measurable but small beside total check time.

With `JOBS=1`, three focused `make mutation` runs for `Flay group ordering` took 40.97, 40.79, and 41.14 seconds (median 40.97); all caught the intended mutation. Three runs for `Flay generated descriptor support` took 18.44, 12.01, and 11.97 seconds (median 12.01); all caught the intended mutation. Each invocation compiled one shared contract binary. The first run is colder; report it separately instead of hiding it in the median.

For `Flay group ordering`, the pinned precompile entry point compiled its one selected shared contract in 9.46 seconds. A direct `-O 0` Spinel compile took 2.07 seconds, and the precompiled duplication contract against the unchanged executable took 1.10 seconds. These are separate phase probes, not an additive decomposition of the 40.97-second runner measurement; runner setup and contract subprocess work remain in the end-to-end total.

## Consequences

Ranked follow-up hypotheses:

1. Waiting for the oldest worker can leave a free slot unused. `CheckRunner#wait_for_capacity` and `#drain_workers` explicitly wait on the first worker; ticket 107 must prove out-of-order slot reuse with a gated child.
2. Shared contract precompile defaults to one compiler because its subprocess does not inherit `JOBS`; the selected contract took 9.46 seconds. Ticket 108 should compare identical multi-contract precompile sets under resolved budgets.
3. Mutation invocations compile unchanged contracts again. Repeated focused invocations each reported one newly compiled shared binary, while preserving mutant rebuild and execution. Tickets 110–112 test safe immutable reuse and invalidation.

Worker-copy filtering remains worth measuring under ticket 109, but the observed 0.32-second copy of 10.6 MB does not rank above the three hypotheses. No speedup is claimed until ticket 115 repeats the baseline after the harness slices.
