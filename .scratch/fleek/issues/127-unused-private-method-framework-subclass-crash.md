# 127: Prevent UnusedPrivateMethod crash on framework superclass

**What to fix:** Explicit `UnusedPrivateMethod` analysis of a simple `ActiveJob::Base` subclass must return a truthful report instead of crashing.

**Part of:** Ticket 24 — shared-syntax analyzer parity.

**Blocked by:** 61; 96; 115 — Verify harness savings before resuming feature work.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded case

`test/fixtures/unused_private_method_framework_subclass.rb` contains only an empty `FrameworkJob < ActiveJob::Base` class. With Reek 6.6.0, `bundle exec reek --smell UnusedPrivateMethod --no-progress test/fixtures/unused_private_method_framework_subclass.rb` exits 0 with no findings. `build/fleek --checks reek:UnusedPrivateMethod test/fixtures/unused_private_method_framework_subclass.rb` exits 139 (SIGSEGV) with no report. The same crash reproduces on the pinned Rails corpus at `app/jobs/application_job.rb`.

## Acceptance criteria

- [ ] Fleek no longer crashes on the minimal fixture; preserve Reek's clean result and complete 1/1 source coverage when no unsupported detector behavior is present.
- [ ] Add a public CLI regression and a non-equivalent mutation proving the superclass case is handled.
- [ ] Verify all selected source accounting and exit status; do not convert other unsupported inputs into clean results.
- [ ] Record pinned tool identities, exact commands, full gates and an ADR decision in `## Answer`.

## Execution and stop condition

Use pinned Spinel 2026.09.12, Flay 2.14.4 and Reek 6.6.0. Start with the bounded public case, then implement only the cause of this crash through the existing native analysis path. Keep the unrelated partial Rails source shapes tracked in tickets 97–101. Before a code commit, run the complete native/project/analyzer/mutation gates required by `AGENTS.md` and record exclusions faithfully.
