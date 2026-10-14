# 13: Ruby 4.0 and Spinel extension findings

**What to build:** Both implemented checks analyze documented Ruby 4.0 and pinned Spinel examples with reviewed behavior and original locations, while preserving shared-syntax parity. Parent specification: Language support and real-project parity.

**Blocked by:** 12 Combined report and separate exclusions.

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] Publish the exact supported Ruby 4.0 and pinned Spinel syntax boundary; exercise actual checks rather than treating successful parsing as successful analysis.
- [ ] Unchanged original tools remain the shared-syntax references. Reference rejection is a recorded boundary, never a clean result.
- [ ] Review and record expected extension findings, scope, duplication shape, comments/suppression, and original locations; label extension behavior separately from stock-Reek parity.
- [ ] If a modified reference is used, independently lock it and validate agreement with the unchanged reference over common grammar before relying on it.
- [ ] Requires, FFI declarations, and analyzed side effects are not executed or loaded. Unsupported syntax yields incomplete/error output and exit 1.
- [ ] Extension location/traversal mutations are detected; supported common-grammar comparisons and required gates pass.
