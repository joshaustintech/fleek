# 40: Describe Flay range and regular-expression values

**What to build:** Fleek classifies supported inclusive/exclusive ranges and static/interpolated regular expressions like Flay 2.14.4.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 36 — Describe scalar identity in Flay method candidates.

**Status:** resolved
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [x] Express range flags, pattern values, interpolation parts, and options through shared descriptors or narrow verified adapters.
- [x] Match identical, similar, clean, and unsupported cases against unchanged Flay 2.14.4.
- [x] Preserve node mass, group kind, score, source locations, order, and complete coverage.
- [x] Focused mutations detect missing range/regexp identity, options, interpolation, or mass rules.
- [x] Record any required representation adapter in an ADR.

## Answer

Shared descriptors now preserve range inclusivity and endpoint identity, plus regular-expression pattern, options, and interpolated parts. Focused contracts cover identical and similar ranges/regexps, clean inputs, and unsupported lambda interpolation against pinned Flay 2.14.4; boundary cases also preserve mass and complete coverage. All nine focused range/regexp mutants were caught. The full pinned Spinel build and check passed: 57 workers, Flay score 0, and zero Reek warnings. ADR 0168 records the representation decisions.
