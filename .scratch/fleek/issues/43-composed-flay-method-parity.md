# 43: Verify composed Flay method-candidate parity

**What to build:** Fleek matches Flay 2.14.4 when supported method parameters, statements, control flow, and expressions appear together in real method candidates.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 42 — Generate Flay contracts for every supported descriptor.

**Status:** claimed
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [ ] Compare generated composed methods, clean results, findings, and unsupported boundaries through the compiled CLI against unchanged Flay 2.14.4.
- [ ] Verify candidate grouping, similar-versus-identical classification, subtree pruning, mass, score, original locations, ordering, and incomplete status across top-level and class methods.
- [ ] Remove remaining duplicate candidate-support and equality/mass paths for covered node families; adapters remain only for demonstrated representation differences.
- [ ] Mutations detect omissions and mismatches across each reported behavior.
- [ ] Pass the full repository gate and both code-review axes; resolve Ticket 22 only when all its acceptance criteria are proven.
