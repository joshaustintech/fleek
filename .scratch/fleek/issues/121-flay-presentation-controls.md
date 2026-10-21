# 121: Inventory and support Flay presentation controls

**What to build:** Match useful behavior for Flay's `--summary`, `--diff`, `-#`, and `--verbose` presentation controls while preserving Fleek's report contract.

**Part of:** Ticket 23 — Flay controls.

**Blocked by:** 58 (resolved); 115 (resolved).

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [x] Verify each option's output-stream and analysis-score effects against pinned Flay 2.14.4; record the `--diff` dependency limitation.
- [x] Decide and document which presentation effects fit Fleek's stable report format; keep deliberate unsupported differences explicit.
- [x] Add public evidence for supported behavior and run relevant gates and reviews.

## Answer

Pinned Flay 2.14.4 reported score 48 for all four options. `--summary` replaced groups with per-file score; `-#` removed numbering; `--verbose` wrote progress to stderr; `--diff` printed `ruby2ruby is required for diff` because that optional dependency is absent, so no diff was rendered. Fleek accepts `-#` as a no-op because its report groups are already unnumbered, including in combined Flay/Reek runs. It rejects `--summary`, `--diff`, and `--verbose` before stdout output to preserve report v1's layout and stream contract. See [ADR 0237](../../../docs/adr/0237-keep-flay-presentation-options-out-of-report-v1.md).

Verification used pinned Spinel `2026.09.12` (`112bae85c1a2`): the public contract passed; full `make check JOBS=8` passed with 78 workers, eight mutation workers, all mutants caught, Flay score 1008, and Reek 0 warnings; `make ticket-check` passed with 138 documents; and `git diff --check` passed. Focused mutation `Flay numbering no-op support` was caught.
