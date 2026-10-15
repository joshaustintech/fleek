# ADR 0033: Measure bounded cold runtime against complete work

## Status

Accepted.

## Context

Ticket 19 remains open because Flay cannot fully analyze class-level Rails declarations. Timing Fleek's partial Rails Flay run against Flay's full result would compare different work. Reek ClassVariable already analyzes the pinned 25-file Rails corpus completely. Fleek's bounded class-method Flay fixture also has exact reference-backed finding parity.

## Decision

Record useful runtime evidence now with two complete workloads: compare Flay 2.14.4 with Fleek Flay on the same duplicated class-method fixture; compare Reek 6.6.0 with Fleek Reek on the exact 25-file Rails corpus; compare sequential Flay-plus-Reek reference commands with one Fleek combined invocation on the same duplicate fixture. Check output, stderr, status, coverage, finding identity, locations, and score before retaining every timing.

Define cold as a fresh process for each observation with natural OS filesystem cache state. Do not claim cache eviction. Run 20 samples per variant, alternate pair order, retain raw timings, and pin host, executable, compiler, reference, input, and harness identities. Set each Fleek p95 target to the corresponding complete reference workload's measured p95; report whether current results meet it.

Preserve Fleek's declared status contract: Flay 2.14.4 returns 0 when it reports the fixture finding, while Fleek returns 2 for findings. The finding, location, mass, score, coverage, and stderr are compared directly; the intentional exit difference is documented, consistent with ADRs 0002 and 0018.

## Consequences

The measured targets are met on macOS arm64: Flay fixture p95 3.897 ms against 178.776 ms; Reek ClassVariable on the 25-file Rails corpus p95 6.606 ms against 376.211 ms; combined fixture p95 4.323 ms against 693.700 ms. These are the latest receipt values; raw observations and reproduction steps are in [the runtime receipt](../research/cold-runtime-2026-10-15.md).

These measurements prove only the listed workloads. They do not establish full Rails Flay parity, runtime on other hosts, purged-cache behavior, or downloadable release performance. Ticket 19 remains the full-manifest Flay gate; ticket 17 remains the external release verification gate.
