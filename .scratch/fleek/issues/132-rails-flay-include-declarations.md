# 132: Analyze Rails Flay include declarations

**What to build:** Flay structural duplication analysis accepts direct constant `include` declarations alongside supported methods in a simple class.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Compare receiver-free `include` calls with one or more constant or constant-path arguments in simple classes against Flay 2.14.4. The declarations add no method candidates to Flay's `:defn` group; supported methods retain exact findings, mass, score, ordered locations, and complete coverage. Calls with non-constant arguments, a receiver, or a block remain incomplete. Do not broaden this to `extend`, `prepend`, or module singleton behavior.

## Starting evidence

After issue 131, the pinned `UsersController` is complete when selected alone, but the 25-file manifest remains incomplete. `app/controllers/application_controller.rb` has supported method syntax and a direct `include SessionsHelper` declaration; its bare `private` visibility call is supported by issue 131.

## Acceptance criteria

- [ ] A minimal public CLI fixture with a direct `include` declaration fails before the change and matches Flay 2.14.4 afterward.
- [ ] Constant and constant-path include arguments do not make an otherwise supported simple class partial; methods retain exact reference behavior and coverage.
- [ ] Dynamic arguments, receiver calls, and include blocks remain incomplete, protected by mutations.
- [ ] Run required Spinel, project, analyzer, mutation, tracker, and review gates; record exact commands and results in `## Answer`.
- [ ] Add an ADR for the AST boundary and link this child from issue 97. Leave issue 97 open while any Rails manifest gaps remain.

## Execution and stop condition

Claim this ticket before implementation. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Reuse the existing native candidate collector and public duplication contract. Do not execute application code or treat arbitrary class-body calls as supported.

