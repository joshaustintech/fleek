# 123: Match deeper and wrapped ClassVariable namespace contexts

**What to build:** Close `ClassVariable` parity gaps for classes nested under three or more modules or wrapped within a namespace, using pinned Reek 6.6.0 results to bound each supported case.

**Part of:** Ticket 24 — shared-syntax analyzer parity.

**Blocked by:** 62 (resolved); 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [x] Compare existing three-level and wrapped namespace fixtures against pinned Reek; record findings, qualified context, lines, coverage, and status for each shape.
- [x] Implement only reproducible mismatches through the native analyzer, or retain explicit incomplete coverage where reference behavior cannot be represented safely.
- [x] Add focused public CLI contracts and non-equivalent mutation evidence for changed behavior; preserve context exclusions and namespace occurrence ownership.
- [x] Record commands, pinned identities, ADR decision, and remaining child links in `## Answer`.

## Answer

Pinned Reek 6.6.0 reports `ApplicationCable::Internal::Nested::Connection` at line 5 for the three-module fixture; `ApplicationCable::Internal::Connection` at line 5 for a wrapped class under two modules; both `ApplicationCable` line 2 and `ApplicationCable::Connection` line 5 when a namespace and child both declare class variables; and `ApplicationCable::Connection` line 4 for a wrapped namespace child. Fleek reports each selected file as `1 selected; 0 analyzed; 1 failed; 0 excluded` with status incomplete.

No production behavior change was appropriate: the existing native walker supports bounded one- and two-module paths, while deep and wrapped scopes need broader occurrence ownership to preserve exact attribution. ADR 0239 records this boundary. `test/class_variable_contract.rb` now compares Reek findings and contexts for all four shapes and verifies Fleek's incomplete coverage; the focused `ClassVariable nested namespace boundary` mutation was caught. A trial mutation widening the two-module count alone survived because another independent fail-safe still rejects the deep tree; it was removed as equivalent coverage rather than counted as a non-equivalent mutant.

Verification used pinned Spinel `2026.09.12` (`112bae85c1a2`) and Reek 6.6.0. `test/class_variable_contract.rb` passed; `ClassVariable nested namespace boundary` mutation was caught. `make check JOBS=8` passed with 78 workers, eight mutation workers, all mutants caught, Flay 1008, and Reek 0 warnings. Pinned Spinel `gmake check` passed 3,596 tests plus allocation, inference, and spin-e2e. `make ticket-check` validated 138 documents and `git diff --check` passed. Ticket 123 closes only its deep/wrapped namespace cases; parent ticket 24 remains open for its other residual children.
