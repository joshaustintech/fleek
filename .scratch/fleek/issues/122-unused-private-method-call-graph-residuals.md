# 122: Complete UnusedPrivateMethod inherited and dynamic-call parity

**What to build:** Match pinned Reek 6.6.0 `UnusedPrivateMethod` behavior for inherited methods and reflective or dynamic call forms, with explicit evidence for each bounded case.

**Part of:** Ticket 24 — shared-syntax analyzer parity.

**Blocked by:** 61 (resolved); 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [x] Record pinned Reek and Fleek results for inherited private methods and reflective/dynamic references (`send`, `public_send`, method objects, and `to_proc` where accepted); add only cases with a reproducible parity mismatch.
- [x] Implement supported mismatches through the existing native analysis path, or document unsupported syntax as incomplete coverage when faithful support is out of scope.
- [x] Add focused public CLI contracts and non-equivalent mutation evidence for every behavior changed; preserve selected-check coverage and outcome semantics.
- [x] Record exact commands, pinned identities, remaining limits, and an ADR decision in `## Answer`.

## Answer

Pinned Reek 6.6.0 with `test/fixtures/config_unused_private_enabled.yml` reports unused private methods in inherited class scopes and for `send` and `public_send`. It returns clean for `method(:hidden)` and `method(:hidden).to_proc.call`. Fleek reports all five selected inputs as incomplete with `1 selected; 0 analyzed; 1 failed; 0 excluded`, preserving its bounded call-graph guarantee. No production behavior change was needed: the existing native scope and reflective-call guards already enforce this safe boundary. The decision is recorded in [ADR 0238](../../../docs/adr/0238-keep-call-graph-residuals-incomplete.md).

The public `test/default_argument_api_contract.rb` compares all cases with pinned Reek and checks Fleek's explicit incomplete status. Focused mutations caught removing the dynamic-call, inherited-scope, and method-object guards.

Verification used pinned Spinel `2026.09.12` (`112bae85c1a2`): `make check JOBS=8` passed with 78 workers, eight mutation workers, all mutants caught, Flay score 1008, and Reek 0 warnings; pinned Spinel `gmake -C /private/tmp/fleek-spinel-pinned-rebuild-20261021 check` passed 3,596 tests and allocation, inference, and spin-e2e gates; `make ticket-check` validated 138 documents; `git diff --check` passed. Focused mutation command: `FLEEK_MUTATIONS='UnusedPrivateMethod dynamic call boundary,UnusedPrivateMethod inherited scope boundary,UnusedPrivateMethod method object boundary' make mutation JOBS=3`.
