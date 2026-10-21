# ADR 0238: Keep inherited and reflective private-call analysis incomplete

## Status

Accepted for Ticket 122.

## Context

Reek 6.6.0's opt-in `UnusedPrivateMethod` detector has behaviors beyond Fleek's bounded direct-call model. Inherited class scopes and reflective calls can change whether a private method is considered used. Reporting complete results without resolving those call paths could invent an unused-method finding or omit one.

## Decision

Keep inherited class scopes and reflective/dynamic call forms unsupported in Fleek's `UnusedPrivateMethod` analyzer. Return incomplete coverage for inherited classes and calls through `send`, `public_send`, `method`, and `to_proc`. Do not infer usage from a reflective reference. Preserve the existing native guards and test that their removal changes the public result.

## Consequences

For the pinned cases, Reek reports inherited and `send`/`public_send` findings, but treats method objects and `to_proc` calls as clean. Fleek reports those selected inputs as incomplete with zero analyzed and one failed source, so neither result is presented as a complete match. Supporting these forms requires a bounded cross-scope and reflective call model with additional pinned evidence.

## Evidence

Pinned Reek 6.6.0 runs with `test/fixtures/config_unused_private_enabled.yml` reported findings for inherited private methods and `send`/`public_send`, and no findings for `method(:hidden)` or `method(:hidden).to_proc.call`. The public Fleek CLI reports each case as incomplete with zero analyzed and one failed selected source. Ticket 122 records the fixture matrix and exact outcomes.

Verification used pinned Spinel `2026.09.12` (`112bae85c1a2`): `make check JOBS=8` passed with 78 workers, eight mutation workers, all mutants caught, Flay score 1008, and Reek 0 warnings; the pinned Spinel `gmake check` passed 3,596 tests and allocation, inference, and spin-e2e gates; `make ticket-check` validated 138 documents; and `git diff --check` passed. Focused mutations caught removal of dynamic-call, inherited-scope, and method-object guards.
