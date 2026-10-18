# 22: Flay method and expression parity

**What to build:** Fleek finds the same structural duplication candidates inside methods and expressions that pinned Flay 2.14.4 finds on identical shared-parseable Ruby source.

**Blocked by:** None (can start immediately).

**Status:** claimed  
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [ ] Cover shared-parseable method parameter, statement, control-flow, and expression forms that pinned Flay considers when building duplication candidates.
- [ ] Match structural equality, candidate mass and pruning, similar-versus-identical classification, group score, source locations, and ordering.
- [x] Match supported cross-file candidate collection and preserve original input paths and lines for top-level and class methods.
- [ ] Compare clean, finding, and boundary cases through the compiled CLI against unchanged Flay 2.14.4.
- [ ] Mutation checks detect omitted candidates and mismatches in tree shape, mass, grouping, score, locations, or order.

## Answer

Implementation is in progress. Array and keyword-hash literals are supported in class-method candidate trees. Top-level methods now use the same bounded AST candidate algorithm and positional-parameter rules, matching Flay on calls with arguments (mass/score 16), required parameters (mass/score 14), differing required arities (mass/score 12), optional parameters and differing defaults (mass/score 52), if/else and unless control flow (mass/scores 62 and 16), local-variable writes and identity (mass/scores 38 and 16), boolean OR and AND expressions (mass/score 34 each), `case`/`when` control flow with multiple conditions (mass/score 34), float expressions (mass/score 12), nil expressions (mass/score 8), inclusive range expressions (mass/score 10), inclusive/exclusive range similarity, conditional returns (mass/score 44), identical array/hash expressions (mass/scores 38/76 and 60/120), `map` blocks with required block parameters (mass/score 16), explicit `self` receivers (mass/score 10), parenthesized calls (mass/score 8), and qualified constant paths (identical method group mass/score 12/24). Different `when` condition-list lengths also match Flay's no-group result, as do qualified constant paths with different terminal names. The case adapter preserves Flay's synthetic condition-array node in tree equality and mass; focused mutations protect these candidate forms and their behavior. Generated N-expression and N-method contracts exercise beyond the former 128-node, 24-candidate, 32-body-entry, 8,192-byte report, and eight-parameter limits. The expression contract compares mass, locations, and coverage with Flay; the 2,200-method contract compares group mass with Flay and checks the generated ordered locations, score, and coverage; a 40-parameter contract compares mass, score, locations, and coverage with Flay. A two-file class-method contract compares Flay kind, mass, score, ordered original paths/lines, and complete coverage. Candidate metadata, group work arrays, and report storage grow geometrically, and supported positional parameters have no fixed count cap. Broader method-form parity remains in progress. See ADRs 0110–0121.
