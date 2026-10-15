# ADR 0017: Flay mass threshold and single-file scores

## Status

Accepted for the supported single-file structural group.

## Context

Ticket 09 matched default Flay groups only at the fixed mass threshold of 16. Users need to select a Flay threshold explicitly and see the same group selection and weighted score as pinned Flay 2.14.4. The current grammar admits exactly one group in one source file; accepting unsupported shapes or multiple sources would make the total and per-file figures incomplete.

## Decision

Accept `--mass MASS` for `flay:StructuralDuplication`, defaulting to Flay's 16. MASS must be a decimal integer from 3 through the native interface's maximum. Values below 3 can make nested bare-call nodes eligible, but this slice emits only method-level groups; accepting them could report an incomplete score. Missing, malformed, below-range, and out-of-range values therefore fail before source analysis. Other Flay options remain explicitly unsupported. The report records the selected threshold.

Apply the selected threshold to the AST-derived `:defn` mass and retain Flay's similar and identical weighting. Report both the total score and the single analyzed file's contribution. The contribution equals the total because this supported slice contains one group and one source file. Fleek keeps the cross-tool result status contract: findings return 2, while Flay 2.14.4 returns 0.

## Consequences

The locked reference test compares the same source at thresholds 15, 16, and 17: the mass-16 group is included at 15 and 16, and excluded at 17. Identical groups preserve their additional occurrence multiplier. Invalid settings fail honestly. Multiple files, multiple groups, their pruning, and aggregated per-file contributions remain outside this slice and are handled by later tickets.

## Evidence

`test/duplication_contract.rb` compares those three thresholds and the similar, identical, clean, and unsupported results against Flay 2.14.4. Mutation cases target the inclusive threshold boundary, identical multiplier, and total score. The same CLI contract checks invalid and unsupported low mass values, per-file report contributions, and explicit `--mass` help text.

The mutation harness removes its previous compiled executable before building each mutant. A failed NUL mutation exposed that same-second source and binary timestamps could otherwise make `make` reuse the unmutated executable, producing false survival. The forced rebuild makes each mutation result evidence about the current source.
