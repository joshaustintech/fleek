# 141: Analyze the Rails Micropost presence and length validations for Flay

**What to build:** Flay structural duplication analysis accepts the pinned `Micropost` `user_id` presence validation and `content` presence/maximum-length validation.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved), 140 (resolved).

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Accept exactly `validates :user_id, presence: true` and `validates :content, presence: true, length: { maximum: 140 }` as non-candidate class-body declarations. Keep other attributes, validation keys, values, hash sizes, receivers, blocks, and extra arguments incomplete. Image validation is outside this issue.

## Starting evidence

Pinned Rails `app/models/micropost.rb` contains both declarations. Flay 2.14.4 reports score zero; Fleek marks the file partial because these and the image validation remain unsupported.

## Acceptance criteria

- [ ] Minimal public CLI fixtures match Flay 2.14.4 after implementation.
- [ ] Unsupported validation attributes and shapes remain incomplete with focused mutation coverage.
- [ ] The pinned `Micropost` remains incomplete until image validation is supported.
- [ ] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record results in `## Answer`.
- [ ] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97 after issue 140. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Implement only these two validations; do not add generic Rails validation support.
