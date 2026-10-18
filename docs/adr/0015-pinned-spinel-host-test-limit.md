# ADR 0015: Pinned Spinel host test limitation

## Status

Accepted for this host; re-evaluate when a network-capable test host is available.

## Context

Repository delivery instructions require a full build and test run using pinned Spinel 2026.09.12 before each commit. The pinned compiler's upstream `make check` exercises loopback sockets, socket options, HTTP clients, and garbage-collection behavior. The current managed execution host rejects loopback bind/connect operations with `EPERM` and `ECONNREFUSED`, including when the check is retried through the host-level execution path. The complete run reports 3,574 passed, 22 failed, and 0 errors. The failures are upstream environment-sensitive cases; one GC-root case also failed inconsistently across repeated runs.

## Decision

Do not change Fleek behavior, modify the pinned Spinel checkout, or hide upstream failures. Run and record the full check, then use its explicit failure output as a host limitation while separately requiring Fleek's pinned build, project contracts, mutations, Flay, Reek, and code review to pass. Repeat the full Spinel check on a host that permits loopback socket operations before claiming that full upstream gate passes.

## Consequences

This host cannot provide a passing full Spinel `make check` result, so upstream socket behavior and the intermittent GC-root case remain unverified here. Fleek's own checks remain independently actionable and must pass. A failed or incomplete upstream result must never be recorded as a pass.

## Evidence

On 2026-10-14, the required pinned Spinel check completed with 3,574 pass, 22 fail, and 0 error. The socket-dependent output included `EPERM` and `ECONNREFUSED`; repeated runs also disagreed on a GC-root fixture. The standard Fleek project build and contracts, full mutation set, Flay, and Reek passed separately.

Rerun on 2026-10-18 completed with 3,575 pass, 21 fail, and 0 error. The remaining failures are loopback socket/network cases with `EPERM` or `ECONNREFUSED`; the suite output contains `Abort trap: 6` for the socket backtrace fixture, followed by its expected `backtrace-test: pass`. This matches the documented managed-host restriction; no Spinel source was changed.
