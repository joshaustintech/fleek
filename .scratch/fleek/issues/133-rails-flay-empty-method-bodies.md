# 133: Analyze empty Rails class methods for Flay

**What to build:** Flay structural duplication analysis treats empty method bodies in simple classes as supported, without changing candidate findings.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Match Flay 2.14.4 for direct methods with no body in simple classes. Empty definitions must not make an otherwise supported class partial or create method-level groups. Preserve their role in class-level groups, including exact kind, identity, mass, score, and locations. Methods with supported nonempty bodies retain exact existing results; unsupported method bodies stay incomplete. Do not expand parameter or class-scope support.

## Starting evidence

The pinned Rails `static_pages_controller.rb` contains four direct methods with empty bodies. Flay 2.14.4 reports score zero; Fleek currently marks that file partial. `password_resets_controller.rb` also has empty `new` and `edit` methods, and `sessions_controller.rb` contains an empty `new` method.

## Acceptance criteria

- [x] A public CLI contract for empty class methods fails before implementation and matches Flay 2.14.4 afterward.
- [x] Empty-only classes are complete with no method groups or score, matching Flay 2.14.4.
- [x] Empty methods inside otherwise supported classes preserve exact Flay class groups and do not make sources partial.
- [x] The pinned Rails `static_pages_controller.rb` is complete when selected alone.
- [x] Unsupported body shapes still remain incomplete, with focused mutation coverage.
- [x] Validate the affected pinned Rails files and record exact gates in `## Answer`.
- [x] Add an ADR and link this child from issue 97; keep issue 97 open while other gaps remain.

## Execution and stop condition

Claimed from the issue 97 frontier after ticket 132. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Reuse the public duplication contract. Preserve fail-closed behavior for every body that is not empty or already supported.

## Answer

The public CLI contract failed before implementation because empty methods made supported classes incomplete. Empty methods are now retained in class candidate trees with no method-level body nodes; they add no method group, while class-group mass includes the Flay-required extra point per empty method. Unsupported body forms still fail closed.

RED/GREEN: the empty-only fixture now matches Flay's clean score-zero result with complete coverage. A paired-class fixture with distinct empty method names matches Flay's similar `:class` group at mass/score 56 and ordered locations 1/12. The pinned `static_pages_controller.rb` is complete when selected alone and matches Flay's zero score.

Pinned tools: Spinel `2026.09.12` (`112bae85c1a2`), Flay `2.14.4`, Reek `6.6.0`.

- Focused mutations `Flay empty class methods rejected` and `Flay empty method class mass`: both caught.
- `make rails-manifest-parity` with `FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce`: passed; exact 25-file manifest, Reek clean, Flay explicitly incomplete at 0/25 analyzed because remaining source forms persist.
- `make check JOBS=8`: 78 workers passed; all mutations caught; Flay score 1137; Reek 0 warnings.
- `env PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:/opt/homebrew/opt/make/libexec/gnubin:/usr/bin:/bin make -C /private/tmp/fleek-spinel-pinned-rebuild check`: 3,596 native tests passed; allocation, inference, and `spin-e2e` passed.
- `make ticket-check`: 142 ticket documents valid. `git diff --check`: passed.

ADR 0247 records empty method tree and class-mass semantics. Issue 97 remains open until every residual manifest shape resolves.
