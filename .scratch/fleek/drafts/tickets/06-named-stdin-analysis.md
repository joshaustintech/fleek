# 06: Named stdin analysis

**What to build:** Editors and agents send source through explicit stdin selection with a required filename and receive meaningful findings and configuration origin. Parent specification: Smell analysis and source workflow.

**Blocked by:** 05 Explicit files and directory scans.

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] Explicit stdin requires a source filename; missing origin fails before analysis with exit 1.
- [ ] The same supported source through a file and named stdin produces equivalent findings, locations, and completion status.
- [ ] Invalid stdin source produces a diagnostic attributed to its supplied origin and exits 1.
- [ ] Empty stdin and mixed stdin/path invocation have documented, tested behavior; neither falls back to a directory scan.
- [ ] Origin is available for later configuration scoping without loading or executing source. Origin/status mutations are detected and required gates pass.
