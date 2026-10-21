# 131: Analyze Rails Flay visibility declarations

**What to build:** Flay structural duplication analysis accepts bare visibility declarations alongside supported methods in a simple class.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Compare bare `private`, `protected`, and `public` declarations with Flay 2.14.4 in simple classes containing otherwise supported methods. Visibility declarations add no method candidates to Flay's `:defn` group. Calls with arguments, receiver-qualified calls, and visibility changes inside unsupported scope shapes remain incomplete. Verify findings, group kind, mass, score, original ordered locations, coverage, streams, and status.

## Starting evidence

The exact Rails corpus still marks all 25 Flay sources partial after issue 130 resolves direct `before_action` calls. `UsersController` contains a bare `private` call mixed with supported methods. `test/duplication_contract.rb` already has paired callback fixtures and can host the focused visibility case.

## Acceptance criteria

- [ ] A minimal public CLI contract with a bare visibility declaration fails before the change and matches Flay 2.14.4 afterward.
- [ ] Bare visibility declarations do not make an otherwise supported simple class partial; method findings, mass, score, order, and coverage match the reference.
- [ ] Calls with arguments and receiver-qualified visibility calls remain incomplete, protected by a mutation.
- [ ] Run required Spinel, project, analyzer, mutation, tracker, and review gates; record exact commands and results in `## Answer`.
- [ ] Add an ADR for the AST boundary and link this child from issue 97. Leave issue 97 open while any Rails manifest gaps remain.

## Execution and stop condition

Claim this ticket before implementation. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Reuse the existing native candidate collector and public duplication contract. Do not execute application code or treat arbitrary class-body calls as supported.

