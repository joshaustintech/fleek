# 21: Flay class and module candidate parity

**What to build:** Fleek reports Flay 2.14.4 structural duplication groups formed by class and module scopes on identical shared-parseable Ruby source, including correct group identity, locations, mass, score, and ordering.

**Blocked by:** None (can start immediately).

**Status:** resolved
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [x] Discover the same class and module candidates as pinned Flay, including nested and cross-scope cases supported by its shared Ruby grammar.
- [x] Match candidate grouping, similar-versus-identical classification, mass, weighted score, source locations, and deterministic ordering against identical inputs.
- [x] Preserve independent verified findings when another candidate is unsupported; report incomplete until all selected source is covered.
- [x] Compare public CLI behavior with unchanged Flay 2.14.4 and add clean, finding, and boundary cases.
- [x] Mutation checks detect missing candidates, wrong group shape, score, locations, ordering, or incomplete status.

## Answer

Candidate scope paths use dynamically sized typed storage and iterative traversal. Generated public contracts compare 64-level class and module paths with unchanged Flay 2.14.4; qualified namespace and cross-scope cases verify group identity, mass, score, locations, and ordering. Mixed parent bodies retain verified class groups when module, class, or direct-method siblings are unsupported, and mark the source incomplete. Focused mutations protect these boundaries. The 8–20 qualified-path fixture ladder was removed after measuring its 42.20-second contract cost; the 21-component boundary and generated-depth checks retain coverage. Final forced native build, all CLI contracts and mutation shards, Flay, Reek, and both review axes pass. See ADR 0102 for unsupported sibling behavior.
