# ADR 0023: Preserve findings from partially analyzed Flay sources

## Status

Accepted.

## Context and decision

Rails classes can contain supported methods alongside callbacks, parameterized methods, or other shapes Fleek cannot yet compare. Discarding every finding hides proven Flay results, while reporting the supported subset as complete implies unsupported candidates ran. Fleek now emits only verified supported groups, labels the source `partial`, warns that candidates may be omitted, reports zero fully analyzed sources and incomplete coverage, and exits 1 whenever any class member was skipped.

## Consequences

On the pinned `UsersController`, Fleek now reports the same Flay 2.14.4 group, mass 48, score 48, and ordered locations at lines 51 and 58, while exiting 1 with `Status: incomplete`. The 25-file corpus remains a separate release gate; partial findings do not establish parity.
