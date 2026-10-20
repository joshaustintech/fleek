# Structural duplication and combined analysis

Publication: active specification.

## Problem Statement

Developers need one executable to report both duplication and smells. Byte-identical source matching, altered scoring, merged exclusions, or invented combined scores would make the replacement incompatible or hide findings.

## Solution

Implement Flay's real default structural duplication behavior on a declared supported syntax subset, then run it alongside ClassVariable in one native analysis mode with a stable two-section report and honest completion status.

## User Stories

1. As a developer, I want structural duplicate groups, so that renamed identifiers or changed literals do not evade the agreed reference rule.
2. As a developer, I want structurally different code kept separate, so that similarity is not inferred from token counts or source length.
3. As a developer, I want reference-equivalent mass thresholds, so that only the intended nodes contribute findings.
4. As a developer, I want correct identical-group multipliers and totals, so that duplication scores retain their meaning.
5. As a developer, I want nested covered subtrees pruned correctly, so that reported groups match upstream behavior.
6. As a developer, I want multi-file groups and all locations, so that duplication across files is visible.
7. As an agent, I want deterministic ordering and tie handling, so that repeated results are comparable.
8. As a developer, I want one command to run duplication and smells, so that I do not need separate analysis modes.
9. As a developer, I want separate report sections and type-specific scores, so that unlike metrics are not mixed.
10. As a developer, I want duplication exclusions and smell exclusions applied separately, so that excluding one analysis does not silently exclude the other.
11. As a CI user, I want any failed selected analysis to make the overall report incomplete, so that partial results cannot masquerade as complete checks.
12. As an agent, I want unsupported flags and formats rejected explicitly, so that CLI compatibility limits remain visible.

## Implementation Decisions

- Implement the selected default Flay structural algorithm and its AST semantics, mass, normal pruning, identical multiplier, grouping, scores, and ordering. Literal/name-insensitive structural matching is not text equality.
- Initially declare a narrow supported syntax boundary and reject unsupported nodes rather than silently dropping them. Expand only with behavioral proof.
- Support the default algorithm and its mass threshold; bounded method fuzzy matching, the tested legacy parser boundary, and Flay ignore path expansion are recorded in ADRs 0191, 0192, 0193, and 0194. Liberal, diff, plugins, and unsupported report options remain explicit unsupported requests until separately implemented.
- Use one check-selection interface and distinct long options. Omit conflicting upstream short aliases.
- Produce one text report with separate duplication and smell sections; preserve type-specific content and metrics without inventing a combined score.
- Apply duplication ignore policy only to duplication. Reek exclusions and suppression remain smell-specific.
- Overall status is 0 complete/clean, 2 complete/findings, or 1 error/incomplete, with errors taking precedence even if one analyzer returns useful findings.

## Testing Decisions

- Exercise the compiled CLI and compare unchanged Flay output semantics over shared syntax and locked dependencies.
- Cover equal structures, renamed identifiers/changed literals, different structure, threshold boundaries, identical/non-identical groups, nested covered groups, ties, multiple files, and no findings.
- Verify AST translation, mass, equality, and pruning from executed references rather than assumptions about source length or node counts.
- Run both checks over the same inputs; test each analyzer's exclusions independently, opposing exclusions, unsupported enabled checks, and one-analysis failure.
- Mutation checks target structural equality, mass boundary, multiplier, pruning, exclusion leakage, report ordering, and global error precedence.

## Out of Scope

Fuzzy/liberal/diff behavior, plugin formats, ERB, a combined score, machine formats, new smells, and full Flay option compatibility.

## Further Notes

The default algorithm may need several coherent passing commits per ticket. A supported syntax subset is acceptable during development but must not be described as full Flay equivalence or a useful release solely because one example passes.
