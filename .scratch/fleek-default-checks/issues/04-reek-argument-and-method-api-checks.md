# 04: Reek argument and method API checks

**Type:** task  
**Status:** resolved
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** Fleek reports Reek’s default parameter and method API findings with matching messages, locations, contexts, thresholds, configuration, and exclusions.

**Blocked by:** 01: Default invocation and CWD scan; 02: Reek default configuration.

- [x] Support BooleanParameter, ControlParameter, LongParameterList, LongYieldList, UnusedParameters, and UtilityFunction defaults.
- [x] Preserve opt-in UnusedPrivateMethod selection when selected or enabled according to pinned Reek configuration behavior; keep it out of the default set otherwise.
- [x] Match pinned Reek 6.6.0 findings on shared supported syntax.
- [x] List unsupported syntax honestly and preserve supported findings with incomplete status.

## Answer

Added the six default detectors and compared supported findings with pinned Reek 6.6.0. Explicit/configured `UnusedPrivateMethod` remains selected but unsupported per the parent spec's out-of-scope decision. `UtilityFunction.public_methods_only: true` also remains explicitly incomplete until native visibility tracking is implemented. See ADR 0044.
