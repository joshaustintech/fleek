# 05: Explicit files and directory scans

**What to build:** Developers analyze explicitly named files or directories and can tell which requested sources were analyzed or failed. Parent specification: Smell analysis and source workflow.

**Blocked by:** 03 First ClassVariable finding.

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] Discover Ruby source recursively from directory arguments; skip hidden directories and do not follow directory symlinks. Document file/symlink and repeated-path handling before claiming a stable discovery contract.
- [ ] Explicit non-Ruby inputs and missing/unreadable requested inputs produce clear errors rather than disappearing from the report.
- [ ] Good files still produce findings when another file fails; overall completion is incomplete with exit 1 and failed sources identified.
- [ ] Define and test empty-source-set behavior so no discovered files is distinguishable from analyzed clean files; do not invent successful coverage.
- [ ] Findings preserve deterministic source locations, and discovery/error-precedence mutations are detected with required gates passing.
