# 137: Analyze the Rails Relationship model declarations for Flay

**What to build:** Flay structural duplication analysis accepts the pinned `Relationship` model's direct association and presence-validation declarations.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Accept receiver-free, block-free `belongs_to :follower, class_name: "User"` and `belongs_to :followed, class_name: "User"` declarations, plus `validates :follower_id, presence: true` and `validates :followed_id, presence: true`. These are non-candidate class-body declarations. Other macro names, receivers, blocks, arguments, keys, or values remain incomplete. Do not broaden to general Active Record DSL support.

## Starting evidence

Pinned Rails `app/models/relationship.rb` contains exactly the four class-body declarations above. Flay 2.14.4 reports score zero; Fleek currently marks the model partial.

## Acceptance criteria

- [ ] Minimal public CLI fixtures fail before implementation and match Flay 2.14.4 afterward.
- [ ] The pinned `Relationship` model analyzes completely with unchanged clean Flay output.
- [ ] Unsupported names and call shapes remain incomplete, protected by focused mutations.
- [ ] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record results in `## Answer`.
- [ ] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97's residual frontier after ticket 136. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Accept only the four specified declaration forms.
