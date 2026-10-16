# 05: Reek call and flow checks

**Type:** task  
**Status:** open  
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** Fleek reports Reek’s default call and control-flow findings with matching messages, locations, contexts, thresholds, configuration, and exclusions.

**Blocked by:** 01: Default invocation and CWD scan; 02: Reek default configuration.

- [ ] Support DuplicateMethodCall, FeatureEnvy, ManualDispatch, MissingSafeMethod, NestedIterators, NilCheck, and RepeatedConditional defaults.
- [ ] Match pinned Reek 6.6.0 findings on shared supported syntax.
- [ ] List unsupported syntax honestly and preserve supported findings with incomplete status.
