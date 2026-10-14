# 11: Pruning and multi-file duplication

**What to build:** Duplication findings across files preserve Flay's default pruning, surviving groups, locations, and ordering. Parent specification: Structural duplication and combined analysis.

**Blocked by:** 10 Mass thresholds and duplication scores. Explicit multi-file discovery is already delivered by ancestor ticket 05.

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] Nested duplicate groups and covered subtrees produce the exact surviving default-pruning groups from unchanged Flay.
- [ ] Cross-file groups include all reference-equivalent locations and correct scores; clean files do not invent groups.
- [ ] Ties, location ordering, and report grouping are deterministic and reference-equivalent within the duplication section.
- [ ] Failed requested files mark the report incomplete with exit 1; remaining groups are clearly partial rather than scored as complete global analysis.
- [ ] Execute minimal nested and multi-file regression cases; pruning/location/order mutations are detected with required gates passing.
