# ADR 0145: Support multiple-assignment method candidates

## Status

Accepted.

## Context

Pinned Flay 2.14.4 includes destructuring assignments in method candidates. Prism represents assignments with `MultiWriteNode` and `MultiTargetNode`, and local targets with `LocalVariableTargetNode`. Rejecting these nodes loses otherwise supported candidates. Counting Prism nodes directly also undercounts Flay's candidate mass by two for each multiple-assignment expression.

## Decision

Include multiple-write and target nodes in method candidate trees. Compare local target names as part of candidate identity. Add two mass points per `MultiWriteNode` to account for the additional structure in Flay's RubyParser tree; child targets and values remain traversed normally so candidate mass scales with target count.

## Consequences

Compiled CLI contracts compare identical two-target methods (mass 22), similar methods whose only difference is target names (mass 20), and identical three-target methods (mass 26) against Flay. A two-versus-three-target pair matches Flay's clean result. Focused mutations protect candidate acceptance, target identity, and mass.
