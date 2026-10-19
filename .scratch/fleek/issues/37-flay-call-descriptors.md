# 37: Describe Flay method calls and argument trees

**What to build:** Fleek groups methods with supported calls the same way Flay 2.14.4 does, including differences in receivers, method names, arguments, and blocks.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 36 — Describe scalar identity in Flay method candidates.

**Status:** open  
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [ ] Express supported call identity and child structure through shared descriptors.
- [ ] Match same and differing receiver, method name, argument, splat, and block forms against unchanged Flay 2.14.4.
- [ ] Preserve candidate grouping, mass, score, locations, ordering, and coverage for accepted forms.
- [ ] Keep unsupported call shapes incomplete and add focused mutations for call support and identity.
- [ ] Record representation adapters or mass differences in ADRs.
