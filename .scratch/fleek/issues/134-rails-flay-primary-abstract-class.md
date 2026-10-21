# 134: Analyze Rails primary_abstract_class declarations for Flay

**What to build:** Flay structural duplication analysis accepts Rails' direct `primary_abstract_class` declaration in a simple class.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Treat only a receiver-free `primary_abstract_class` call with no block and no arguments as a non-candidate class declaration. Compare the public CLI result against Flay 2.14.4. Calls with a receiver, arguments, a block, or any other class-body method remain incomplete. Do not broaden to arbitrary Rails macros.

## Starting evidence

Pinned Rails `app/models/application_record.rb` contains `class ApplicationRecord < ActiveRecord::Base` with a direct `primary_abstract_class` call and no methods. Flay reports score zero; Fleek currently marks the file partial.

## Acceptance criteria

- [x] A minimal public CLI fixture fails before implementation and matches Flay 2.14.4 afterward.
- [x] The pinned `ApplicationRecord` analyzes completely with unchanged clean Flay output.
- [x] Other class-body calls and unsupported call forms remain incomplete, protected by focused mutations.
- [x] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record exact results in `## Answer`.
- [x] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97's residual frontier after ticket 133. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Reuse the existing class-body declaration path. Never treat arbitrary class-body calls as harmless.

## Answer

Added one exact class-body exception: receiver-free `primary_abstract_class` with no args or block. The public contract was red before implementation and green afterward. The pinned `ApplicationRecord` is complete with Flay's clean score-zero output. Calls with arguments, receiver, block, or any other method name remain incomplete.

Pinned tools: Spinel `2026.09.12` (`112bae85c1a2`), Flay `2.14.4`, Reek `6.6.0`.

- Focused mutations for args, receiver, block, and unrelated macro: all caught.
- `make rails-manifest-parity` with `FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce`: passed; exact 25-file manifest; Reek clean; Flay remains explicitly incomplete because other source shapes remain.
- `make check JOBS=8`: 78 workers passed; all mutation workers passed; Flay and Reek command checks passed, Reek reported 0 warnings.
- `env PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:/opt/homebrew/opt/make/libexec/gnubin:/usr/bin:/bin make -C /private/tmp/fleek-spinel-pinned-rebuild check`: 3,596 native tests passed; allocation, inference, and `spin-e2e` passed.
- `make ticket-check`: 143 ticket documents valid. `git diff --check`: passed.

ADR 0248 records the exact macro boundary. Issue 97 remains open until all residual manifest gaps resolve.
