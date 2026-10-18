# ADR 0094: Cache immutable Flay references during mutation checks

## Status

Accepted.

## Context

Each mutation rebuilds Fleek and runs its complete mapped public contract. The duplication contract also invokes unchanged Flay 2.14.4 for many fixtures on every mutant. Within one isolated mutation shard, source inputs and Flay do not change; only Fleek's implementation changes. Re-running identical Flay processes adds time without increasing mutation coverage.

## Decision

During mutation checks only, persist Flay exit status, stdout, stderr, and the complete invocation key in the shard's disposable `build/mutation-reference-cache`. Map each length-prefixed invocation key to a bounded deterministic 32-bit FNV-1a filename, then verify the stored full key before accepting a cache hit. A digest collision causes a miss and a fresh Flay invocation. Each shard executes its mutation contracts serially, so only one cache writer runs within a worker; distinct workers own distinct cache directories. Write key and result files before status, so status marks a complete entry. Clear copied cache data when initializing each worker; reuse entries only among mutants in that worker's run. Normal contract runs always invoke live Flay when the cache environment variable is absent. Continue rebuilding every mutated Fleek binary and running its complete public contract.

Deep-scope fixtures use stable filenames under each worker's unique temporary root. Their previous process-ID component made every mutation invocation appear to be a new source path, defeating reference reuse.

The parallel `Errno::ENOENT` was localized to writing the cache status file: the worker cache root and target directory existed, while the encoded per-invocation target did not. Replacing the unbounded percent-encoded invocation filename with the bounded digest filename removed that failure in repeated eight-worker mutation and full-check runs. The process-ID fixture path amplified the issue by forcing those writes for every mutant; stable paths eliminate the unnecessary repeated cache entries.

## Consequences

Mutation runs still compare each changed Fleek binary against unchanged Flay output for every contract assertion. Shards cannot share cache state. Worker cleanup removes each cache. Full invocation-key verification protects cached result correctness even if two digest filenames collide.

## Evidence

A compiled full duplication contract completed with all 94 Flay reference invocations live in 17.23 seconds. With those reference results warmed in the disposable cache, it completed in 0.37 seconds (97.9% less contract runtime); both runs passed. Full pinned `make check` with 183 mutants passed in 300.10 seconds; the preceding uncached full gate passed in 418.44 seconds, a 28.3% reduction.

A later full `make mutation JOBS=8` passed all eight shards and caught every configured mutant in 207.19 seconds after making deep fixture paths stable. Final `make -B check JOBS=8` passed all 33 workers, all mutations, Flay score 0, and Reek warnings 0 in 282.07 seconds with bounded filenames and full-key verification. A further `make mutation JOBS=8` passed all eight shards and caught every mutant in 204.97 seconds.

A later full-load failure still occurred with the target directory and `.out`, `.err`, and `.key` entries present but the `.status` entry missing. Cache read/write paths and status content had been passed inline to native `File` calls. Keeping those values in locals removed the failure in two consecutive `make check JOBS=8` runs. This points to temporary lifetime across Spinel native calls; the precise runtime mechanism is inferred, while the status-write symptom and passing gates are observed.

After retaining cache paths and status content in local variables, two consecutive `make check JOBS=8` runs passed all 33 workers and mutants, Flay score 0, and Reek warnings 0 in 290.42 and 284.45 seconds.
