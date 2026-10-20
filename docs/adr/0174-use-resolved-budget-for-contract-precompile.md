# ADR 0174: Use the resolved worker budget for contract precompile

## Status

Accepted

## Context

The check runner resolves a positive CPU-bounded `@jobs` value, but its shared mutation-contract precompile child previously did not receive `JOBS`. The child therefore defaulted to serial compilation even when the outer runner had idle CPU capacity. Contract compilation already caps each batch at the selected contract count and gives each compiler a separate temporary directory.

## Decision

Pass the runner's resolved `@jobs` value to the precompile child. Keep the selected-contract batch cap, per-compiler temporary roots, Spinel `-O 1`, and mutation analyzer worker limits unchanged. Keep optional precompile budget and elapsed-time output behind `FLEEK_PRECOMPILE_BUDGET_REPORT=true` for reproducible cost probes; ordinary output stays unchanged.

## Evidence

The deterministic process-boundary contract gates fake compiler processes for resolved budgets 8, 1, 3, and 8, and checks observed configuration, fan-out, selected contract count and dependency, isolated temporary roots, and `-O 1`. It passes under pinned Spinel 2026.09.12. The actual runner path was also exercised with `JOBS` unset, 1, 3, and 100. Its reports showed resolved budgets 8, 1, 3, and 8; selected four-contract precompile batches were capped at four (the child reported the effective cap). Every focused mutation was caught.

For the same four selected contracts, RED with forwarding removed reported child `JOBS=1` and precompile time 6.48s. GREEN with `JOBS` unset reported child `JOBS=8` and 4.46s; explicit `JOBS=3` reported child `JOBS=3` and 5.50s. These phase measurements are diagnostic and are not timing assertions. Full correctness gates remain required before delivery.

## Consequences

Shared contracts can compile concurrently up to the resolved runner budget and selected-contract count. The existing CPU clamp, invalid-`JOBS` rejection, focused contract set, analyzer concurrency, and optimization level remain intact. Ticket 108's full `make check JOBS=4` passed 58 workers in 398.63 seconds; Flay score was 0, Reek warnings were 0, and all 124 ticket documents validated.
