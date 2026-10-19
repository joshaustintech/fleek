# 47: Bound generated contract concurrency inside check workers

**What to fix:** Keep generated Flay parity and mapped mutation contracts reliable and efficient when the check runner executes isolated workers.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

- [x] Measure generated-contract process fan-out and runtime in direct and isolated-worker modes.
- [x] Bound nested analyzer concurrency so a high outer `JOBS` value does not multiply into excessive child processes.
- [x] Map the optional-keyword-count mutation to a focused public contract so an unrelated positional-count assertion cannot mask its result.
- [x] Verify the generated contract and full test, mutation, Flay, and Reek gates; record before/after evidence.

## Answer

The generated contract now caps its nested analyzer workers at two only when the outer check runner provides an isolated temp root; direct runs retain the requested `JOBS`. On the same generated input, direct runs measured 5.09 s at 8 workers, 8.71 s at 2, and 13.06 s at 1. The isolated-run path measured 8.92 s with `JOBS=8` and the cap, reducing potential fan-out from 16 analyzer processes to 4 while the outer runner is already scheduling check workers.

The optional-keyword-count mutant now uses a focused public contract, so its expected failure cannot be masked by the earlier positional-count case. The generated contract writes a compact inventory/result report inside each mutation worker’s isolated temp root, satisfying the harness isolation check; direct runs delete it. Focused mutations and the full 60-worker `make check JOBS=8` pass. Reek reports zero warnings. Flay reports its existing score 64 from duplicate check/test constant arrays; this change adds no Flay findings.

See [ADR 0171](../../../docs/adr/0171-bound-generated-contract-work.md).
