# 138: Analyze the Rails Micropost user association for Flay

**What to build:** Flay structural duplication analysis accepts the pinned `Micropost` model's direct `belongs_to :user` declaration.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Accept only the receiver-free, block-free `belongs_to :user` call with exactly one symbol argument as a non-candidate class-body declaration. Calls with options, another association name, a receiver, a block, or any other method remain incomplete. Do not broaden to general Active Record DSL support.

## Starting evidence

Pinned Rails `app/models/micropost.rb` starts with `belongs_to :user`. Flay 2.14.4 reports score zero; Fleek currently marks the model partial because it also contains other unsupported class-body forms.

## Acceptance criteria

- [ ] A minimal public CLI fixture remains incomplete due to residual declarations before and after this change, while the supported call shape is protected by a focused acceptance contract.
- [ ] Unsupported association calls remain incomplete, protected by focused mutations.
- [ ] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record results in `## Answer`.
- [ ] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97's residual frontier after ticket 137. Use pinned Spinel 2026.09.12 and Flay 2.14.4. This slice covers only the one bare association; it does not resolve the entire `Micropost` file.
