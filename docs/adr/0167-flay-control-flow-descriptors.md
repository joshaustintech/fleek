# ADR 0167: Describe Flay control flow with focused contracts

## Status

Accepted

## Context

Ticket 22 adds control-flow parity to the bounded method-candidate tree. Prism represents supported branches, loops, transfers, and exception flow with native nodes, while Flay's RubyParser translator adds a synthetic array around each `when` condition list. The broad duplication contract already checked these forms, but mutations replayed unrelated collection and scalar cases.

## Decision

Keep native control-flow structure in the shared node descriptor table. Preserve the one verified synthetic wrapper as a structural marker and mass adjustment, as established in ADR 0111. Use separate public Flay parity contracts for branches/case, loops, and exception flow; route each control-flow mutant to the smallest applicable contract.

Contracts compare grouping, mass, score, locations, and complete coverage against Flay 2.14.4. Differing `when` condition-list lengths must remain a complete clean result. Unsupported syntax remains incomplete.

## Consequences

Control-flow mutations compile only the contracts assigned to their behavior instead of replaying the broad duplication suite. The public contracts cover `if`/`unless`/`else`, `case`/`when`, boolean expressions, loops, returns, yields, and supported rescue/retry/ensure forms. Focused mutants protect node acceptance and parent-dependent mass.
