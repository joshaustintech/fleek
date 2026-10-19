# 37: Describe Flay method calls and argument trees

**What to build:** Fleek groups methods with supported calls the same way Flay 2.14.4 does, including differences in receivers, method names, arguments, and blocks.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 36 — Describe scalar identity in Flay method candidates.

**Status:** resolved
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [x] Express supported call identity and child structure through shared descriptors.
- [x] Match same and differing receiver, method name, argument, splat, and block forms against unchanged Flay 2.14.4.
- [x] Preserve candidate grouping, mass, score, locations, ordering, and coverage for accepted forms.
- [x] Keep unsupported call shapes incomplete and add focused mutations for call support and identity.
- [x] Record representation adapters or mass differences in ADRs.

Implemented descriptor-backed call-name identity and recursive call-child comparison. Same/different receivers, names, arguments, splats, and blocks match Flay 2.14.4; argument-forwarding calls remain explicitly incomplete. Parameterless block mass uses its Flay-compatible adjustment while parameterized block mass retains its existing contract. ADR 0163 records these adapters.

The pinned full check passed: 50 workers, all mutation checks caught, Flay score 0, and Reek warnings 0. Spec and standards reviews passed.
