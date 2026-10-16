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

Partial implementation is pushed incrementally. Fleek now matches pinned Flay 2.14.4 for bounded direct module groups, complete multi-method class/module groups at file scope and in one-level namespaces, sole nested-module chains through eight modules (verified at eight), mixed independent method/scope groups, and multi-candidate method groups. The ninth-module boundary is explicitly incomplete while pinned Flay still reports its group. Public CLI fixtures cover clean/finding inputs, similar/identical groups, nested/cross-scope locations, score allocation, and deterministic ordering; mutation checks exercise these behaviors and the exact depth boundary. ADR 0050 records the multi-group representation and its limits. This ticket remains claimed because chains beyond eight modules, nested class scopes, and remaining shared-grammar boundaries still need parity evidence.
