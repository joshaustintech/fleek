# ADR 0112: Isolate duplication contract output files

## Status

Accepted as worker-isolation hardening.

## Context

Parallel mutation workers run the same compiled duplication contract. Fleek and Flay subprocess output previously used fixed `/tmp` paths, so worker-owned capture files were not explicit. A full mutation run still failed after this change, which showed that output-path isolation was useful hardening but not the complete `Errno::ENOENT` root cause. The failure was later traced to repeated deep-fixture cache misses combined with cache filenames derived from the full source path; see ADR 0094 and issue 31.

## Decision

Derive duplication contract subprocess output paths from `FLEEK_TEMP_ROOT`, which the check runner assigns uniquely per worker. Keep a mutation-harness assertion against the shared compiled contract source so the regression guard verifies both Fleek and Flay capture paths use the worker-root helper.

## Consequences

Each worker owns its subprocess output and error files. Direct contract runs retain `/tmp` as the fallback root. This prevents cross-worker capture-file interference and complements, but does not replace, the stable fixture paths and bounded collision-checked reference cache documented in ADR 0094.

## Alternatives considered

- Reduce mutation worker count: rejected because it avoids failures by lowering throughput instead of fixing resource ownership.
- Add retries around missing output: rejected because that would hide a harness defect.
