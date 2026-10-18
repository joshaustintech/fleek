# 26: Reduce mutation contract compilation cost

**What to fix:** Mutation checks spend excessive time compiling large public contracts for each isolated shard.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Reproduction

- Pinned Spinel: `2026.09.12` / source `112bae85c1a25fc5399009a849f805bfe691426b`
- Compile `test/duplication_contract.rb` at the default optimization level: 23.13 seconds.
- Compile the same contract with `-O 1`: 5.86 seconds.
- Run both compiled contracts against the same built Fleek executable and warmed reference cache: both pass; runtime was 0.62 seconds at default and 0.70 seconds at `-O 1`.

The mutation harness compiles mapped contracts once per shard. The eight-worker gate therefore recompiles this unchanged contract in each shard.

## Acceptance criteria

- [x] Mutation-only contract binaries use Spinel `-O 1`, reducing measured compile-plus-run time from 23.75 s to 6.55 s.
- [x] The unchanged public contract passes with the mutation compiler setting.
- [x] Mutation checks still catch all 183 configured mutants across eight isolated shards.
- [x] Full native build/contracts, Flay, and Reek gates pass: 18 contracts, Flay score 0, Reek 0 warnings.
- [x] Before/after timings and the decision are recorded in [ADR 0096](../../../docs/adr/0096-mutation-contract-optimization-level.md).
