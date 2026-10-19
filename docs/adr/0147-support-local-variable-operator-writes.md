# ADR 0147: Support local-variable operator writes in method candidates

## Status

Accepted

## Context

Pinned Flay 2.14.4 reports shared method candidates containing local-variable operator writes such as `total += 1`. Fleek previously rejected these methods. A three-call method pair has Flay mass 24; differing local names or `+=` versus `-=` produce similar groups at the same mass.

## Decision

Include Prism `LocalVariableOperatorWriteNode` in method candidate trees. Add two mass units per node to match Flay's RubyParser tree. Compare its local name and operator token bytes from Prism's token location when deciding identical versus similar groups.

## Consequences

Compiled CLI contracts compare identical writes, renamed-variable writes, and different operators against pinned Flay for kind, mass, score, locations, and coverage. Focused mutations protect candidate support, mass, and operator identity. `+=`/`-=` operator identity uses exact source token bytes; multiple assignment keeps its existing two-point adjustment.
