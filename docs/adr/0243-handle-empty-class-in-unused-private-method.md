# ADR 0243: Handle empty classes in UnusedPrivateMethod

## Status

Accepted for Ticket 127.

## Context

An empty Ruby class has a null Prism `body` pointer. The `UnusedPrivateMethod` native collector passed that pointer to `PM_NODE_TYPE_P`, which dereferenced it and crashed. The same crash occurred with either `ActiveJob::Base` or `Object` as the superclass. Adding one public method made the class body a statements node and avoided the crash.

## Decision

Treat a null class body as an empty, supported body and return no unused-private-method findings. Check for null before calling `PM_NODE_TYPE_P`. Continue to reject unsupported non-null body nodes as incomplete.

## Consequences

The minimal empty framework subclass returns the same clean result as pinned Reek, with complete coverage for its one selected source. Other unsupported method, scope, or call-graph shapes retain their existing incomplete behavior.

## Evidence

Ticket 127 records the public crash regression and caught `UnusedPrivateMethod empty framework subclass handling` mutation. On pinned Spinel 2026.09.12 (tag object `00ce35bb96e489620358ffbc48791001a73778a5`, source `112bae85c1a25fc5399009a849f805bfe691426b`), `make check JOBS=8` passed with 78 workers, 8 mutation workers, all mutations caught, Flay score 1008, and Reek 0 warnings. `gmake -C /private/tmp/fleek-spinel-pinned-rebuild check` passed 3,596 tests, allocation and inference checks, and `spin-e2e`. The tracker validator accepted 138 documents.
