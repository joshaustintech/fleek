# ADR 0141: Support interpolated regular-expression literals in method candidates

## Status

Accepted; extends ADR 0140.

## Context

Pinned Flay 2.14.4 includes methods containing interpolated regular-expression literals in duplication candidates. These candidates include interpolated parts and option flags in structural identity, and have distinct mass from Fleek's unadjusted Prism node count.

## Decision

Accept Prism `PM_INTERPOLATED_REGULAR_EXPRESSION_NODE` in recursive method candidates. Preserve its parts in the candidate tree, compare option flags for identity, and apply the measured one-point mass adjustment for each such node. Validate identical patterns, changed pattern content, changed options, mass, and source locations against the compiled CLI and pinned Flay. Protect candidate support, mass, part-content identity, and option identity with separate deterministic mutations.

## Consequences

Static and interpolated regular-expression method candidates match Flay's grouping and mass behavior for covered forms. Unsupported child syntax still marks the candidate incomplete.

## Harness consequence

Keep regex parity comparisons in a dedicated public contract and map regex mutations only to that contract. Combining the six Flay comparisons with the broad parameter contract multiplied them across every parameter and expression mutant. The focused mutation map preserves deterministic coverage while avoiding unrelated reference-process work. ADR 0142 records the measured harness fix.
