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

Implementation is in progress. Candidate scope paths use dynamically sized, typed storage; straight nested class/module chains use iterative traversal. Public contracts pass Flay 2.14.4 parity for generated 64-level chains, the 21-component qualified-path boundary, wrapped sibling-class scopes, module scopes inside sibling classes, mixed scope-kind identity, and namespace classes containing nested modules. The 8–20 qualified-path fixture ladder was removed after measuring its 42.20-second contract cost; the retained boundary and generated depths keep the same behavioral checks. More compound shapes remain under paired reference discovery; the full mutation/native/Flay/Reek gates and code review remain before this ticket can be resolved.
