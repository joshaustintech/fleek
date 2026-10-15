# ADR 0029: Support conditional returns in class methods

## Status

Accepted.

## Context

The pinned Rails `User#authenticated?` method uses `return false if digest.nil?`. The bounded class-method AST collector rejected Prism `ReturnNode` and `FalseNode`, even though the surrounding conditional grammar was supported. Ticket 19 requires matching Flay 2.14.4 on the same source and preserving explicit incomplete status for unsupported forms.

## Decision

Add Prism `ReturnNode` and `FalseNode` to the bounded class-method AST grammar. Keep both as distinct tree nodes so return control flow and false literals participate in structural equality and mass. Continue to fail closed when any child node falls outside the supported grammar.

## Consequences

A paired fixture containing conditional false returns and calls matches Flay's similar `:defn` group at mass/score 44 and lines 2/10. Separate mutations remove return-node and false-literal support and must break that contract. This broadens method bodies only; it does not establish full Rails corpus parity.
