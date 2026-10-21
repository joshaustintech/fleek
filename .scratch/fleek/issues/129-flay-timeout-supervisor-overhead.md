# 129: Avoid timeout supervisor overhead on untimed Flay runs

**What to fix:** Flay timeout support must not spawn a worker and timer when the user did not request a timeout.

**Part of:** Ticket 23 — Flay analysis-control parity.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Reproduce and record timing for identical public Flay inputs with omitted timeout and explicit `--timeout 0`.
- [x] Omitted timeout preserves the existing direct CLI path; positive explicit budgets retain isolated cancellation.
- [x] Focused timeout contracts and mutations pass; full gate runtime returns near the recorded 402.49-second baseline without weakening checks.
- [x] Record the timing and decision in [ADR 0234](../../../docs/adr/0234-keep-untimed-flay-runs-on-direct-path.md).

## Answer

On the local macOS arm64 host, the seven-run median probe used `build/fleek --checks flay:StructuralDuplication test/fixtures/duplication_class_methods_rails_pair.rb`, then repeated with `--timeout 0`. Untimed invocation measured 8.052 ms before and 3.701 ms after keeping omitted timeout on the direct path. Explicit zero measured 3.689 ms before and 3.486 ms after. The initial `/usr/bin/time -p env ... make check JOBS=4` after ticket 120 passed 73 workers and four mutation workers in 784.83s, compared with ticket 115's 402.49s cache-disabled result at 61 workers. Profiling found that 59 mutations each reran the full 49-second default-argument/Reek contract. Mutation runs now select the smallest mapped public assertions while ordinary test runs retain the full contract; ADR 0235 records this boundary. The final pinned full gate, `/usr/bin/time -p env PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin BUNDLE_PATH=/private/tmp/fleek-bundle SPINEL=/private/tmp/fleek-spinel-pinned-rebuild-20261021/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild-20261021 make check JOBS=8`, passed 77 workers and eight mutation workers in 351.44s. All 335 mutation labels were caught. This is below the 402.49-second comparison without removing ordinary contract assertions or mutation checks. The timeout path decision and its omitted-default limitation are recorded in ADR 0234.
