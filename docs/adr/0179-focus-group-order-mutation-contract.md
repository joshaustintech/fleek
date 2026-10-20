# ADR 0179: Focus the Flay group-order mutation contract

## Status

Accepted

## Context

`Flay group ordering` was the highest-cost eligible label in ticket 106 and mapped to the broad `duplication_contract.rb`. Even with the compiled contract warm, the focused mutation took 35.64s; precompile used 3.347s and the remaining broad contract run took about 32.3s. The behavior is one report-order comparison on a known mixed method/class fixture.

## Decision

Map only `Flay group ordering` to `duplication_group_order_contract.rb`. The focused public CLI contract retains exact expected finding status, group kinds, locations, mass/score, total and per-file score, coverage, normalized status, clean stderr and pinned Flay reference expectations, then checks that the method group precedes the class group. Keep the broad duplication contract in the ordinary test suite for all other parity behavior; move this fixture scenario into the focused contract so it runs once there. The exact mutation must fail with `Flay group ordering differed` after other report fields pass.

## Evidence

The unchanged implementation passed and the intended mutant was caught at the order assertion. The narrow warm run took 18.25s total (3.360s precompile), versus 35.64s warm for the old broad mapping (3.347s precompile); the narrow compiled contract itself ran in 0.28s. Narrow cold was 18.98s total (4.145s precompile). The complete check passed 61 workers and caught all 273 labels; Flay score 0, Reek warnings 0, 124 ticket documents valid. Pinned Spinel 2026.09.12 at `112bae85c1a25fc5399009a849f805bfe691426b`; Flay 2.14.4; Reek 6.6.0.

## Consequences

Focused runs of this label exercise only the report behavior they protect. Other labels continue using the broad contract, which remains part of the ordinary full suite. Compile/setup time stayed about the same; the saving came from executing fewer unrelated public comparisons.
