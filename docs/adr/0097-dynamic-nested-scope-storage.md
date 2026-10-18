# ADR 0097: Size Flay candidate scope paths from parsed input

## Status

Accepted. Supersedes the depth and component ceilings in ADRs 0086, 0088–0093, and 0095.

## Context

Ticket 21 accumulated separate boundary fixes for nested module methods, classes under modules, nested class chains, and relative qualified module paths. Each fix added another numeric limit and another nearly identical fixture/mutation. The parser already exposes the complete scope chain; fixed candidate path storage, rather than Flay semantics, created those frontiers.

## Decision

Collect nested module chains iteratively and store each candidate's scope-name path in dynamically sized memory. Grow path buffers from the parsed depth, check allocation-size overflow and allocation failure, and release candidate paths after each scan. Keep independent semantic limits, such as the existing per-scope body and candidate counts, explicit and unchanged. Test public CLI parity against Flay with generated source at a high N (64) for nested modules and classes, and retain compact reference fixtures for distinct grouping shapes.

## Consequences

Supported module depth and qualified path length are no longer bounded by arbitrary candidate-array constants. Runtime remains bounded by available memory and parser capacity; allocation failure is reported as incomplete/unsupported analysis. Nested class traversal still follows the parsed class chain and has no configured depth ceiling.

## Evidence

The public duplication contract generated and compared 64-level module and class chains against Flay 2.14.4, and the qualified namespace contract now covers 21 components. Focused mutations that stop module traversal, class traversal, or scope-depth comparison are caught by the public CLI contract.
