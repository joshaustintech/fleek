# 24: Complete shared-syntax analyzer parity

**What to build:** Fleek's native CLI completes every built-in Flay 2.14.4 check and Reek 6.6.0 detector on identical shared-parseable source, with the pinned tools' defaults and controls, and no unsupported selected analysis.

**Blocked by:** Default-check issue 08: Complete default profile parity; 21: Flay class and module candidate parity; 22: Flay method and expression parity; 23: Flay analysis-control parity.

**Status:** open  
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [ ] Verify every built-in Flay check and Reek detector, including opt-in detectors, is selectable and matches clean/finding behavior against the pinned references.
- [ ] Verify default selection, explicit subsets, configuration precedence, settings, exclusions, suppressions, and check-specific controls across standalone and combined runs.
- [ ] Re-run the pinned Rails Ruby manifest for all applicable built-in checks; complete every source accepted by both pinned analyzers without unsupported selected analysis.
- [ ] Match semantic findings, locations, grouping, ordering, metrics, coverage, and outcomes; retain the documented Fleek report format and exit-code normalization.
- [ ] Keep Ruby 4.0 or Spinel-only extension evidence separate from unchanged-reference parity and document deliberate differences.
- [ ] Mutation checks demonstrate that omitted checks, findings, controls, source locations, coverage gaps, and incorrect final status fail the public CLI contract.
