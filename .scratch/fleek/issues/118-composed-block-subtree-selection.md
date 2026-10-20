# 118: Match Flay subtree selection for similar composed methods

**What to build:** When composed method signatures differ in parameter names or defaults, preserve Flay's nested block finding instead of reporting the enclosing method.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Acceptance criteria

- [x] Compare generated identical and renamed/default parameterized-block pairs against pinned Flay and Fleek, including finding kind, node, mass, score, locations, coverage, and total score.
- [x] Add a focused mutation for the group-selection rule and record the full gate results.

## Starting evidence

Pinned Flay reports the similar nested block pair at `:iter` with mass 22 and total score 22, while Fleek reports the enclosing `:defn` with mass 36 and total score 36. The pair uses signatures `(required, optional = 1, *rest, mode:, strict: false, **options, &callback)` and `(source, fallback = 3, *tail, state:, safe: true, **settings, &handler)`, with nested parameterized blocks and same-shaped calls.

## Answer

Added generated identical and renamed/default public-CLI comparisons against Flay 2.14.4. Both assert finding kind and node, normalized mass, group and total score, ordered locations, coverage, and status. The `Flay composed block subtree selection` mutation is caught by the focused contract. On pinned Spinel 2026.09.12, the cold `make check` passed all 63 workers with `JOBS=4` and four mutation workers; Flay and Reek reported zero findings. `make reek` also reported zero warnings. See [ADR 0185](../../../docs/adr/0185-select-nested-block-group-for-renamed-composed-methods.md).
