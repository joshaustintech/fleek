# 03: Reek object and scope checks

**Type:** task  
**Status:** resolved
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** Fleek reports Reek’s default object and scope findings with matching messages, locations, context, default thresholds, configuration, and exclusions.

**Blocked by:** 01: Default invocation and CWD scan; 02: Reek default configuration.

- [x] Support Attribute, ClassVariable, InstanceVariableAssumption, IrresponsibleModule, ModuleInitialize, and SubclassedFromCoreClass defaults.
- [x] Preserve existing ClassVariable behavior while running it through default selection.
- [x] Match pinned Reek 6.6.0 findings on shared supported syntax.
- [x] List unsupported syntax honestly and preserve supported findings with incomplete status.

**Evidence:** `make check` passed: pinned Spinel identity, 17 process contracts, 107 mutation cases, reference checks, Flay score 0, and Reek 0 warnings. Specification and standards reviews passed. Decision recorded in [ADR 0043](../../../docs/adr/0043-default-object-scope-detectors.md).
