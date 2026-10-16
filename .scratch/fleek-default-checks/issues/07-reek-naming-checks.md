# 07: Reek naming checks

**Type:** task  
**Status:** resolved
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** Fleek reports Reek’s default naming findings with matching messages, locations, contexts, thresholds, configuration, and exclusions.

**Blocked by:** 01: Default invocation and CWD scan; 02: Reek default configuration.

- [x] Support UncommunicativeMethodName, UncommunicativeModuleName, UncommunicativeParameterName, and UncommunicativeVariableName defaults.
- [x] Match pinned Reek 6.6.0 findings on shared supported syntax.
- [x] List unsupported syntax honestly and preserve supported findings with incomplete status.
