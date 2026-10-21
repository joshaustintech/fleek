# 132: Analyze Rails Flay include declarations

**What to build:** Flay structural duplication analysis accepts direct constant `include` declarations alongside supported methods in a simple class.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Compare receiver-free `include` calls with one or more constant or constant-path arguments in simple classes against Flay 2.14.4. The declarations add no method candidates to Flay's `:defn` group; supported methods retain exact findings, mass, score, ordered locations, and complete coverage. Calls with non-constant arguments, a receiver, or a block remain incomplete. Do not broaden this to `extend`, `prepend`, or module singleton behavior.

## Starting evidence

After issue 131, the pinned `UsersController` is complete when selected alone, but the 25-file manifest remains incomplete. `app/controllers/application_controller.rb` has supported method syntax and a direct `include SessionsHelper` declaration; its bare `private` visibility call is supported by issue 131.

## Acceptance criteria

- [x] A minimal public CLI fixture with a direct `include` declaration fails before the change and matches Flay 2.14.4 afterward.
- [x] Constant and constant-path include arguments do not make an otherwise supported simple class partial; methods retain exact reference behavior and coverage.
- [x] Dynamic arguments, receiver calls, and include blocks remain incomplete, protected by mutations.
- [x] Run required Spinel, project, analyzer, mutation, tracker, and review gates; record exact commands and results in `## Answer`.
- [x] Add an ADR for the AST boundary and link this child from issue 97. Leave issue 97 open while any Rails manifest gaps remain.

## Execution and stop condition

Claim this ticket before implementation. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Reuse the existing native candidate collector and public duplication contract. Do not execute application code or treat arbitrary class-body calls as supported.

## Answer

Added direct, receiver-free `include` calls with no block and one or more constant or constant-path arguments as non-candidate declarations in simple classes. Dynamic arguments, receiver calls, blocks, and other class-body statements remain incomplete. The public CLI contract was red before implementation and green afterward; Flay 2.14.4 and Fleek match the `:defn` similar group at mass/score 48 and ordered locations 5/12 with complete one-source coverage. The pinned Rails `ApplicationController` is now complete when selected alone. Focused mutations catch accepting dynamic arguments, receiver calls, or blocks.

Pinned tools: Spinel `2026.09.12` (`112bae85c1a2`), Flay `2.14.4`, Reek `6.6.0`.

- `make rails-manifest-parity` with `FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce`: passed. Exact 25-file manifest identity; Reek clean; combined Rails Flay remains explicitly incomplete at 0/25 fully analyzed because other residual shapes remain.
- `make check JOBS=8`: 78 workers passed, all mutations caught, Flay score 1118, Reek 0 warnings.
- `make -C /private/tmp/fleek-spinel-pinned-rebuild check` with pinned Ruby 3.4.9 and GNU make on `PATH`: 3,596 tests passed; allocation, inference, and `spin-e2e` passed. The first attempt used the host BSD make and failed the pack subtest; the corrected GNU make environment passed.
- Focused mutations: include dynamic-argument, receiver-call, and block rejection passed; updated callback-declaration and class-partial-status mutations also passed.
- `make ticket-check`: 141 ticket documents valid. `git diff --check`: passed.

ADR 0246 records the supported AST boundary. Issue 97 remains open until all other Rails manifest gaps are resolved.

