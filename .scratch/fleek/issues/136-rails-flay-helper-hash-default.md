# 136: Analyze the Rails helper hash default for Flay

**What to build:** Flay structural duplication analysis accepts the pinned `UsersHelper#gravatar_for` optional parameter default `{ size: 80 }`.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Accept a nonempty hash literal with one symbol key `size` and one integer literal value as an optional positional method parameter default. Preserve existing Flay candidate mass, identity, and location behavior. Other keys, dynamic values, and unsupported hash forms remain incomplete. Do not broaden general hash-default support without separate reference-backed evidence.

## Starting evidence

Pinned Rails `app/helpers/users_helper.rb` contains `def gravatar_for(user, options = { size: 80 })`. Flay 2.14.4 reports score zero; Fleek currently marks the helper partial.

## Acceptance criteria

- [x] A minimal public CLI fixture fails before implementation and matches Flay 2.14.4 afterward.
- [x] The pinned `UsersHelper` analyzes completely with unchanged clean Flay output.
- [x] Other keys and dynamic or unsupported values remain incomplete, protected by focused mutations.
- [x] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record results in `## Answer`.
- [x] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97's residual frontier after ticket 135. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Keep the accepted parameter default to the exact `size: 80` hash shape.

## Answer

Added support for the exact optional positional default `{ size: 80 }`; hash defaults with another key, a dynamic value, or additional entries remain incomplete. The public contract was red before implementation and now matches Flay's score-zero output. The pinned `UsersHelper` now analyzes completely by itself.

Pinned tools: Spinel `2026.09.12` (`112bae85c1a2`), Flay `2.14.4`, Reek `6.6.0`.

- Focused mutations for a different key, dynamic value, and extra entry: all caught.
- `make check JOBS=8`: 78 workers passed, including every mutation shard; Flay score 1137 and Reek 0 warnings.
- `make rails-manifest-parity` with `FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce`: passed; exact 25-file manifest, Reek clean, Flay remains explicitly incomplete for remaining model files.
- `env PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:/opt/homebrew/opt/make/libexec/gnubin:/usr/bin:/bin make -C /private/tmp/fleek-spinel-pinned-rebuild check`: 3,596 native tests passed; allocation, inference, and `spin-e2e` passed.
- `make ticket-check`: 145 ticket documents valid. `git diff --check`: passed.

ADR 0250 records the exact default boundary. Issue 97 remains open for the residual model files.
