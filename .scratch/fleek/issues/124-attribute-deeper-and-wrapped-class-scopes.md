# 124: Match Attribute in deeper and wrapped class scopes

**What to build:** Complete pinned Reek 6.6.0 `Attribute` parity for writable attributes in deeper nested classes and classes wrapped inside namespace scopes.

**Part of:** Ticket 24 — shared-syntax analyzer parity.

**Blocked by:** 63 (resolved); 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [x] Record exact Reek findings, contexts, lines, visibility, and status for nested classes beyond one level and classes inside module or wrapper scopes.
- [x] Implement only reproducible mismatches through the native analyzer, or preserve explicit incomplete coverage where exact scope ownership is unsupported.
- [x] Add public CLI contracts and non-equivalent mutation evidence for changed behavior; preserve per-class visibility and exclusion handling.
- [x] Record exact commands, pinned identities, ADR decision, and remaining child links in `## Answer`.

## Answer

Pinned Reek 6.6.0 reports `Profile::Credentials#secret` at line 5, `Profile::Credentials#token` at line 6, and `Profile::Credentials::Secrets#visible` at line 13 in the deep fixture. Its `attr_reader :label` and private `attr_accessor :internal` are clean; the enclosing class's private visibility does not make the child class's default-public writers private. In the wrapped namespace fixture, Reek reports only `Profile::Credentials#secret` at line 9; the private `hidden` writer and read-only `label` are clean. Fleek reports both selected files as `1 selected; 0 analyzed; 1 failed; 0 excluded` with status incomplete.

No production change was needed: these scopes exceed the native scanner's one-level class model. ADR 0240 records the decision to keep them incomplete. `test/default_object_scope_contract.rb` compares exact pinned findings and verifies Fleek's coverage; mutation `Attribute deep and wrapped scope boundary` was caught.

Verification used pinned Spinel `2026.09.12` (`112bae85c1a2`) and Reek 6.6.0. The focused `test/default_object_scope_contract.rb` passed; `Attribute deep and wrapped scope boundary` mutation was caught. `make check JOBS=8` passed with 78 workers, eight mutation workers, all mutants caught, Flay 1008, and Reek 0 warnings. Pinned Spinel `gmake check` passed 3,596 tests plus allocation, inference, and spin-e2e. `make ticket-check` validated 138 documents and `git diff --check` passed. Ticket 124 closes these deep/wrapped cases; parent ticket 24 remains open for its other residual children.
