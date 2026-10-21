# 130: Analyze Rails class callback declarations for Flay

**What to build:** Flay structural duplication analysis accepts direct Rails-style callback declarations alongside supported methods in a simple class.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use the pinned Rails `UsersController` source and minimal paired fixtures with direct `before_action` declarations containing positional symbols, arrays, and keyword-hash options. Compare Flay 2.14.4 and Fleek public CLI findings, group kind, mass, score, ordered locations, coverage, streams, and status. Callback declaration ASTs contribute no method candidates; supported methods retain their existing candidates. Unknown class-body statement forms and callbacks with blocks remain explicitly incomplete.

## Starting evidence

`FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce make rails-manifest-parity` reproduces the pinned score-48 group at `users_controller.rb:51,58`, while the Flay scan marks all 25 files partial. `UsersController` contains three direct `before_action` calls before its methods. Issue 96 and the census receipt record this known class-declaration gap.

## Acceptance criteria

- [x] A focused public contract compares callback-bearing sources against Flay 2.14.4 and fails before the implementation change.
- [x] Direct callback declarations in the listed forms do not make an otherwise supported simple class partial; their methods retain exact reference findings and coverage semantics.
- [x] Unsupported declaration and block forms remain incomplete, with mutations proving the boundary.
- [x] Run required Spinel, project, analyzer, mutation, tracker, and review gates; record commands and results in `## Answer`.
- [x] Add an ADR for the AST boundary and link this child from issue 97. Do not close issue 97 unless every remaining manifest gap is resolved.

## Execution and stop condition

Claim this ticket before implementation. Use pinned Spinel 2026.09.12, Flay 2.14.4, and existing duplication contracts. Do not execute application code or weaken reference expectations. Keep the work limited to direct callback declarations in simple class bodies; route other class-level macros or unsupported method shapes to separately evidenced children.

## Answer

Added a bounded collector for direct `before_action` calls in simple class bodies. It requires an implicit receiver, no block, and nonempty symbol, array, or hash-style arguments. Other calls and callback blocks continue to mark the source partial. Supported method findings and locations remain unchanged.

RED/GREEN: changed the public contract first to require complete coverage for callback fixtures; `make rails-manifest-parity` failed on the old incomplete status. After implementation, the contract passed and retained Flay 2.14.4's similar `:defn` group at mass/score 48 with ordered locations. A separate callback-block fixture confirms Fleek remains incomplete when the reference's class grouping is outside the supported subset. Focused mutations caught callback acceptance, callback-block acceptance, candidate loss, and the existing partial reporting boundaries.

Pinned tools: Spinel `2026.09.12` (`112bae85c1a2`), Flay `2.14.4`, Reek `6.6.0`. Evidence:

- `make rails-manifest-parity` with `FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce`: both contracts passed. The manifest revision and 25-file selection matched; Reek remained clean at 25/25. Rails Flay remains explicitly incomplete because other residual shapes remain.
- `make check JOBS=8`: 78 workers passed, all mutations caught, Flay score 1044, Reek 0 warnings.
- `make -C /private/tmp/fleek-spinel-pinned-rebuild check`: 3,596 native tests passed; allocation, inference, and `spin-e2e` passed.
- `make ticket-check`: 139 ticket documents valid. `git diff --check`: passed.

ADR 0244 records the narrow AST boundary. Issue 97 remains open until all other Rails manifest gaps are resolved.

