# ADR 0017: Flay mass thresholds, groups, and file scores

## Status

Accepted for the bounded structural group implementation.

## Context

Ticket 09 matched default Flay groups only at the fixed mass threshold of 16. Users need to select a Flay threshold explicitly and see the same group selection and weighted score as pinned Flay 2.14.4. Ticket 11 adds a bounded group from exactly two supported parameterless top-level methods, whether they occur in one file or across files.

## Decision

Accept `--mass MASS` for `flay:StructuralDuplication`, defaulting to Flay's 16. MASS must be a decimal integer from 3 through the native interface's maximum. Values below 3 can make nested bare-call nodes eligible, but this slice emits only method-level groups; accepting them could report an incomplete score. Missing, malformed, below-range, and out-of-range values therefore fail before source analysis. Other Flay options remain explicitly unsupported. The report records the selected threshold.

Apply the selected threshold to the AST-derived `:defn` mass and retain Flay's similar and identical weighting. Report the total score and allocate half of a two-occurrence group score to each file containing an occurrence. Sort requested files before combining their source, so group locations and per-file score rows are deterministic and match Flay's file/line ordering.

Flay's Prism adapter drops a file whose parse result is a lone top-level `:defn` during candidate traversal. Cross-file fixtures therefore include a top-level `nil` expression after the method, making each file parse to an analyzable top-level block; this does not add eligible duplication nodes. Fleek collects exactly two supported top-level methods from the combined source and fails closed when either has unsupported syntax or when there are more candidates. Top-level statements other than methods and this `nil` container expression are rejected, so nested class/module methods cannot be silently omitted from an otherwise complete report.

The supported grammar has only whole-method candidates plus bare zero-argument call and integer-literal statements. The minimum mass of 3 keeps child nodes below threshold, so nested candidate pruning has no effect in this slice. Nested class/module methods are explicitly unsupported: a pinned reference fixture confirms Flay reports their group, while Fleek reports incomplete analysis. When Flay reports a group from the selected files but any requested file fails discovery/read, Fleek preserves the group and marks coverage incomplete with exit 1. Findings return 2 when analysis is complete, while Flay 2.14.4 returns 0.

## Consequences

The locked reference test compares the same source at thresholds 15, 16, and 17: the mass-16 group is included at 15 and 16, and excluded at 17. Identical groups preserve their additional occurrence multiplier. Invalid settings fail honestly. Multiple groups, nested candidate syntax, fuzzy matching, and non-top-level methods remain unsupported and must not imply complete analysis.

## Evidence

`test/duplication_contract.rb` compares the three thresholds and similar, identical, clean, unsupported, cross-file, and nested-scope results against Flay 2.14.4, including reversed input order, per-file scores, and a failed requested file. The single-method-per-file probe also records that Flay drops a lone top-level `:defn`; the accepted fixture shape matches parser traversal. Mutation cases target structural equality, inclusive threshold boundary, identical multiplier, total score, cross-file collection, nested-scope rejection, source mapping, and deterministic ordering. The CLI contract checks invalid and unsupported low mass values, report contributions, and explicit `--mass` help text.

The mutation harness removes its previous compiled executable before building each mutant. A failed NUL mutation exposed that same-second source and binary timestamps could otherwise make `make` reuse the unmutated executable, producing false survival. The forced rebuild makes each mutation result evidence about the current source.
