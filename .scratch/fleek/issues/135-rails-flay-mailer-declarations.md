# 135: Analyze Rails ApplicationMailer declarations for Flay

**What to build:** Flay structural duplication analysis accepts the pinned `ApplicationMailer`'s direct `default` and `layout` declarations.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Support only receiver-free, block-free `default from: <string literal>` and `layout <string literal>` calls in simple classes. They are non-candidate declarations. Compare the public CLI output with Flay 2.14.4. Calls with receivers, blocks, other arguments, unsupported values, or other class-body method names remain incomplete. Do not expand to general Rails macros.

## Starting evidence

Pinned Rails `app/mailers/application_mailer.rb` contains `default from: "user@realdomain.com"` and `layout "mailer"`, with no methods. Flay reports score zero; Fleek currently marks this file partial.

## Acceptance criteria

- [x] A minimal public CLI fixture fails before implementation and matches Flay 2.14.4 afterward.
- [x] The pinned `ApplicationMailer` analyzes completely with unchanged clean Flay output.
- [x] Unsupported macro names and call shapes remain incomplete, protected by focused mutations.
- [x] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record results in `## Answer`.
- [x] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97's residual frontier after ticket 134. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Reuse the class-body declaration path and do not execute application code.

## Answer

Added exact receiver-free, block-free `default from: <string literal>` and `layout <string literal>` class declarations. Dynamic values, other keys/macros, receivers, blocks, and extra layout arguments remain incomplete. The focused CLI contract was red before implementation and now matches Flay's clean score-zero output; pinned `ApplicationMailer` analyzes completely by itself.

Pinned tools: Spinel `2026.09.12` (`112bae85c1a2`), Flay `2.14.4`, Reek `6.6.0`.

- Focused mutations for dynamic default values and extra layout arguments: both caught.
- `make check JOBS=8`: 78 workers passed, including every mutation shard; Flay score 1137 and Reek 0 warnings.
- `make rails-manifest-parity` with `FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce`: passed; exact 25-file manifest, Reek clean, Flay remains explicitly incomplete for remaining files.
- `env PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:/opt/homebrew/opt/make/libexec/gnubin:/usr/bin:/bin make -C /private/tmp/fleek-spinel-pinned-rebuild check`: 3,596 native tests passed; allocation, inference, and `spin-e2e` passed.
- `make ticket-check`: 144 ticket documents valid. `git diff --check`: passed.

ADR 0249 records the fail-closed boundary. Issue 97 remains open for the other residual manifest files.
