# 129: Avoid timeout supervisor overhead on untimed Flay runs

**What to fix:** Flay timeout support must not spawn a worker and timer when the user did not request a timeout.

**Part of:** Ticket 23 — Flay analysis-control parity.

**Status:** claimed
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Reproduce and record timing for identical public Flay inputs with omitted timeout and explicit `--timeout 0`.
- [x] Omitted timeout preserves the existing direct CLI path; positive explicit budgets retain isolated cancellation.
- [ ] Focused timeout contracts and mutations pass; full gate runtime returns near the recorded 402.49-second baseline without weakening checks.
- [x] Record the timing and decision in [ADR 0234](../../../docs/adr/0234-keep-untimed-flay-runs-on-direct-path.md).

## Answer

On the local macOS arm64 host, the seven-run median probe used `build/fleck --checks flay:StructuralDuplication test/fixtures/duplication_class_methods_rails_pair.rb`, then repeated with `--timeout 0`. Untimed invocation measured 8.052 ms before and 3.701 ms after keeping omitted timeout on the direct path. Explicit zero measured 3.689 ms before and 3.486 ms after. The exact full-gate command was `/usr/bin/time -p env PATH=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin:$PATH SPINEL=/private/tmp/fleek-spinel-pinned-rebuild-20261021/bin/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-pinned-rebuild-20261021 BUNDLE=/Users/josh/.local/share/mise/installs/ruby/3.4.9/bin/bundle BUNDLE_PATH=/private/tmp/fleek-bundle make check JOBS=4`; it passed all 73 workers and four mutation workers in 784.83s, compared with ticket 115's 402.49s cache-disabled result at 61 workers. Focused timeout contracts and mutations pass, but the full-gate runtime remains above baseline; keep this issue open and resolve the measured regression before advancing ticket 23. The decision and omitted-default limitation are recorded in ADR 0234.
