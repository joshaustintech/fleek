# 22: Flay method and expression parity

**What to build:** Fleek finds the same structural duplication candidates inside methods and expressions that pinned Flay 2.14.4 finds on identical shared-parseable Ruby source.

**Blocked by:** None (can start immediately).

**Status:** claimed  
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [ ] Cover shared-parseable method parameter, statement, control-flow, and expression forms that pinned Flay considers when building duplication candidates.
- [ ] Match structural equality, candidate mass and pruning, similar-versus-identical classification, group score, source locations, and ordering.
- [ ] Match cross-file candidate collection and preserve original input paths and lines.
- [ ] Compare clean, finding, and boundary cases through the compiled CLI against unchanged Flay 2.14.4.
- [ ] Mutation checks detect omitted candidates and mismatches in tree shape, mass, grouping, score, locations, or order.

## Answer

Implementation is in progress. The first slice adds array literals to class-method candidate trees; the paired compiled CLI/Flay contract matches a similar class group at mass/score 40 and lines 1/7. A named mutation removes array-node support and is caught by its isolated public contract. ADR 0104 records the boundary.
