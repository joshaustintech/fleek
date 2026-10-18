# ADR 0113: Grow method candidate storage with the scanned AST

## Status

Accepted

## Context

Ticket 22 method candidates stored AST nodes and structural markers in fixed arrays sized for 128 nodes and 256 markers. A 300-expression method was accepted by Flay 2.14.4 but Fleek marked it incomplete. Statement traversal also had a 128-entry ceiling. These caps were unrelated to scan needs and contradicted arbitrary-depth candidate traversal.

## Decision

Store each method candidate's AST-node metadata and structural tree in separately allocated arrays. Grow each array geometrically from a small initial capacity, check multiplication and capacity growth for overflow, and release all candidate allocations on successful analysis and every rejection path. Reserve a closing tree marker after visiting children: child traversal can consume capacity originally reserved by its parent. A full duplication contract exposed this error through a Prism destruction assertion on nested candidates. Traverse statement lists without a candidate-count cutoff. Keep the existing 24-method-per-file collection limit separate; it is a different scan dimension.

Use a generated public CLI contract whose requested expression count is an input parameter. The contract exercises 300 repeated call expressions, compares group locations and completeness, and checks candidate mass against pinned Flay 2.14.4. Focused mutations prevent node growth, tree growth, and nested closing-marker reservation.

## Consequences

Large candidates use memory proportional to their AST shape instead of reserving maximum-sized arrays for every candidate. Allocation failure remains fail-closed as incomplete analysis. The specific 300-expression fixture checks behavior beyond the former limit; geometric growth is the general mechanism for any representable required capacity.
