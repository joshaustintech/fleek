# ADR 0239: Keep deep and wrapped ClassVariable namespaces incomplete

## Status

Accepted for Ticket 123.

## Context

Reek 6.6.0 reports class-variable findings in classes beneath three modules and in class declarations wrapped by `begin`. Fleek's native `ClassVariable` walker currently supports direct scopes plus one- and two-module namespace paths. It cannot attribute occurrences across arbitrary module depth or wrapper nodes with the same scope ownership guarantees.

## Decision

Keep deeper module chains and wrapped namespace declarations outside the supported `ClassVariable` shape. Return incomplete coverage for those selected sources instead of emitting a partial or misattributed finding set. Preserve the existing supported direct and two-module cases.

## Consequences

The pinned fixtures demonstrate the difference explicitly: Reek reports qualified contexts and lines for deep/wrapped declarations, while Fleek reports zero analyzed and one failed source. Extending this behavior requires general namespace traversal and occurrence ownership, followed by parity checks for nested and sibling declarations.

## Evidence

Pinned Reek 6.6.0 reports the expected qualified findings for three-module, wrapped, and mixed namespace fixtures. Fleek reports each as incomplete with zero analyzed and one failed source. Ticket 123 records the per-fixture findings and coverage.

Verification used pinned Spinel `2026.09.12` (`112bae85c1a2`): `make check JOBS=8` passed with 78 workers, eight mutation workers, all mutants caught, Flay score 1008, and Reek 0 warnings; the pinned Spinel `gmake check` passed 3,596 tests and allocation, inference, and spin-e2e gates; `make ticket-check` validated 138 documents; and `git diff --check` passed. Focused mutation `ClassVariable nested namespace boundary` was caught.
