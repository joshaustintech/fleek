# 23: Flay analysis-control parity

**What to build:** Flay-specific settings and analysis-affecting controls produce the same structural duplication result and selected source set as pinned Flay 2.14.4.

**Status:** resolved
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [x] Inventory the pinned Flay 2.14.4 analysis-affecting options and path controls, then match their behavior in Fleek.
- [x] Match mass thresholds, pruning modes, fuzzy detection, parser mode selection, `.flayignore`, and relevant path expansion behavior against the pinned reference; distinguish presentation-only options from analysis controls.
- [x] Validate invalid, repeated, conflicting, and check-inapplicable controls before analysis with clear diagnostics.
- [x] Keep Fleek report formatting and documented exit-code normalization while comparing semantic results.
- [x] Compare public CLI behavior against unchanged Flay 2.14.4 and protect controls and precedence with mutation checks.

## Answer

Pinned Flay 2.14.4 inventory and bounded parity evidence are recorded in tickets 10 and 53–59. Fleek matches the documented analysis and source-selection cases, with unsupported parser shapes reported incomplete and report status normalized to Fleek's contract. Tickets 120 and 128 resolve explicit timeout handling and per-file continuation (ADRs 0233 and 0236). Ticket 121 accepts `-#` as a no-op and keeps `--summary`, `--diff`, and `--verbose` unsupported to preserve report v1 (ADR 0237). Ticket 59's control table and all child evidence are reconciled; no unresolved ticket23 residual remains.

Verification on pinned Spinel `2026.09.12` (`112bae85c1a2`): `make check JOBS=8` passed with 78 workers, eight mutation workers, all mutants caught, Flay score 1008, and Reek 0 warnings; `make ticket-check` validated 138 documents; `git diff --check` passed. The pinned upstream Spinel build and suite passed 3,596 tests plus allocation, inference, and spin-e2e gates during ticket 128. Child evidence remains linked at tickets 59, 120, 121, and 128.
