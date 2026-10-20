# 118: Match Flay subtree selection for similar composed methods

**What to build:** When composed method signatures differ in parameter names or defaults, preserve Flay's nested block finding instead of reporting the enclosing method.

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [ ] Compare generated identical and renamed/default parameterized-block pairs against pinned Flay and Fleek, including finding kind, node, mass, score, locations, coverage, and total score.
- [ ] Add a focused mutation for the group-selection rule and record the full gate results.

## Starting evidence

Pinned Flay reports the similar nested block pair at `:iter` with mass 22 and total score 22, while Fleek reports the enclosing `:defn` with mass 36 and total score 36. The pair uses signatures `(required, optional = 1, *rest, mode:, strict: false, **options, &callback)` and `(source, fallback = 3, *tail, state:, safe: true, **settings, &handler)`, with nested parameterized blocks and same-shaped calls.
