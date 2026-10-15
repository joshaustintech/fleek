# ADR 0021: Single-level Ruby namespace analysis

## Status

Accepted.

## Context

The pinned Rails 8 corpus wraps Action Cable classes in a module, such as `ApplicationCable::Connection`. Reek 6.6.0 reports ClassVariable contexts with that qualified name. Rejecting the entire file marked a real supported check incomplete even though its direct class-variable traversal was already correct. Silently analyzing only the leaf could miss class variables declared in the outer namespace.

## Decision

For `reek:ClassVariable`, support exactly one simple module namespace containing one direct simple class or module scope. Accept an optional superclass on a class. Report the leaf context as `Namespace::Leaf`, retaining occurrence grouping and source locations. Apply existing suppression and configuration matching to that qualified leaf context.

Keep fail-closed behavior for wrapped, deeper, sibling, reopened, qualified-constant, or otherwise ambiguous scope structures. Direct AST body membership is required; source-range containment alone is insufficient. If the outer namespace itself has class-variable occurrences, report the file incomplete rather than skipping a second Reek context. Continue to accept standalone simple classes and modules.

## Consequences

The Rails Tutorial app's 25 Ruby files now complete the selected `reek:ClassVariable` check with the same clean result as unchanged Reek 6.6.0. Flay still cannot analyze the app's ordinary class methods; ticket 19 remains a release gate. The exact corpus snapshot and initial failure are in [ADR 0020](0020-rails-parity-corpus-and-release-gate.md).

## Evidence

The CLI contract compares namespaced classes and modules, qualified context, grouping/locations, suppression, and a configured context exclusion against unchanged Reek. Additional fixtures prove deeper namespaces and outer-namespace class-variable occurrences return incomplete. Mutation checks cover namespace traversal, qualified names, nesting boundaries, and omitted outer-scope occurrences.
