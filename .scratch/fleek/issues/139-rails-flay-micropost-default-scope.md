# 139: Analyze the Rails Micropost default scope for Flay

**What to build:** Flay structural duplication analysis accepts the pinned `Micropost` default scope `default_scope -> { order(created_at: :desc) }`.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Accept only a receiver-free, block-free `default_scope` call with one lambda argument whose body is exactly `order(created_at: :desc)`, also receiver-free and block-free. Treat it as a non-candidate declaration. Other lambda bodies, call shapes, or class-body macros remain incomplete.

## Starting evidence

Pinned Rails `app/models/micropost.rb` contains `default_scope -> { order(created_at: :desc) }`. Flay 2.14.4 reports score zero; Fleek currently marks the model partial due to several remaining declarations.

## Acceptance criteria

- [x] A minimal public CLI fixture matches Flay 2.14.4 after implementation.
- [x] Unsupported default-scope bodies and call shapes remain incomplete, protected by focused mutations.
- [x] The pinned `Micropost` remains incomplete until its attachment and validation forms are supported.
- [x] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record results in `## Answer`.
- [x] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97's residual frontier after ticket 138. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Limit lambda support to this direct default-scope shape.

## Answer

Implemented the exact receiver-free `default_scope -> { order(created_at: :desc) }` declaration. The public CLI fixture matches Flay 2.14.4 with score zero. Unsupported keys, direction, extra body statements, lambda parameters, receiver, and alternate macro remain incomplete. Ticket-specific mutations caught the supported-shape, boundary, and class-method partial-status regressions.

Verification: `make check JOBS=8` passed all 78 workers; Flay score 1137; Reek 0 warnings. Pinned Spinel `2026.09.12` check passed 3,596 tests, allocation and inference checks, and `spin-e2e: ALL GREEN`. Rails manifest contract passed with full model parity still explicitly incomplete. Tracker check: pending final run.

Remaining Micropost gaps are its attachment declaration and validations; the `User` model remains partial. See [ADR 0253](../../../docs/adr/0253-bound-rails-micropost-default-scope.md).
