# 133: Analyze empty Rails class methods for Flay

**What to build:** Flay structural duplication analysis treats empty method bodies in simple classes as supported, without changing candidate findings.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Match Flay 2.14.4 for direct methods with no body in simple classes. Empty definitions must not make an otherwise supported class partial and must not add duplication groups, mass, or score. Methods with supported nonempty bodies retain exact existing results; unsupported method bodies stay incomplete. Do not expand parameter or class-scope support.

## Starting evidence

The pinned Rails `static_pages_controller.rb` contains four direct methods with empty bodies. Flay 2.14.4 reports score zero; Fleek currently marks that file partial. `password_resets_controller.rb` also has empty `new` and `edit` methods, and `sessions_controller.rb` contains an empty `new` method.

## Acceptance criteria

- [ ] A public CLI contract for empty class methods fails before implementation and matches Flay 2.14.4 afterward.
- [ ] Empty methods do not make supported classes partial and do not alter existing findings or score.
- [ ] Unsupported body shapes still remain incomplete, with focused mutation coverage.
- [ ] Validate the affected pinned Rails files and record exact gates in `## Answer`.
- [ ] Add an ADR and link this child from issue 97; keep issue 97 open while other gaps remain.

## Execution and stop condition

Claimed from the issue 97 frontier after ticket 132. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Reuse the public duplication contract. Preserve fail-closed behavior for every body that is not empty or already supported.
