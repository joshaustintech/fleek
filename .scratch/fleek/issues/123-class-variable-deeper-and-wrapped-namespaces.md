# 123: Match deeper and wrapped ClassVariable namespace contexts

**What to build:** Close `ClassVariable` parity gaps for classes nested under three or more modules or wrapped within a namespace, using pinned Reek 6.6.0 results to bound each supported case.

**Part of:** Ticket 24 — shared-syntax analyzer parity.

**Blocked by:** 62; 115.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [ ] Compare existing three-level and wrapped namespace fixtures against pinned Reek; record findings, qualified context, lines, coverage, and status for each shape.
- [ ] Implement only reproducible mismatches through the native analyzer, or retain explicit incomplete coverage where reference behavior cannot be represented safely.
- [ ] Add focused public CLI contracts and non-equivalent mutation evidence for changed behavior; preserve context exclusions and namespace occurrence ownership.
- [ ] Record commands, pinned identities, ADR decision, and remaining child links in `## Answer`.
