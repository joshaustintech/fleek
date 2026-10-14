# 04: ClassVariable scope and occurrence parity

**What to build:** ClassVariable findings correctly group names and occurrence lines within their reference-defined class/module contexts. Parent specification: Smell analysis and source workflow.

**Blocked by:** 03 First ClassVariable finding.

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] Reads and assignments contribute the exact reference occurrence lines; repeated use emits one finding per name/context, and different names remain separate.
- [ ] Nested classes/modules do not leak occurrences into their enclosing context.
- [ ] Execute and record reference behavior for method use, top-level use, reopening, and singleton contexts before claiming support; implement supported cases or reject remaining contexts explicitly.
- [ ] CLI findings preserve reference names, messages, contexts, ordering, and locations over these shared-syntax fixtures.
- [ ] Scope/grouping mutations are detected, and all required gates remain passing.
