# 141: Analyze the Rails Micropost presence and length validations for Flay

**What to build:** Flay structural duplication analysis accepts the pinned `Micropost` `user_id` presence validation and `content` presence/maximum-length validation.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved), 140 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Accept exactly `validates :user_id, presence: true` and `validates :content, presence: true, length: { maximum: 140 }` as non-candidate class-body declarations. Keep other attributes, validation keys, values, hash sizes, receivers, blocks, and extra arguments incomplete. Image validation is outside this issue.

## Starting evidence

Pinned Rails `app/models/micropost.rb` contains both declarations. Flay 2.14.4 reports score zero; Fleek marks the file partial because these and the image validation remain unsupported.

## Acceptance criteria

- [x] Minimal public CLI fixtures match Flay 2.14.4 after implementation.
- [x] Unsupported validation attributes and shapes remain incomplete with focused mutation coverage.
- [x] The pinned `Micropost` remains incomplete until image validation is supported.
- [x] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record results in `## Answer`.
- [x] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97 after issue 140. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Implement only these two validations; do not add generic Rails validation support.

## Answer

Implemented the exact `validates :user_id, presence: true` and `validates :content, presence: true, length: { maximum: 140 }` declarations as non-candidate class-body calls. The public CLI fixture matches Flay 2.14.4 at score zero. Other attributes, validation keys, presence values, extra attributes or options, length keys, maxima and extra length options, receivers and blocks remain incomplete. Twelve ticket-specific mutations are caught. The content-without-presence fixture shares the presence check with the key boundary, so its mutation is caught by the key fixture.

Verification with Spinel `112bae85c1a2 (2026.09.12)` (Apple clang 2100.4.1.1), Flay 2.14.4 and Reek 6.6.0:
- `make -B check`: 80 workers and 399 mutants caught (555 s).
- Flay on `bin`: score 0. The pre-existing test-contract score of 1137 is unchanged. Reek: 0 warnings.
- `FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce make rails-manifest-parity`: pass. Rails Flay stays explicitly incomplete.
- `make ticket-check`: 151 valid.

Pinned `Micropost` stays partial because of its image validation; `User` remains the other manifest gap. Further exact-shape slices are replaced by the generic engine in [issue 142](142-generic-flay-core-engine.md). See [ADR 0255](../../../docs/adr/0255-bound-rails-micropost-basic-validations.md).
