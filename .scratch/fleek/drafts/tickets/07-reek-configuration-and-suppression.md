# 07: Reek configuration and suppression

**What to build:** Existing supported Reek settings, scope rules, exclusions, and suppression comments control native ClassVariable analysis faithfully. Parent specification: Smell analysis and source workflow.

**Blocked by:** 04 ClassVariable scope and occurrence parity; 06 Named stdin analysis.

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] Import supported Reek YAML with reference-equivalent explicit-file, discovery, precedence, detector, and directory-scope behavior; select/verify any native YAML solution through real pinned-compiler execution.
- [ ] ClassVariable enablement, supported exclusions, and suppression comments produce unchanged-reference-equivalent findings on shared syntax.
- [ ] Named stdin uses the supplied origin for source scope; explicit-file and directory exclusion behavior matches the supported reference policy.
- [ ] Malformed/unsupported settings and unsupported enabled/default checks fail before any analysis, identifying the offending capability. No unified configuration format is introduced.
- [ ] Reek exclusions affect smell analysis only; preserve their scope for the later combined mode.
- [ ] Precedence, suppression, enablement, and exclusion mutations are detected; full native and zero-finding quality gates pass.
