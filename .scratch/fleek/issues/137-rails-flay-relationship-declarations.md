# 137: Analyze the Rails Relationship model declarations for Flay

**What to build:** Flay structural duplication analysis accepts the pinned `Relationship` model's direct association and presence-validation declarations.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Accept receiver-free, block-free `belongs_to :follower, class_name: "User"` and `belongs_to :followed, class_name: "User"` declarations, plus `validates :follower_id, presence: true` and `validates :followed_id, presence: true`. These are non-candidate class-body declarations. Other macro names, receivers, blocks, arguments, keys, or values remain incomplete. Do not broaden to general Active Record DSL support.

## Starting evidence

Pinned Rails `app/models/relationship.rb` contains exactly the four class-body declarations above. Flay 2.14.4 reports score zero; Fleek currently marks the model partial.

## Acceptance criteria

- [x] Minimal public CLI fixtures fail before implementation and match Flay 2.14.4 afterward.
- [x] The pinned `Relationship` model analyzes completely with unchanged clean Flay output.
- [x] Unsupported names and call shapes remain incomplete, protected by focused mutations.
- [x] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record results in `## Answer`.
- [x] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97's residual frontier after ticket 136. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Accept only the four specified declaration forms.

## Answer

Added exact receiver-free, block-free `belongs_to` calls for `follower` and `followed` with `class_name: "User"`, plus their `presence: true` validations. Other keys, values, call shapes, and macros remain incomplete. The public contract was red before implementation and now matches Flay's score-zero output. The pinned `Relationship` model analyzes completely by itself.

Pinned tools: Spinel `2026.09.12` (`112bae85c1a2`), Flay `2.14.4`, Reek `6.6.0`.

- Focused mutations for declaration support, dynamic association value, false presence, extra keyword, receiver, and block: all caught.
- `make check JOBS=8`: 78 workers passed, including every mutation shard; Flay score 1137 and Reek 0 warnings.
- `make rails-manifest-parity` with `FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce`: passed; exact 25-file manifest, Reek clean, Flay remains explicitly incomplete for residual model files.
- `env PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:/opt/homebrew/opt/make/libexec/gnubin:/usr/bin:/bin make -C /private/tmp/fleek-spinel-pinned-rebuild check`: 3,596 native tests passed; allocation, inference, and `spin-e2e` passed.
- `make ticket-check`: 146 ticket documents valid. `git diff --check`: passed.

ADR 0251 records the exact declaration boundary. Issue 97 remains open for `Micropost` and `User`.
