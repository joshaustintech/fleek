# 130: Analyze Rails class callback declarations for Flay

**What to build:** Flay structural duplication analysis accepts direct Rails-style callback declarations alongside supported methods in a simple class.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Use the pinned Rails `UsersController` source and minimal paired fixtures with direct `before_action` declarations containing positional symbols, arrays, and keyword-hash options. Compare Flay 2.14.4 and Fleek public CLI findings, group kind, mass, score, ordered locations, coverage, streams, and status. Callback declaration ASTs contribute no method candidates; supported methods retain their existing candidates. Unknown class-body statement forms and callbacks with blocks remain explicitly incomplete.

## Starting evidence

`FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce make rails-manifest-parity` reproduces the pinned score-48 group at `users_controller.rb:51,58`, while the Flay scan marks all 25 files partial. `UsersController` contains three direct `before_action` calls before its methods. Issue 96 and the census receipt record this known class-declaration gap.

## Acceptance criteria

- [ ] A focused public contract compares callback-bearing sources against Flay 2.14.4 and fails before the implementation change.
- [ ] Direct callback declarations in the listed forms do not make an otherwise supported simple class partial; their methods retain exact reference findings and coverage semantics.
- [ ] Unsupported declaration and block forms remain incomplete, with a mutation proving the boundary.
- [ ] Run required Spinel, project, analyzer, mutation, tracker, and review gates; record commands and results in `## Answer`.
- [ ] Add an ADR for the AST boundary and link this child from issue 97. Do not close issue 97 unless every remaining manifest gap is resolved.

## Execution and stop condition

Claim this ticket before implementation. Use pinned Spinel 2026.09.12, Flay 2.14.4, and existing duplication contracts. Do not execute application code or weaken reference expectations. Keep the work limited to direct callback declarations in simple class bodies; route other class-level macros or unsupported method shapes to separately evidenced children.

