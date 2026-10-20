# ADR 0189: Preserve composed cross-file pruning

## Status

Accepted

## Context

Ticket 51 compares composed begin/rescue/ensure methods across separate source files in top-level and class scopes. Flay 2.14.4 prunes identical top-level methods to an `:ensure` group across files, while retaining the enclosing method group when those methods are in one file. For class scopes, Flay reports matching `:defn` groups, including a second independent method group, rather than a `:class` group. The previous Fleek path did not retain these cross-file pruning choices.

## Decision

Pass source-file byte offsets from the existing source map into the native analyzer and retain each candidate method's source offset. Apply composed exception subtree selection and scoped class pruning only when the matched candidate pair comes from different source files. Preserve the enclosing method behavior for a same-file pair even when the analysis includes an unrelated second file. Keep the existing partial-result path when a sibling class has unsupported syntax; retain findings from the supported candidates.

Use the largest matching composed exception subtree among paired candidates and account for the three RubyParser wrapper nodes Flay includes per `:ensure` member but Prism does not expose in that subtree. Continue to use the existing Flay ordering and source-map translation for report locations.

## Evidence

Pinned Flay 2.14.4 reports the top-level cross-file regexp pair as identical `:ensure`, mass 32, score 64, at line 3 in each file. Class cross-file inputs report a similar `:defn` at mass/score 32 and an identical `:defn` at mass 6, score 12, with total score 44. Fleek matches both reports in default and liberal mode and keeps canonical path/line ordering when input order is reversed. The complete normalized Flay records and exact Fleek group lines are asserted, including group count and order. A same-file regexp pair whose methods are separated by a comment containing the former sentinel, plus an unrelated second input, remains the identical `:defn` finding at mass 36, score 72. With an unsupported sibling class, Fleek retains both method findings, reports the same score 44, and marks both selected files failed/incomplete; the warning appears on stderr only. The focused public contract and non-equivalent selection/pruning mutations pass.

## Consequences

The parity correction is limited to composed begin/rescue/ensure candidate pairs from different source files. Same-file pruning and unrelated scope groups retain their existing behavior. Unsupported syntax remains explicitly incomplete, and parent Tickets 22/43 remain open pending their remaining children.
