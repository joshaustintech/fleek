# 135: Analyze Rails ApplicationMailer declarations for Flay

**What to build:** Flay structural duplication analysis accepts the pinned `ApplicationMailer`'s direct `default` and `layout` declarations.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 115 (resolved).

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Support only receiver-free, block-free `default from: <string literal>` and `layout <string literal>` calls in simple classes. They are non-candidate declarations. Compare the public CLI output with Flay 2.14.4. Calls with receivers, blocks, other arguments, unsupported values, or other class-body method names remain incomplete. Do not expand to general Rails macros.

## Starting evidence

Pinned Rails `app/mailers/application_mailer.rb` contains `default from: "user@realdomain.com"` and `layout "mailer"`, with no methods. Flay reports score zero; Fleek currently marks this file partial.

## Acceptance criteria

- [ ] A minimal public CLI fixture fails before implementation and matches Flay 2.14.4 afterward.
- [ ] The pinned `ApplicationMailer` analyzes completely with unchanged clean Flay output.
- [ ] Unsupported macro names and call shapes remain incomplete, protected by focused mutations.
- [ ] Run required project, pinned Spinel, Rails, analyzer, mutation, and tracker gates; record results in `## Answer`.
- [ ] Add an ADR and link this child from issue 97; keep issue 97 open while other manifest gaps remain.

## Execution and stop condition

Claimed from issue 97's residual frontier after ticket 134. Use pinned Spinel 2026.09.12 and Flay 2.14.4. Reuse the class-body declaration path and do not execute application code.
