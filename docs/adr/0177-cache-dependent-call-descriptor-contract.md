# ADR 0177: Cache the dependent call-descriptor contract

## Status

Accepted

## Context

The call-descriptor public mutation contract imports a shared pair-comparison helper and the common analysis runner. It can reuse a compiled executable only when the prepared source closure and runtime paths remain tied to the current worker.

## Decision

Extend the existing opt-in public-contract cache to exactly `test/duplication_method_call_contract.rb` with `test/duplication_method_pair_contract.rb`; retain the native-parser leaf. Hash the complete prepared source bundle, including `analysis_runner.rb`, and include the temporary-path rewrite format in the key. Read and prepare all required sources before cache lookup, so a missing dependency fails before any cached executable can be restored. Keep each contract's cache namespace separate. Mutants and analyzer results remain uncached.

## Evidence

The cache contract verifies the eligible contract/dependency sets, source and dependency changes, rewrite-format changes, and existing compiler/runtime/flag/corruption/failure/concurrency cases. An uncached focused run caught `Flay method call candidates` in 12.86s. An opted-in cold miss compiled one shared binary and caught the same mutation in 19.06s; the next isolated warm hit restored one binary, rebuilt the mutant, and caught it in 11.59s. Worker-directory and temporary-root assertions passed. Cold key calculation outweighs compilation savings, so caching remains opt-in. Full `make check JOBS=4` passed 60 workers; Flay score 0, Reek warnings 0, and all 124 ticket documents validated. Pinned Spinel is 2026.09.12 at `112bae85c1a25fc5399009a849f805bfe691426b`; Flay 2.14.4; Reek 6.6.0.

## Consequences

Changing the selected contract, pair helper, analysis helper, or rewrite format misses the cache. Missing prepared files fail before restore. Remaining contracts use the existing compilation path, and opt-in callers accept cache-key hashing overhead.
