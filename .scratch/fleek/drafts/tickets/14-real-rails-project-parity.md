# 14: Real Rails project parity

**What to build:** Developers can see reproducible evidence that Fleek's selected checks work on a small actual Rails project, beyond toy fixtures. Parent specification: Language support and real-project parity.

**Blocked by:** 13 Ruby 4.0 and Spinel extension findings.

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] Select an actual small Rails project, record source revision/manifest, required notices, and supported settings; do not replace it with generated toy source or edit findings out of the corpus.
- [ ] Run Fleek and unchanged originals over identical selected source/settings in the locked reference environment.
- [ ] Compare supported findings, locations, grouping, scores, and order; retain deliberate CLI/status exceptions and separately labeled extension cases.
- [ ] All requested supported inputs/checks complete, or the release remains blocked with the exact capability gap documented. No unexplained parity difference is waived as a baseline.
- [ ] Discovered faults become minimal failing regressions and small passing slices with mutation proof and required gates.
- [ ] Record executable commands, versions, outputs, statuses, and capability limits so a fresh agent can reproduce the receipt.
