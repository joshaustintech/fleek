# 36: Describe scalar identity in Flay method candidates

**What to build:** Fleek distinguishes identical methods from similar methods when their supported scalar values or constant names differ, matching Flay 2.14.4.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** None (can start immediately).

**Status:** open  
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [ ] Express supported scalar identity rules in the shared node descriptors rather than detached type branches.
- [ ] Compare identical and differing integer, float, string, symbol, boolean, nil, and constant values through the compiled CLI against unchanged Flay 2.14.4.
- [ ] Preserve Flay mass, score, locations, ordering, and complete coverage for accepted forms; keep unsupported forms incomplete.
- [ ] Focused mutations detect a missing or incorrect scalar identity rule.
- [ ] Record any representation decision in an ADR.
