# ADR 0190: Describe Range and regexp identity

## Status

Accepted

## Context

Ticket 52 audited accepted method-body descriptors through candidate support, generic child traversal, structural equality, and mass. Generated contracts in ADR 0170 cover every accepted descriptor, while fixed contracts cover representation-specific behavior. The audit found that Range end exclusion and regexp value identity remain implemented as node-type conditionals outside the Prism-indexed descriptor. This leaves accepted node identity split across the descriptor inventory and equality dispatch, contrary to ADR 0160's completion boundary.

## Decision

Track Range and regexp descriptor completion as a bounded child ticket. Move the existing identity metadata and equality dispatch into the shared node descriptor path while preserving Flay 2.14.4 behavior. Keep the synthetic `when` condition array, parent-dependent mass, optional-default policy, and composed exception/source-file pruning as explicit adapters because they translate structural or contextual differences between Prism and RubyParser.

## Consequences

Ticket 119 proves descriptor parity with unchanged public behavior. Together with generated/composed contracts in tickets 42, 43, 52, and 118, it satisfies Ticket 22's remaining acceptance criteria. Its pinned cold full gate and both review axes passed after the final child changes; Ticket 22 is resolved. Existing public contracts remain the baseline for the implementation.
