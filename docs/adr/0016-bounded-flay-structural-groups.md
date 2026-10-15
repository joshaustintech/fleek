# ADR 0016: Bounded Flay structural groups

## Status

Accepted for the first native duplication slice.

## Context

Flay 2.14.4's default detector groups RubyParser S-expression trees by structural hash, applies a default mass threshold of 16, prunes covered subtrees, and weights identical groups more heavily. Treating source text or token counts as structures would change the rule. The pinned Prism adapter exposes Ruby AST nodes but does not provide Flay's RubyParser S-expression translation.

## Decision

Implement `flay:StructuralDuplication` only for one Ruby source file containing exactly two parameterless top-level methods. Each method body may contain bare zero-argument call statements or integer literal statements. Any other candidate syntax, extra top-level node, extra input, or requested Flay option fails with incomplete status and a diagnostic. This ticket makes the check separately selectable; it does not implement combined check selection or combined report sections, which remain Ticket 12.

For this grammar, the only possible Flay candidate at the default mass is the method's `:defn` tree: its mass is two nodes for `:defn` and `:args`, plus one node per body statement. Each body statement is a one-node `:call` or `:lit` tree. Equal statement-kind sequences therefore match Flay's structural hash; method/call names and integer values are excluded from structural equality. They remain part of S-expression equality, which distinguishes similar from identical groups. There are no eligible child subtrees at mass 16, so Flay's normal subtree pruning cannot remove another candidate.

The report keeps Flay's weighted group mass and score, locations, node type, and similar/identical classification. A two-location similar group scores `mass * 2`; an identical group scores `mass * 2 * 2`. Fleek follows the accepted cross-tool status contract: complete findings return 2, while Flay 2.14.4 returns 0 for findings. ADR 0002 records this deliberate CLI difference.

Fuzzy, liberal, diff, plugins, custom mass thresholds, multi-file groups, and other AST syntax remain unsupported. The check never reports complete analysis for an unsupported input. Ticket 09's reference fixtures exercise the default threshold on exact supported shapes; just-below/at/above selection and explicit mass settings are Ticket 10, while cross-file groups and pruning are Ticket 11.

## Consequences

This proves genuine default Flay grouping on a narrow, fully understood syntax subset while leaving general AST translation, threshold boundaries, combined reporting, and multi-file pruning to their ordered tickets. Ticket 10 extends mass selection and scoring; Ticket 11 adds cross-file groups and default pruning; Ticket 12 combines selected analyzers in a single report.

## Evidence

The locked Flay 2.14.4 CLI reports two renamed 14-statement method bodies with changed integer literals as one similar `:defn` group at lines 1 and 18, weighted mass/score 32. Two identical method bodies produce mass/score 64. Replacing one body statement with a literal changes the tree shape and yields score 0. The compiled CLI contract checks these reports, statuses, locations, an unsupported class input, and a rejected fuzzy request.
