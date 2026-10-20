# ADR 0178: Reuse mapped mutation contracts by default

## Status

Accepted

## Context

The mutation runner compiles the same mapped public contracts on repeated checks. Focused cache keys include the full prepared source closure, so warming a different selection cannot supply binaries for a complete run. Each mutation and public contract must still execute for every selected label.

## Decision

Enable compiled-contract reuse by default for all contracts in `MutationCase::CONTRACTS` whose selected dependency closure matches `CONTRACT_DEPENDENCIES`. Keep ordinary standalone test contracts uncached. Store verified envelopes under the source checkout's ignored `build/mutation-contract-cache/`, outside disposable worker copies. `WorkspaceStager` already excludes `build/mutation-*`; the runner passes the persistent cache path to precompile and mutation workers. Continue to key the complete prepared bundle, compiler/runtime identity, options, platform, code-generation environment and rewrite/cache formats. Each run restores into its own shared-contract directory, then builds and executes every mutant with its normal expected-failure checks.

Use `FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true` with `make check` or `make mutation` for a true cold run; disabled runs compile all selected contracts and neither read nor write cache entries. The cache has no automatic eviction. Remove only the ignored `build/mutation-contract-cache/` directory when stored entries should be discarded. Cache corruption or identity changes miss and rebuild; compiler failures are never published. Atomic same-directory publication uses invocation-unique temporary entries, so concurrent writers and worker cleanup cannot expose partial binaries or remove another run's files.

## Evidence

With pinned Spinel 2026.09.12 (`112bae85c1a25fc5399009a849f805bfe691426b`), Flay 2.14.4, Reek 6.6.0, and `JOBS=4`, cold `make check` compiled 48 shared mutation contracts in 25.434s; warm `make check` restored all 48 in 3.870s, avoiding 48 compiler processes and saving 21.564s in precompile. Both complete runs passed 60 workers and caught the same 273 mutation labels; sorted caught-label and mutation-worker status outputs matched. Focused disabled mode compiled one contract; two concurrent independent focused runs both compiled the same cold key, each caught `Flay method call candidates`, and each passed its isolated worker/temp-root checks. The cache contract verifies digest, executable mode, input invalidation, corrupt-entry rebuild, failed-build nonpublication, concurrent atomic publication, and separate restored output paths. Flay score 0, Reek warnings 0, and all 124 ticket documents validated.

## Consequences

Repeated full mutation runs avoid shared-contract compilation while still rebuilding every mutant and running every contract. Ordinary tests retain their current compile path. Different selected source closures produce distinct entries; ignored entries persist until manually removed and may accumulate. Use the disable setting when independent cold verification is needed.
