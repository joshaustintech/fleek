# 138: Analyze the Rails Micropost user association for Flay

**What to build:** Flay structural duplication analysis accepts the pinned `Micropost` model's direct `belongs_to :user` declaration.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Accept only the receiver-free, block-free `belongs_to :user` call with exactly one symbol argument as a non-candidate class-body declaration. Calls with options, another association name, a receiver, a block, or any other method remain incomplete. Do not broaden to general Active Record DSL support.

## Starting evidence

Pinned Rails `app/models/micropost.rb` starts with `belongs_to :user`. Flay 2.14.4 reports score zero; Fleek currently marks the model partial because it also contains other unsupported class-body forms.

## Acceptance criteria

- [x] A minimal public CLI fixture remains incomplete due to residual declarations before and after this change, while the supported call shape is protected by a focused acceptance contract.
- [x] Unsupported association calls remain incomplete, protected by focused mutations.
- [x] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record results in `## Answer`.
- [x] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97's residual frontier after ticket 137. Use pinned Spinel 2026.09.12 and Flay 2.14.4. This slice covers only the one bare association; it does not resolve the entire `Micropost` file.

## Answer

Added support for the exact receiver-free, block-free `belongs_to :user` call. Calls with options, another name, a receiver, a block, or an unrelated macro remain incomplete. The minimal public CLI fixture matches Flay's score-zero output. The pinned `Micropost` still reports incomplete because its attachment, default scope, and validation declarations remain unsupported.

Pinned tools: Spinel `2026.09.12` (`112bae85c1a2`), Flay `2.14.4`, Reek `6.6.0`.

- Focused mutations for support, association name, extra args, receiver, and block: all caught.
- `make check JOBS=8`: 78 workers passed, including every mutation shard; Flay score 1137 and Reek 0 warnings.
- `make rails-manifest-parity` with `FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce`: passed; exact 25-file manifest and Reek clean; Flay remains explicitly incomplete.
- `env PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:/opt/homebrew/opt/make/libexec/gnubin:/usr/bin:/bin make -C /private/tmp/fleek-spinel-pinned-rebuild check`: 3,596 native tests passed; allocation, inference, and `spin-e2e` passed.
- `make ticket-check`: 147 ticket documents valid. `git diff --check`: passed.

ADR 0252 records the one-call boundary. Issue 97 remains open for remaining Micropost and User shapes.
