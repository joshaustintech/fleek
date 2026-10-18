# 33: Isolate regular-expression mutation contract cost

**What to fix:** Regex parity checks shared the broad method-parameter contract, so unrelated mutations repeated six pinned Flay comparisons.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Reproduction

- Pinned Spinel `2026.09.12`, `JOBS=8`.
- Adding the six regex comparisons to `test/duplication_method_parameter_contract.rb` caused each mutation mapped to that contract to execute six additional Flay subprocess comparisons.
- A forced full check with the combined contract was interrupted after several minutes and yielded no passing result.

## Fix

Move the comparisons to `test/duplication_method_regexp_contract.rb`, add that focused contract to standard tests/checks, and map regex mutations only to it. Extend `.agents/skills/performance-bugs/SKILL.md` to require a contract fan-out audit when checks are added to heavily mapped mutation contracts.

## Verification

- The seven selected regex mutations pass using one shared contract binary and seven mutation workers in 29.8 seconds, including setup/build.
- A single regex mutation passes in 10.58 seconds; an unrelated parameter mutation passes in 17.15 seconds.
- The full pinned `make -B check JOBS=8` passes 40 workers, all configured mutations, the regex contract, Flay score 0, and Reek warnings 0.
- Two-axis code review passes; no wall-clock threshold was added.

ADR 0142 records the contract isolation decision and timing evidence.
