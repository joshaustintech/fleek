# 131: Analyze Rails Flay visibility declarations

**What to build:** Flay structural duplication analysis accepts bare visibility declarations alongside supported methods in a simple class.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Compare bare `private`, `protected`, and `public` declarations with Flay 2.14.4 in simple classes containing otherwise supported methods. Visibility declarations add no method candidates to Flay's `:defn` group. Calls with arguments, receiver-qualified calls, and visibility changes inside unsupported scope shapes remain incomplete. Verify findings, group kind, mass, score, original ordered locations, coverage, streams, and status.

## Starting evidence

The exact Rails corpus still marks all 25 Flay sources partial after issue 130 resolves direct `before_action` calls. `UsersController` contains a bare `private` call mixed with supported methods. `test/duplication_contract.rb` already has paired callback fixtures and can host the focused visibility case.

## Acceptance criteria

- [x] A minimal public CLI contract with a bare visibility declaration fails before the change and matches Flay 2.14.4 afterward.
- [x] Bare visibility declarations do not make an otherwise supported simple class partial; method findings, mass, score, order, and coverage match the reference.
- [x] Calls with arguments and receiver-qualified visibility calls remain incomplete, protected by mutations.
- [x] Run required Spinel, project, analyzer, mutation, tracker, and review gates; record exact commands and results in `## Answer`.
- [x] Add an ADR for the AST boundary and link this child from issue 97. Leave issue 97 open while any Rails manifest gaps remain.

## Execution and stop condition

Claim this ticket before implementation. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Reuse the existing native candidate collector and public duplication contract. Do not execute application code or treat arbitrary class-body calls as supported.

## Answer

Added direct, receiver-free `private`, `protected`, and `public` calls with no arguments as non-candidate declarations in simple class bodies. Calls with arguments, receiver-qualified calls, callback blocks, and other unsupported statements remain partial. The focused contract was red before implementation; afterward Flay 2.14.4 and Fleek match the `:defn` similar group at mass/score 48 and ordered locations 5/16, with complete one-source coverage. Argument and receiver fixtures retain explicit partial status; focused mutations catch accepting either unsupported form.

The pinned Rails `UsersController` now analyzes completely when selected alone and still matches the reference score-48 group at lines 51/58. The combined 25-file Rails manifest remains incomplete because other residual shapes remain. A default-configuration contract now checks only whether the opt-in detector is disabled; complete Flay output can expose unrelated Reek findings, so its prior aggregate exit-status restriction was not relevant to that assertion.

Pinned tools: Spinel `2026.09.12` (`112bae85c1a2`), Flay `2.14.4`, Reek `6.6.0`.

- `make rails-manifest-parity` with `FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce`: passed. Exact 25-file manifest identity and existing incomplete boundary remain asserted; Reek is clean.
- `make check JOBS=8`: 78 workers passed, all mutations caught, Flay score 1112, Reek 0 warnings.
- `make -C /private/tmp/fleek-spinel-pinned-rebuild check`: 3,596 tests passed; allocation, inference, and `spin-e2e` passed.
- `make ticket-check`: 140 ticket documents valid. `git diff --check`: passed.

ADR 0245 records the supported visibility calls and fail-closed boundaries. Issue 97 remains open.

