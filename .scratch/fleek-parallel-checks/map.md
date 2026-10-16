# Parallel and isolated check runs

## Notes

- Goal: `.scratch/fleek-parallel-checks/spec.md`.
- Decision recorded in [ADR 0040](../../docs/adr/0040-parallel-isolated-check-runs.md).

## Decisions-so-far

- Concurrent workers use private project copies and temporary-output namespaces.
- Mutation labels are partitioned across workers; each mutant must be caught once.
- Worker count defaults to logical CPU count and accepts a lower `JOBS` cap.
- Ticket 01 is implemented and pushed in `dacf834`; see its Answer for validation limits.

## Fog

- Full check and concurrent test/mutation evidence are recorded in issue 01.
