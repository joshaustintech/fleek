# 07: Reek naming checks

**Type:** task  
**Status:** open  
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** Fleek reports Reek’s default naming findings with matching messages, locations, contexts, thresholds, configuration, and exclusions.

**Blocked by:** 01: Default invocation and CWD scan; 02: Reek default configuration.

- [ ] Support UncommunicativeMethodName, UncommunicativeModuleName, UncommunicativeParameterName, and UncommunicativeVariableName defaults.
- [ ] Match pinned Reek 6.6.0 findings on shared supported syntax.
- [ ] List unsupported syntax honestly and preserve supported findings with incomplete status.
