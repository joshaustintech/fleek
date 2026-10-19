# 38: Describe Flay collection and destructuring nodes

**What to build:** Fleek groups supported array, hash, keyword-hash, association, splat, and multiple-assignment method expressions with Flay 2.14.4 semantics.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 36 — Describe scalar identity in Flay method candidates.

**Status:** resolved
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [x] Express supported collection child structure and identity through shared descriptors.
- [x] Match identical, similar, and clean candidate groups, including target counts, names, associations, and Flay mass adjustments.
- [x] Preserve score, source locations, order, and complete coverage against unchanged Flay 2.14.4.
- [x] Keep unsupported neighboring shapes incomplete; focused mutations detect missing rules and incorrect mass or identity.
- [x] Record representation differences in ADRs.

Array, keyword-hash, hash-association, splat, and multiple-assignment nodes use the shared descriptor table. Focused Flay contracts cover group identity, mass, score, locations, ordering, coverage, and clean target-count boundaries; all eight focused support/mass/identity mutations are caught. ADRs 0104, 0105, 0145, and 0166 record representation and mutation-routing decisions.
