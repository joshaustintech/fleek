# 46: Narrow collection mutation contracts

**What to fix:** Focused collection mutations verify behavior through small public Flay contracts instead of replaying the full duplication suite.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

- [x] Add focused top-level collection contracts for array and keyword-hash descriptors, preserving Flay kind, mass, score, source lines, and complete coverage.
- [x] Route collection descriptor mutations to the smallest matching public contract.
- [x] Compare focused mutation runtime before and after; retain complete full-suite mutant detection.
- [x] Record measured fan-out and routing decision in an ADR.

The broad duplication contract took 51.54 seconds. The same selected array mutation fell from 29.57 to 12.65 seconds after rerouting to the focused contract. Eight collection and descriptor mutations all passed. ADR 0166 records the routing policy.
