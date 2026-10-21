# ADR 0241: Keep deep InstanceVariableAssumption scopes incomplete

## Status

Accepted for Ticket 125.

## Context

Reek 6.6.0 reports uninitialized instance-variable assumptions in classes nested beyond one direct child and in classes under modules. Fleek's native detector supports one simple class or one class with one direct nested class, and attributes the finding to that class declaration.

## Decision

Keep deeper and module-wrapped class scopes unsupported. Report incomplete coverage when such a selected source contains nested classes, even when Reek's configured exclusions remove its findings or the class initializes the instance variable. Do not convert an unvisited class to a clean result.

## Consequences

Pinned Reek can report, suppress, or clear these findings based on class context and initialization. Fleek conservatively retains incomplete status until its native walker can track all class scopes and initialization boundaries. Existing direct and one-level nested behavior remains unchanged.

## Evidence

Ticket 125 records deep and wrapped findings, an initialized clean control, configured exclusions, incomplete Fleek coverage, and the caught `InstanceVariableAssumption deep and wrapped scope boundary` mutation. On pinned Spinel 2026.09.12 (tag object `00ce35bb96e489620358ffbc48791001a73778a5`, source `112bae85c1a25fc5399009a849f805bfe691426b`), `make check JOBS=8` passed with 78 workers, all mutations caught, Flay score 1008, and Reek 0 warnings. `gmake -C /private/tmp/fleek-spinel-pinned-rebuild check` passed 3,596 tests, allocation and inference checks, and `spin-e2e`. The tracker validator accepted 138 documents.
