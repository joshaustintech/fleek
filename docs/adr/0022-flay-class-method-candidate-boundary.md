# ADR 0022: Flay class-method candidate boundary

## Status

Accepted.

## Context

The pinned Rails corpus reports a similar Flay `:defn` group for methods nested directly in `UsersController`. Fleek's initial Flay adapter only collected methods at the program root, so every class declaration failed closed before useful Flay candidates could be analyzed.

## Decision

Extend the bounded Flay adapter to accept exactly one simple class containing 2–16 direct parameterless methods. Preserve Prism tree nesting in structural comparisons; preorder node types alone can conflate different call-argument trees. Compare literal and identifier values separately when classifying identical groups. Detect matching nested subtrees: if a subtree group reaches Flay's mass threshold but cannot be represented, fail incomplete. Continue rejecting class-level statements, class nesting, parameters, and unsupported AST forms. Do not execute source or infer that omitted candidates were analyzed.

## Consequences

The bounded class-method seam matches unchanged Flay 2.14.4 on public CLI fixtures for a Rails-shaped similar group (mass and score 48), an identical group (score 64), and different call-tree topology that Flay leaves clean. A separate reference fixture proves a qualifying partial subtree is reported as incomplete instead of being silently skipped. The adapter preserves tree boundaries with paired node/end markers and ignores atom values for structural similarity; exact node values participate in identical-group classification. Prism keyword-hash container nodes do not contribute a Flay mass unit in this adapter, verified by the Rails-shaped score fixture. The class scan is capped at 16 direct methods to bound stack use. This remains an implementation slice: the real 25-file Rails manifest is still incomplete, so release parity is unproven. Unsupported class contents and AST forms continue to report incomplete.

## Evidence

`test/duplication_contract.rb` compares the supported class-method cases against locked Flay 2.14.4. The mutation suite removes tree comparison and tightens the method-count boundary; both must fail the public CLI contract. The pinned 25-file Rails run remains an explicit release gate, not evidence supplied by these synthetic fixtures.
