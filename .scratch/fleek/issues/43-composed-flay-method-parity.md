# 43: Verify composed Flay method-candidate parity

**What to build:** Fleek matches Flay 2.14.4 when supported method parameters, statements, control flow, and expressions appear together in real method candidates.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 42 — Generate Flay contracts for every supported descriptor.

**Status:** resolved
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [x] Compare generated composed methods, clean results, findings, and unsupported boundaries through the compiled CLI against unchanged Flay 2.14.4.
- [x] Verify candidate grouping, similar-versus-identical classification, subtree pruning, mass, score, original locations, ordering, and incomplete status across top-level and class methods.
- [x] Share parameter default shape selection and iterator group emission across top-level and class method paths while retaining their representation-specific method adapters.
- [x] Mutations detect omissions and mismatches across each reported behavior.
- [x] Pass the full repository gate and both code-review axes; resolve Ticket 22 only when all its acceptance criteria are proven.

## Answer

Added generated top-level and class-method comparisons against Flay 2.14.4, including three-method groups, a matching subset, and two distinct iterator groups contributed by the same methods. The analyzer groups block nodes independently, orders findings by mass, and matches Flay's kind, mass, score, locations, order, and coverage. Focused mutations catch parameter-selection and multi-block grouping faults. Spec review found no remaining parity gaps; standards review found no blockers. The pinned Spinel 2026.09.12 full gate passed with 63 workers and four mutation workers; standalone Flay reported score 0 and Reek reported 0 warnings. Ticket 22 remains open for its other acceptance criteria. See [ADR 0186](../../../docs/adr/0186-group-composed-methods-by-flay-subtree.md) for the grouping decision.
