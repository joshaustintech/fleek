# ADR 0176: Cache the native-parser mutation contract

## Status

Accepted

## Context

Focused mutation runs repeatedly compile the same native-parser public contract. This contract is a leaf with no shared Ruby-source dependencies, so its compiled executable can be reused independently of each mutation and worker directory. Cache hits must not reuse mutant binaries or analysis outcomes, and a cache key must fail closed when the compiler/runtime identity cannot be established.

## Decision

Add opt-in caching through `FLEEK_CACHE_NATIVE_PARSER_CONTRACT=true`, only when the selected shared-contract set is exactly `test/native_parser_contract.rb` with no dependencies. Store a single verified envelope per key under ignored `build/mutation-contract-cache/native-parser/`. Key the full prepared source bundle, compiler executable bytes and resolved path, Spinel runtime headers and archives, compile options, code-generation environment, platform, and cache format. Verify the executable payload digest and mode on every hit; restore it through a unique temporary file and atomic rename. Publish only after successful compilation, with a unique temporary entry and atomic rename. Concurrent publishers replace complete entries and remove only their own temporary files.

At ticket 110, the default stayed uncached because the measured end-to-end gain was small. Ticket 112 later enabled caching for all mapped mutation contracts by default; [ADR 0178](0178-default-mapped-mutation-contract-cache.md) records the persistent root and cold-run switch. The native-parser contract still rebuilds each mutant and executes the restored public contract from the new worker directory with that worker's temporary root.

## Evidence

Two uncached focused baseline runs took 11.36s and 11.18s; shared-contract precompile took 3.366s and 3.367s. With the cache enabled, the cold miss took 12.11s total (3.921s precompile); the following warm hit took 11.40s total (3.288s precompile). Both caught `embedded NUL acceptance`. The warm run avoided one compiler process and saved 0.63s in the precompile phase; end-to-end change is small and within run-to-run variation, so caching remains opt-in and no broad speedup is claimed.

The cache contract verifies miss then hit and compile count, source/compiler/runtime-header/runtime-library/flag invalidation, corrupt-entry rebuild, failed-build nonpublication and subsequent miss, and two concurrent publishers yielding one complete digest-verified executable. The warm public mutation run also passed `MutationCase`'s worker-temp-root check, including preserved executable mode. The full uncached `make check JOBS=4` passed 60 workers in 398.90s; Flay score 0, Reek warnings 0, and all 124 ticket documents validated. Pinned compiler: Spinel 2026.09.12 at `112bae85c1a25fc5399009a849f805bfe691426b`; Flay 2.14.4; Reek 6.6.0.

## Consequences

Repeated opted-in runs avoid compiling one unchanged leaf harness. Source, compiler, runtime, flags, platform, or code-generation environment changes produce a miss. Invalid entries rebuild; failed builds never publish. Other contracts, mutants, and analyzer results remained uncached in this initial slice. The single-contract cold cost kept this slice opt-in; ADR 0178 records the later measured full-run decision to enable mapped-contract reuse by default.
