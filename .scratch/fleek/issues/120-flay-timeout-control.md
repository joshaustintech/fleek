# 120: Support Flay timeout control

**What to build:** Match Flay 2.14.4 `--timeout TIME` analysis behavior through Fleek's native parser path.

**Part of:** Ticket 23 — Flay controls.

**Blocked by:** 58; 115.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [x] Compare zero, positive, malformed, and negative timeout values against pinned Flay; record timeout units and failure behavior.
- [x] Preserve selected-source coverage and report incomplete analysis when native parsing cannot finish within the requested budget.
- [x] Add public contracts and non-equivalent mutations, then run full required gates.

## Answer

Added explicit `--timeout SECONDS` support to Flay selections. Flay 2.14.4 accepts integer seconds, treats zero as no timeout, and skips a file with a warning for a negative value. Fleek validates malformed values before analysis and uses the last repeated value. Negative values produce a truthful incomplete report (exit 1), preserving Fleek's normalized status contract. Fleek applies timeouts only when explicitly requested; it does not apply Flay's implicit 10-second default. This measured-overhead tradeoff is recorded in [ADR 0234](../../../docs/adr/0234-keep-untimed-flay-runs-on-direct-path.md).

Prism parsing runs in native C and cannot be safely interrupted inside the current process. Positive budgets therefore supervise an isolated Fleek worker; timeout kills that worker and reports every included selected source as failed, with no partial findings. The budget multiplies by the included source count to preserve Flay's per-file time allowance at the total-run boundary. Successful worker output and exit status pass through unchanged. The public contract covers zero, positive, malformed, negative, repeated values and combined coverage; focused mutations caught both loss of negative-timeout reporting and false timeout classification.

The remaining per-file behavior differs when only one of multiple sources exceeds its budget: Flay continues with other files, while Fleek currently reports the interrupted selection as incomplete. This is tracked by [issue 128](128-flay-per-file-timeout-continuation.md), and the parent Flay control ticket remains open until it resolves. See [ADR 0233](../../../docs/adr/0233-isolate-flay-timeout-analysis.md).

Validation: `/usr/bin/time -p env ... make check JOBS=4` passed all 73 workers and all four mutation workers (no surviving non-equivalent mutants); final measured wall time was 784.83s. `make flay reek` reports the pre-existing Flay score of 1008 and zero Reek warnings; the timeout contract adds no Flay score. `make ticket-check` validated 138 documents and `git diff --check` passed. The pinned Spinel `gmake -C /private/tmp/fleek-spinel-pinned-rebuild-20261021 check` passed 3,596 tests, zero failures/errors, alloc-report, inference, and spin-e2e. Focused mutations caught negative-timeout reporting, actual worker interruption, and Flay option applicability. Full-gate timing is tracked separately in [issue 129](129-flay-timeout-supervisor-overhead.md).
