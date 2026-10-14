# 12: Combined report and separate exclusions

**What to build:** One native invocation runs selected duplication and ClassVariable analysis with two clear report sections, independent exclusion policies, and one honest outcome. Parent specification: Structural duplication and combined analysis.

**Blocked by:** 07 Reek configuration and suppression; 08 Stable human and agent text; 11 Pruning and multi-file duplication.

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] The accepted combined check selection runs both analyzers in one mode; there are no Flay/Reek analysis subcommands.
- [ ] One stable report preserves duplication and smell content/ordering in separate sections and never invents a combined score.
- [ ] Supported duplication ignore behavior is imported and applies only to duplication; Reek exclusions/suppression affect only smells. Opposing exclusions are tested.
- [ ] Any unsupported enabled check/setting fails before analysis; failure of either selected analysis produces incomplete output and exit 1, overriding existing findings.
- [ ] Complete no-findings and complete findings produce 0 and 2 respectively. Ambiguous short aliases and unsupported output/options fail with clear long-option guidance.
- [ ] Demonstrate combined examples, independent exclusions, and status-precedence mutations; required gates pass.
