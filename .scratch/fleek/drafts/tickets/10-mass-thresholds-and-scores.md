# 10: Mass thresholds and duplication scores

**What to build:** Developers receive correct duplication mass selection, identical-group weighting, and total/per-file scores on the supported group shapes. Parent specification: Structural duplication and combined analysis.

**Blocked by:** 09 Structural duplication groups.

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] Execute locked-reference cases to establish exact mass semantics; preserve default mass 16 and supported explicit mass selection.
- [ ] Immediately-below, at, and above threshold cases select exactly the reference nodes.
- [ ] Identical and structurally similar groups retain the correct occurrence multiplier, group score, totals, and applicable per-file contributions.
- [ ] Invalid mass settings fail before analysis; unsupported group/AST forms still fail honestly rather than disappearing.
- [ ] CLI scores and statuses match the selected contract; mass-boundary/multiplier/total mutations are detected and required gates pass.
