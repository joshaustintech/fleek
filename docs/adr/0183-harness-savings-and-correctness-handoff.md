# ADR 0183: Accept the measured harness handoff

## Status

Accepted

## Context

Tickets 106–114 changed scheduling, staging, contract precompile, reuse, and focused contract mappings. Ticket 115 requires comparable post-change evidence before the existing analyzer feature frontier resumes. Standards/spec review also found and tracked two residuals, resolved as tickets 116–117.

## Decision

Compare the baseline and final full gate at `JOBS=4`, reporting cache-disabled and warm-cache results separately. Use three focused cold and warm repetitions for each ranked mutation label. Preserve the existing task graph and resume feature ticket 48 after the handoff; keep README completion last. Report measured differences as observations, not guarantees.

## Evidence

On the pinned Spinel 2026.09.12, Flay 2.14.4, Reek 6.6.0 environment, baseline `make check JOBS=4` took 452.93s with 56 workers. At final HEAD `b02416cab212bf3a8fe8b579380c682830864c20`, cache-disabled full check took 402.49s (61 workers, 49 contracts compiled), and warm-cache full check took 377.99s (61 workers, 49 restored). The cold comparison is 50.44s (11.1%) lower; the warm-to-baseline observation is 74.94s (16.5%) lower. Both full runs caught all 273 unchanged mutation labels. Three cold/warm focused runs per ranked label all caught their mutations; medians and contract execution avoided are recorded in issue 115. Flay score 0, Reek warnings 0, and 126 ticket documents valid. Scheduler, precompile-budget, staging, and cache regression contracts pass. Tickets 106–117 are resolved. Pinned Spinel source commit `112bae85c1a25fc5399009a849f805bfe691426b` and tag object `00ce35bb96e489620358ffbc48791001a73778a5`.

## Consequences

The harness work has reproducible correctness and cost evidence, with full-gate timing variance stated plainly. Existing feature tickets may resume without changing their IDs, parent claims, acceptance criteria, or blockers. README tickets remain last.
