# 03: Reek object and scope checks

**Type:** task  
**Status:** open  
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** Fleek reports Reek’s default object and scope findings with matching messages, locations, context, default thresholds, configuration, and exclusions.

**Blocked by:** 01: Default invocation and CWD scan; 02: Reek default configuration.

- [ ] Support Attribute, ClassVariable, InstanceVariableAssumption, IrresponsibleModule, ModuleInitialize, and SubclassedFromCoreClass defaults.
- [ ] Preserve existing ClassVariable behavior while running it through default selection.
- [ ] Match pinned Reek 6.6.0 findings on shared supported syntax.
- [ ] List unsupported syntax honestly and preserve supported findings with incomplete status.
