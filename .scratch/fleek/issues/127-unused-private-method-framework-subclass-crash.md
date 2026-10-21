# 127: Prevent UnusedPrivateMethod crash on framework superclass

**What to fix:** Explicit `UnusedPrivateMethod` analysis of a simple `ActiveJob::Base` subclass must return a truthful report instead of crashing.

**Part of:** Ticket 24 — shared-syntax analyzer parity.

**Blocked by:** 61; 96; 115 — Verify harness savings before resuming feature work.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded case

`test/fixtures/unused_private_method_framework_subclass.rb` contains only an empty `FrameworkJob < ActiveJob::Base` class. With Reek 6.6.0, `bundle exec reek --smell UnusedPrivateMethod --no-progress test/fixtures/unused_private_method_framework_subclass.rb` exits 0 with no findings. `build/fleek --checks reek:UnusedPrivateMethod test/fixtures/unused_private_method_framework_subclass.rb` exits 139 (SIGSEGV) with no report. The same crash reproduces on the pinned Rails corpus at `app/jobs/application_job.rb`.

## Acceptance criteria

- [x] Fleek no longer crashes on the minimal fixture; preserve Reek's clean result and complete 1/1 source coverage when no unsupported detector behavior is present.
- [x] Add a public CLI regression and a non-equivalent mutation proving the superclass case is handled.
- [x] Verify all selected source accounting and exit status; do not convert other unsupported inputs into clean results.
- [x] Record pinned tool identities, exact commands, full gates and an ADR decision in `## Answer`.

## Answer

The crash came from passing an empty class's null `body` pointer to `PM_NODE_TYPE_P`. `fleek_unused_private_collect_methods` now treats a null body as an empty, supported class before checking the node type. Other non-null unsupported bodies still return incomplete coverage. ADR 0243 records the decision.

The public CLI contract compares the minimal `FrameworkJob < ActiveJob::Base` fixture with Reek 6.6.0: both return exit 0 with no findings; Fleek reports `1 selected; 1 analyzed; 0 failed; 0 excluded`, `Status: complete`, and empty stderr. The non-equivalent mutation that changes the null-body case to unsupported was caught. Probe evidence: changing the superclass to `Object` still crashed with an empty body, while adding one public method made the class complete; both isolate the null-body shape.

Pinned identities: Spinel 2026.09.12 (tag object `00ce35bb96e489620358ffbc48791001a73778a5`, source `112bae85c1a25fc5399009a849f805bfe691426b`), Flay 2.14.4, Reek 6.6.0.

Verification: `make check JOBS=8` passed 78 workers with 8 mutation workers; all mutations were caught, Flay score was 1008, and Reek reported 0 warnings. `gmake -C /private/tmp/fleek-spinel-pinned-rebuild check` passed 3,596 tests, allocation and inference checks, and `spin-e2e`. `make ticket-check` validated 138 documents; `git diff --check` passed. No child tickets remain for this slice; parent Ticket 24 remains open for other detector parity work.

## Execution and stop condition

Use pinned Spinel 2026.09.12, Flay 2.14.4 and Reek 6.6.0. Start with the bounded public case, then implement only the cause of this crash through the existing native analysis path. Keep the unrelated partial Rails source shapes tracked in tickets 97–101. Before a code commit, run the complete native/project/analyzer/mutation gates required by `AGENTS.md` and record exclusions faithfully.
