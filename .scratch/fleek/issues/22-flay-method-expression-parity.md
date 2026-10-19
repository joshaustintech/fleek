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

Implementation is in progress. Array and keyword-hash literals are supported in class-method candidate trees. Top-level methods now use the same bounded AST candidate algorithm and positional-parameter rules, matching Flay on calls with arguments (mass/score 16), required parameters (mass/score 14), differing required arities (mass/score 12), optional parameters and differing defaults (mass/score 52), if/else and unless control flow (mass/scores 62 and 16), while and until loops (mass/score 10 each), local-variable writes and identity (mass/scores 38 and 16), boolean OR and AND expressions (mass/score 34 each), `case`/`when` control flow with multiple conditions (mass/score 34), float expressions (mass/score 12), nil expressions (mass/score 8), inclusive range expressions (mass/score 10), inclusive/exclusive range similarity, conditional returns (mass/score 44), identical array, keyword-hash, and hash-rocket expressions (mass/scores 38/76 and 60/120 for arrays and keyword hashes; 60/120 for hash rockets), `map` blocks with required block parameters (mass/score 16), explicit `self` receivers (mass/score 10), parenthesized calls (mass/score 8), qualified constant paths (identical method group mass/score 12/24), splat arguments, interpolated strings (similar renamed-variable methods, mass/score 10), named rest parameters (similar methods, mass/score 6), and required keyword parameters (similar methods, mass/score 8). Different `when` condition-list lengths also match Flay's no-group result, as do qualified constant paths with different terminal names. The case adapter preserves Flay's synthetic condition-array node in tree equality and mass; focused mutations protect these candidate forms and their behavior. Generated N-expression and N-method contracts exercise beyond the former 128-node, 24-candidate, 32-body-entry, 8,192-byte report, and eight-parameter limits. The expression contract compares mass, locations, and coverage with Flay; the 2,200-method contract compares group mass with Flay and checks the generated ordered locations, score, and coverage; a 40-parameter contract compares mass, score, locations, and coverage with Flay. A two-file class-method contract compares Flay kind, mass, score, ordered original paths/lines, and complete coverage. Candidate metadata, group work arrays, and report storage grow geometrically, and supported parameters have no fixed count cap. Broader method-form parity remains in progress. See ADRs 0110–0129.

Top-level methods containing `for` loops now also match Flay's similar group (mass/score 14) with complete coverage. Their candidate tree accepts the `for` node and its local-variable target. The focused contract compares the compiled CLI report against pinned Flay, and its focused mutation confirms a missing `for` candidate is detected. See ADR 0127.

Top-level methods with named rest parameters now match Flay's similar group (mass/score 6) with complete coverage. Differing rest names preserve similar rather than identical classification. The focused contract detects removal of that name comparison. See ADR 0128.

Top-level methods with required keyword parameters now match Flay's similar group (mass/score 8) with complete coverage. Keyword-name identity, mass addition, and candidate acceptance have separate focused mutations. See ADR 0129.

Top-level methods with supported literal-default optional keyword parameters now match Flay's similar group (mass/score 10) with complete coverage. Different optional keyword counts preserve Flay's no-group result. Nonliteral defaults remain incomplete (Flay finds a candidate, Fleek reports unsupported syntax). Focused mutations protect candidate acceptance, keyword name/default identity, mass, optional-count grouping, and rejection of unsupported defaults. See ADR 0130.

Top-level methods with required post parameters now match Flay's similar groups at mass/score 10, including differing post names and counts. Post parameter names affect identical-versus-similar classification, while post parameters add no mass. Focused mutations protect candidate support, identity, and mass. See ADR 0131.

Top-level methods with named keyword-rest parameters now match Flay's similar group (mass/score 6). Differing keyword-rest names remain similar, and keyword-rest parameters add no mass. Focused mutations protect candidate support and name identity. See ADR 0132.

Anonymous `*` and `**` parameters now match Flay's identical groups at mass/score 6/12. Anonymous-versus-named rest and keyword-rest forms remain similar at mass/score 6. The shared optional-name comparator avoids dereferencing Prism's zero sentinel. A focused contract and mutations protect both candidate support and name identity. See ADR 0144.

Top-level methods with named block parameters match Flay's similar group (mass/score 6). Differing names remain similar and add no mass. Anonymous block parameters now match Flay's identical group (mass/score 6/12); both absent names compare equal without looking up Prism's zero sentinel, while absent-versus-present names remain similar (mass/score 6). Dedicated mutations protect candidate support and both name-identity boundaries. See ADRs 0133 and 0143.

Top-level methods containing bare `yield` and `yield(value)` now match Flay's identical groups at mass/score 6/12 and 8/16 respectively, with complete coverage. The recursive candidate collector preserves yield argument structure and mass; a focused mutation protects yield-node support. See ADR 0134.

Top-level methods containing bare `super` and `super(value)` now match Flay's similar groups at mass/score 6 and 8, with complete coverage. The recursive candidate collector preserves each super node form and argument structure; focused mutations protect both node kinds. See ADR 0135.

Top-level methods containing `next value if value` inside a block now match Flay's similar group at mass/score 24, with complete coverage. The recursive collector preserves next-node and value structure; focused mutations protect node support and its one-point mass. See ADR 0136.

Top-level methods containing `break value if value` and `redo if value` inside blocks now match Flay's similar groups at mass/score 20 and 18, with complete coverage. Focused mutations protect both node forms. See ADR 0137.

Top-level methods containing `begin/rescue/retry` now match Flay's identical group at mass/score 16, with complete coverage. Separate mutations protect begin, rescue, and retry node support, plus retry's one-point mass. See ADR 0138.

Top-level methods containing `begin/ensure` now match Flay's similar group at mass/score 10, with complete coverage. The recursive collector discounts each ensure node by one point to match Flay; focused mutations protect node support and mass. See ADR 0139.

Top-level methods containing static regular-expression literals now match Flay at mass/score 10. Pattern and option differences preserve similar-versus-identical classification. Interpolated regular-expression literals now match Flay at mass/score 16 after a one-point adjustment per Prism node; pattern-part and option differences preserve similar-versus-identical classification. Dedicated compiled CLI contracts compare both forms with pinned Flay, and separate mutations protect candidate support, mass, pattern identity, and option identity. See ADRs 0140 and 0141.

The dedicated regex contract keeps mutation checks narrow: regex mutations run only these six comparisons instead of repeating them for unrelated parameter and expression mutations. See ADR 0142.

Top-level methods containing multiple assignments now match Flay. Candidate trees preserve target arity and names, and each `MultiWriteNode` contributes two mass points to account for Flay's RubyParser representation. Contracts compare identical two-target methods (mass 22), similar methods differing only in target names (mass 20), identical three-target methods (mass 26), and Flay's clean result when target counts differ; focused mutations protect support, mass, and target identity. See ADR 0145.

Method candidates now support nested blocks with optional parameters. Candidate trees compare parameter names and retain supported default expressions; each block parameter list with optional parameters adds one Flay wrapper mass point regardless of how many optional parameters it contains. Contracts compare one and two optional parameters (mass 20 and 24), differing names and literal/call defaults, and a clean one-versus-two parameter boundary. Focused mutations protect support, mass, and parameter/default identity. See ADR 0146.

Method candidates now support local-variable operator writes such as `+=`. Each write adds two Flay mass points; contracts compare identical writes (mass 24), renamed-variable methods, and differing operators as similar groups. Focused mutations protect candidate support, mass, and operator identity. See ADR 0147.

Method candidates now support local-variable logical writes (`&&=` and `||=`). Each node adds two mass points; same-operator target-name changes classify as similar, while different logical operators produce no Flay group. Focused mutations protect support, mass, and target-name identity for both node types. See ADR 0148.

Method candidates now support class-variable reads. Same-name reads match Flay at mass 12; changing only the class-variable name preserves a similar group. Focused mutations protect candidate support and name identity. See ADR 0149.

Method candidates now support class-variable operator writes. Same-name `+=` writes match Flay at mass 24; changing the target name or using a different operator preserves a similar group. Focused mutations protect candidate support, mass, and target/operator identity. See ADR 0150.
