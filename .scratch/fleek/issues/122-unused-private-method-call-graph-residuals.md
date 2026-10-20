# 122: Complete UnusedPrivateMethod inherited and dynamic-call parity

**What to build:** Match pinned Reek 6.6.0 `UnusedPrivateMethod` behavior for inherited methods and reflective or dynamic call forms, with explicit evidence for each bounded case.

**Part of:** Ticket 24 — shared-syntax analyzer parity.

**Blocked by:** 61; 115.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [ ] Record pinned Reek and Fleek results for inherited private methods and reflective/dynamic references (`send`, `public_send`, method objects, and `to_proc` where accepted); add only cases with a reproducible parity mismatch.
- [ ] Implement supported mismatches through the existing native analysis path, or document unsupported syntax as incomplete coverage when faithful support is out of scope.
- [ ] Add focused public CLI contracts and non-equivalent mutation evidence for every behavior changed; preserve selected-check coverage and outcome semantics.
- [ ] Record exact commands, pinned identities, remaining limits, and an ADR decision in `## Answer`.
