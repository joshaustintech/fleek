# 28: Remove redundant qualified namespace depth contracts

**What to fix:** Reduce repeated public CLI and Flay reference work in `test/duplication_contract.rb` while retaining deterministic proof of dynamic path behavior.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

- [x] Measure the standalone duplication contract and representative Flay/Fleek invocations.
- [x] Identify redundant depth-only cases and retain a high-boundary qualified path plus generated arbitrary-depth class/module cases.
- [x] Preserve all distinct grouping, score, location, and unsupported-boundary contracts.
- [x] Re-run full build, public contracts, mutation shards, Flay, and Reek.

## Diagnosis

Pinned Spinel `2026.09.12`, Ruby `3.4.9`, Flay `2.14.4`, command `SPINEL=/private/tmp/fleek-spinel-2026.09.12/bin/spinel /usr/bin/time -p spinel -E test/duplication_contract.rb`. Baseline was 42.20s. The contract contained separate paired Fleek/Flay cases for every qualified namespace depth from 8 through 21. Representative single-process measurements were Flay 0.33s and Fleek 0.06s. Three ranked causes: (1) repeated Flay process startup and identical depth-only assertions; (2) deep source parsing and grouping; (3) repeated Fleek CLI startup. The repeated depth ladder is load-bearing duplication; distinct compound fixtures remain.

## Answer

Removed the 13 redundant 8–20 component fixture pairs. Retained the 21-component qualified namespace boundary and generated 64-level nested class/module contracts. Direct contract time fell from 42.20s to 29.41s (30.3%); output and status remained passing. The final forced gate passed with 29 workers and all 185 mutation cases; Flay score 0, Reek warnings 0, total 233.11s. No wall-clock assertion was added.
