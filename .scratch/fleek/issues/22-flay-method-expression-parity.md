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

Implementation is in progress. Array and keyword-hash literals are supported in class-method candidate trees. Top-level methods now use the same bounded AST tree and positional-parameter rules, matching Flay on calls with arguments (mass/score 16), required parameters (mass/score 14), differing required arities (mass/score 12), optional parameters and differing defaults (mass/score 52), if/else control flow (mass/score 62), local-variable writes and identity (mass/scores 38 and 16), boolean OR expressions (mass/score 34), and conditional returns (mass/score 44). Ruby 4 logical-and shapes also match. Pinned CLI contracts and focused mutations cover these paths. Other method forms remain in progress; see ADR 0110.
