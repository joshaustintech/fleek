# 05: Reek call and flow checks

**Type:** task  
**Status:** resolved
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** Fleek reports Reek’s default call and control-flow findings with matching messages, locations, contexts, thresholds, configuration, and exclusions.

**Blocked by:** 01: Default invocation and CWD scan; 02: Reek default configuration.

- [x] Support DuplicateMethodCall, FeatureEnvy, ManualDispatch, MissingSafeMethod, NestedIterators, NilCheck, and RepeatedConditional defaults.
- [x] Match pinned Reek 6.6.0 findings on shared supported syntax.
- [x] List unsupported syntax honestly and preserve supported findings with incomplete status.

## Answer

Added all seven defaults with bounded native syntax support and explicit incomplete results for unsupported shapes. Matched pinned Reek 6.6.0 findings, threshold settings, call and iterator patterns, and MissingSafeMethod exclusions. See ADR 0045.
