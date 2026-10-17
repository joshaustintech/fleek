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

Partial implementation is pushed incrementally. Fleek now matches pinned Flay 2.14.4 for bounded direct module groups, complete multi-method class/module groups at file scope and in one-level namespaces, sole nested-module method chains through twelve modules, one direct class under a sole nested-module chain up to ten modules, direct classes with multiple supported methods under relative qualified module paths with two to sixteen constant components, nested class chains through six levels, supported direct-sibling and wrapper forms, and multiple classes under qualified module paths. The thirteenth-module method, eleventh-module class, seventeenth-qualified-component, and seventh-level nested-class boundaries remain incomplete while pinned Flay still reports their groups. Public CLI fixtures cover clean/finding inputs, similar/identical groups, nested/cross-scope locations, qualified-path mass, score allocation, deterministic ordering, and boundaries; mutation checks exercise these behaviors and their depth bounds. ADRs 0050–0077 record the multi-group representation and limits. This ticket remains claimed because deeper nested scopes and remaining shared-grammar boundaries still need parity evidence.
