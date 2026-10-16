# 04: Reek argument and method API checks

**Type:** task  
**Status:** open  
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** Fleek reports Reek’s default parameter and method API findings with matching messages, locations, contexts, thresholds, configuration, and exclusions.

**Blocked by:** 01: Default invocation and CWD scan; 02: Reek default configuration.

- [ ] Support BooleanParameter, ControlParameter, LongParameterList, LongYieldList, UnusedParameters, and UtilityFunction defaults.
- [ ] Support opt-in UnusedPrivateMethod when selected or enabled according to pinned Reek configuration behavior; keep it out of the default set otherwise.
- [ ] Match pinned Reek 6.6.0 findings on shared supported syntax.
- [ ] List unsupported syntax honestly and preserve supported findings with incomplete status.
