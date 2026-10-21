# ADR 0240: Keep deep and wrapped Attribute scopes incomplete

## Status

Accepted for Ticket 124.

## Context

Reek 6.6.0 reports writable attributes in classes nested beyond one direct child and in classes under module and wrapper scopes. Fleek's native `Attribute` scanner tracks one simple class or module, or one class with a direct nested class. It does not retain visibility and qualified ownership across deeper or wrapped scopes.

## Decision

Keep deeper nested classes and classes under namespace or wrapper scopes unsupported. Return incomplete coverage for a selected source containing writable attribute declarations in those shapes. Preserve the bounded direct and one-level nested cases.

## Consequences

The reference can find public writers and exclude private writers and read-only readers in these files. Fleek reports incomplete coverage instead of implying that its partial scope scan is exhaustive. Generalizing this behavior requires per-class visibility and scope ownership through arbitrary wrappers and nesting.

## Evidence

Pinned Reek 6.6.0 reports the public writers and excludes the private writer and read-only reader in both fixtures. Fleek reports both files as incomplete with zero analyzed and one failed source. Ticket 124 records the exact findings and visibility controls.

Verification used pinned Spinel `2026.09.12` (`112bae85c1a2`): `make check JOBS=8` passed with 78 workers, eight mutation workers, all mutants caught, Flay score 1008, and Reek 0 warnings; the pinned Spinel `gmake check` passed 3,596 tests and allocation, inference, and spin-e2e gates; `make ticket-check` validated 138 documents; and `git diff --check` passed. Focused mutation `Attribute deep and wrapped scope boundary` was caught.
