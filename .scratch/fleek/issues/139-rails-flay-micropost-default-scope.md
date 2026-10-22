# 139: Analyze the Rails Micropost default scope for Flay

**What to build:** Flay structural duplication analysis accepts the pinned `Micropost` default scope `default_scope -> { order(created_at: :desc) }`.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Accept only a receiver-free, block-free `default_scope` call with one lambda argument whose body is exactly `order(created_at: :desc)`, also receiver-free and block-free. Treat it as a non-candidate declaration. Other lambda bodies, call shapes, or class-body macros remain incomplete.

## Starting evidence

Pinned Rails `app/models/micropost.rb` contains `default_scope -> { order(created_at: :desc) }`. Flay 2.14.4 reports score zero; Fleek currently marks the model partial due to several remaining declarations.

## Acceptance criteria

- [ ] A minimal public CLI fixture matches Flay 2.14.4 after implementation.
- [ ] Unsupported default-scope bodies and call shapes remain incomplete, protected by focused mutations.
- [ ] The pinned `Micropost` remains incomplete until its attachment and validation forms are supported.
- [ ] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record results in `## Answer`.
- [ ] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97's residual frontier after ticket 138. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Limit lambda support to this direct default-scope shape.
