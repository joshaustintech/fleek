# ADR 0142: Isolate regular-expression mutation checks

## Status

Accepted.

## Context

The six static and interpolated regular-expression parity comparisons were appended to the method-parameter contract. Every mutation mapped to that broad contract therefore repeated all six Flay subprocess comparisons, even when mutating unrelated parameter or expression behavior. A full check using that map was interrupted after several minutes without completing, so it supplied no passing evidence.

## Decision

Keep regex comparisons in `test/duplication_method_regexp_contract.rb`, include it in the standard runner through a separate regression-contract list, and map only regex mutations to it. Keep the main test list and parameter contract focused.

## Evidence

Pinned Spinel `2026.09.12`, `JOBS=8`. The seven selected regex mutations passed with one shared contract binary and seven mutation workers in 29.8 seconds including version check and build. A single regex candidate mutation passed in 10.58 seconds; a single unrelated parameter mutation passed in 17.15 seconds. The regex contract directly passes against pinned Flay. `bundle exec flay bin test/*.rb` reports score 0.

## Consequences

Focused mutations execute only their mapped public contract, retaining deterministic coverage and worker isolation. Standard tests still include the regex contract. No wall-clock assertion is added; future slow checks follow `.agents/skills/performance-bugs/SKILL.md` and are tracked as bug tickets.
