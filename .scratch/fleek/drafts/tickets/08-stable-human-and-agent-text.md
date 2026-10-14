# 08: Stable human and agent text

**What to build:** Humans and agents can read a deterministic text report and distinguish findings, diagnostics, checks run, scope limits, and incomplete analysis without guessing. Parent specification: Smell analysis and source workflow.

**Blocked by:** 04 ClassVariable scope and occurrence parity; 06 Named stdin analysis.

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] Establish and document stable text fields, check identifiers, context/location representation, escaping, section order, and completion/coverage conventions from the accepted CLI contract.
- [ ] Filename/message punctuation, whitespace, newlines, and non-ASCII examples do not make fields ambiguous; terminal color is never needed to understand meaning.
- [ ] Keep findings and summaries on stdout; diagnostics on stderr. A mixed failed/good input report explicitly identifies partial results and exits 1.
- [ ] Repeated runs over identical source/settings produce identical report semantics and stable ordering.
- [ ] Help and version output explain selected coverage, reference identities, and unsupported capabilities. Unsupported machine formats fail explicitly.
- [ ] Verify report interpretation through observable output checks; escaping/order/completion mutations are detected with required gates passing.
