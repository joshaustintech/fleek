# 21: Flay class and module candidate parity

**What to build:** Fleek reports Flay 2.14.4 structural duplication groups formed by class and module scopes on identical shared-parseable Ruby source, including correct group identity, locations, mass, score, and ordering.

**Blocked by:** None (can start immediately).

**Status:** claimed
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [ ] Discover the same class and module candidates as pinned Flay, including nested and cross-scope cases supported by its shared Ruby grammar.
- [ ] Match candidate grouping, similar-versus-identical classification, mass, weighted score, source locations, and deterministic ordering against identical inputs.
- [ ] Preserve independent verified findings when another candidate is unsupported; report incomplete until all selected source is covered.
- [ ] Compare public CLI behavior with unchanged Flay 2.14.4 and add clean, finding, and boundary cases.
- [ ] Mutation checks detect missing candidates, wrong group shape, score, locations, ordering, or incomplete status.

## Answer

Implementation is in progress. Candidate scope names now use dynamically sized storage, and nested-module collection is iterative. Public contracts pass Flay 2.14.4 parity for generated 64-level nested module and class chains, the former 21-component qualified-path boundary, and wrapped sibling-class scopes. Additional compound shapes are being discovered through paired reference checks; the full mutation/native/Flay/Reek gates and code review remain before this ticket can be resolved.
