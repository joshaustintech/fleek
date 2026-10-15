# ADR 0022: Flay class-method candidate boundary

## Status

Accepted.

## Context

The pinned Rails corpus reports a similar Flay `:defn` group for methods nested directly in `UsersController`. Fleek's initial Flay adapter only collected methods at the program root, so every class declaration failed closed before useful Flay candidates could be analyzed.

## Decision

Extend the bounded Flay adapter to accept simple classes with at most 32 direct body entries each and at most 16 supported parameterless method candidates total; ADR 0024 records cross-class collection. Preserve Prism tree nesting in structural comparisons; preorder node types alone can conflate different call-argument trees. Compare literal and identifier values separately when classifying identical groups. Detect matching nested subtrees: if a subtree group reaches Flay's mass threshold but cannot be represented, fail incomplete. Class-level statements, parameterized methods, and unsupported method ASTs mark results partial while supported candidates remain reportable. Do not execute source or infer that omitted candidates were analyzed.

## Consequences

The bounded class-method seam matches unchanged Flay 2.14.4 on public CLI fixtures for a Rails-shaped similar group (mass and score 48), an identical group (score 64), cross-class candidate collection, and different call-tree topology that Flay leaves clean. A separate reference fixture proves a qualifying partial subtree is reported as incomplete instead of being silently skipped. The adapter preserves tree boundaries with paired node/end markers and ignores atom values for structural similarity; exact node values participate in identical-group classification. Prism keyword-hash container nodes do not contribute a Flay mass unit in this adapter, verified by the Rails-shaped score fixture. The candidate scan is capped at 16 supported methods total and 32 direct body entries per class to bound stack use. Unsupported class contents and AST forms remain incomplete; ADR 0023 defines how proven groups remain visible in those reports.

## Evidence

`test/duplication_contract.rb` compares the supported class-method cases against locked Flay 2.14.4. The mutation suite removes tree comparison and tightens the method-count boundary; both must fail the public CLI contract. The pinned 25-file Rails run remains an explicit release gate, not evidence supplied by these synthetic fixtures.
