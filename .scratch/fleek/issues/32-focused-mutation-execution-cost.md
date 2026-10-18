# 32: Avoid empty workers in focused mutation runs

**What to fix:** A focused mutation run creates and initializes workers that cannot contain any selected mutation, and compiles a broad public contract for a narrow behavior change.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Reproduction

- Pinned Spinel `2026.09.12`.
- Command: `FLEEK_MUTATIONS='Flay method for loop candidates' SPINEL=/private/tmp/fleek-spinel-2026.09.12/spinel SPINEL_ROOT=/private/tmp/fleek-spinel-2026.09.12 make mutation JOBS=8`.
- Baseline: 32.299 seconds; eight worker copies of the 95 MB checkout; seven workers had no selected mutant.
- A separate `cp -R . /tmp/fleek-copy-baseline` took 0.632 seconds for 95 MB.

## Diagnosis

Three causes were ranked. (1) Focused runs still launched the configured worker count; predicted they would report empty workers and spend time copying worker checkouts. Confirmed: the one-label run reported eight workers, only one of which executed a mutation. (2) The mutation mapped to the 1,118-line duplication contract; predicted a small public contract would reduce compile work. Confirmed by moving the candidate comparison into a dedicated CLI contract. (3) Mutant native compilation dominates all remaining time; this is still required for an isolated source mutant and was not removed.

PIT's coverage-guided selection and runtime-aware ordering informed the policy. Fleek uses its explicit mutation-to-public-contract map as the deterministic relevance index; no agent judgment or Java bytecode model participates in verdicts.

## Resolution

Focused runs now cap mutation workers at the number of unique selected labels and assign selected labels in registry order. In `check` mode, test, reference, Flay, and Reek concurrency stays at the configured `JOBS` value. The `for` loop mutant uses a small Flay-comparison contract. The repeated mutation-only command passed in 10.138 seconds, compiled one shared contract, used one mutation worker, and caught the mutant. ADR 0126 records the policy. The first full gate caught four Reek findings and a stale local-write mutation target after the new AST node insertion; both were fixed.

## Resolution

The filtered full check passed with all 26 public contracts, one selected mutation worker, reference checks, Flay score 0, and Reek warnings 0 in 100.24 seconds. The unfiltered pinned `make -B check JOBS=8` passed all 27 shared mutation contracts, every configured mutation, all 26 public contracts, Flay score 0, and Reek warnings 0 in 306.15 seconds. Eight mutation workers ran while the check runner preserved `JOBS=8` for the other gates. The focused mutation path dropped from 32.299 seconds to 10.138 seconds with the same caught mutation.
