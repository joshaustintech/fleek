# 125: Match InstanceVariableAssumption in deeper and wrapped class scopes

**What to build:** Complete pinned Reek 6.6.0 `InstanceVariableAssumption` parity for class contexts deeper than one direct child and classes wrapped in modules.

**Part of:** Ticket 24 — shared-syntax analyzer parity.

**Blocked by:** 64; 115.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [ ] Match pinned findings, context, class declaration lines, initialization boundaries, and configured exclusions for deeper and module-wrapped classes.
- [ ] Preserve explicit incomplete coverage for unsupported class shapes; do not return clean when a nested class cannot be analyzed.
- [ ] Add public CLI contracts and non-equivalent mutation evidence for changed behavior.
- [ ] Record exact commands, pinned identities, ADR decision, and residual child links in `## Answer`.
