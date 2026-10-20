# ADR 0180: Focus the generated descriptor support mutation contract

## Status

Accepted

## Context

Ticket 106 ranked `Flay generated descriptor support` second among eligible independent labels after ticket 113. Its mapping ran the broad `duplication_generated_descriptor_contract.rb`, which checks the generated descriptor inventory beyond the range support behavior changed by this mutation.

## Decision

Map only `Flay generated descriptor support` to the existing `duplication_method_range_contract.rb`. Keep `duplication_generated_descriptor_contract.rb` enabled in ordinary checks and mapped to `Flay generated descriptor mass`. The range contract asserts the method-range behavior through the public CLI and exact Flay comparison. Update the shared range-mass mutation's expected failure to its range kind/mass/location assertion. Keep the precompile-budget contract's ten samples distinct by replacing its range-candidates entry with generated-descriptor mass.

## Evidence

The baseline range contract passed; the exact descriptor-support mutant failed at `range-expression methods were not analyzed`, and filtered precompile selected only the range contract. Direct execution measured the broad generated-descriptor contract at 10.28s and the focused range contract at 1.13s, avoiding about 9.15s (89%) of unrelated contract execution per mutation occurrence. Cache-disabled, miss, and warm focused mutation invocations reported 3.869s, 3.947s, and 3.404s of precompile time; full invocation wall time varied, so no total wall-time reduction is claimed. Final `make check JOBS=4` passed 61 workers and caught all 273 labels, with 49 cached binaries restored, zero compiled, and 3.689s precompile elapsed. `make flay reek`, `make ticket-check` (124 documents), and `git diff --check` passed. Pinned Spinel 2026.09.12; Flay 2.14.4; Reek 6.6.0.

## Consequences

This support mutation checks range behavior without rerunning the unrelated generated descriptor inventory. The broad inventory remains part of normal regression checks and still protects the generated descriptor mass mutation.
