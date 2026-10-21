# 125: Match InstanceVariableAssumption in deeper and wrapped class scopes

**What to build:** Complete pinned Reek 6.6.0 `InstanceVariableAssumption` parity for class contexts deeper than one direct child and classes wrapped in modules.

**Part of:** Ticket 24 — shared-syntax analyzer parity.

**Blocked by:** 64 (resolved); 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [x] Match pinned findings, context, class declaration lines, initialization boundaries, and configured exclusions for deeper and module-wrapped classes.
- [x] Preserve explicit incomplete coverage for unsupported class shapes; do not return clean when a nested class cannot be analyzed.
- [x] Add public CLI contracts and non-equivalent mutation evidence for changed behavior.
- [x] Record exact commands, pinned identities, ADR decision, and residual child links in `## Answer`.

## Answer

Pinned Reek 6.6.0 reports `Profile::Account::Credentials` at line 3 and `Profiles::Credentials` at line 2 for uninitialized `@name`. The three-level initialized fixture is clean. A detector exclusion for both contexts makes the deep and wrapped fixtures clean in Reek. Fleek reports every selected shape as `1 selected; 0 analyzed; 1 failed; 0 excluded` with status incomplete, including initialized and excluded cases, because its native walker cannot verify those contexts.

No production change was needed. ADR 0241 records the choice to keep unvisited nested scopes incomplete. `test/default_object_scope_contract.rb` compares the pinned findings, initialization control, and exclusions; mutation `InstanceVariableAssumption deep and wrapped scope boundary` was caught.

Verification used pinned Spinel `2026.09.12` (tag object `00ce35bb96e489620358ffbc48791001a73778a5`, source `112bae85c1a25fc5399009a849f805bfe691426b`), Flay 2.14.4, and Reek 6.6.0. The focused `test/default_object_scope_contract.rb` passed, as did the focused mutation label. `make check JOBS=8` passed 78 workers with all mutations caught, Flay score 1008, and Reek 0 warnings. `gmake -C /private/tmp/fleek-spinel-pinned-rebuild check` passed 3,596 tests, allocation and inference checks, and `spin-e2e`. `make ticket-check` validated 138 documents; `git diff --check` passed. ADR 0241 records the fail-closed scope decision. No child tickets remain for this slice; parent Ticket 24 remains open for other detector parity work.
