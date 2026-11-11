# 146: Migrate the remaining Reek detectors to the context engine

**What to build:** The remaining 28 detectors run on the ported context engine, one detector per commit, each matching pinned Reek on the Rails manifest and on differential fixtures with complete coverage.

**Part of:** Ticket 24.

**Blocked by:** 145

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Start with the largest census gaps: TooManyStatements (7 missing), NestedIterators (15 incomplete sources), the call and flow group (DuplicateMethodCall, FeatureEnvy, NilCheck, ControlParameter, ManualDispatch, RepeatedConditional, UnusedParameters, UtilityFunction), then data, size and naming detectors, and UnusedPrivateMethod last. Delete each bounded native implementation with its mutations when it migrates.

## Acceptance criteria

- [ ] The ticket 96 census shows every detector complete and identical to pinned Reek on the Rails manifest.
- [ ] Each migrated detector has differential fixtures and caught mutations.
- [ ] Full gate passes after every migration; record results in `## Answer`.
