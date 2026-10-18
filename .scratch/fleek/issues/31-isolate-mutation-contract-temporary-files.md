# 31: Isolate mutation contract temporary files

**What to fix:** Full parallel mutation runs intermittently fail a mapped Flay contract with `Errno::ENOENT` and an empty path, although the same mutation passes when selected alone.

**Status:** resolved
**Type:** task
**Category:** bug
**Triage:** ready-for-agent

## Reproduction

- Pinned Spinel `2026.09.12`, `JOBS=8`.
- `make check JOBS=8` failed twice in a mutation shard with `unexpected Flay qualified namespace class collection failure: No such file or directory @ rb_sysopen -`.
- `make mutation JOBS=8` failed in a different shard with the same empty-path error during `Flay qualified namespace class mass`.
- `FLEEK_MUTATIONS='Flay qualified namespace class collection' make mutation JOBS=8` passed, as did the isolated public duplication contract.

## Acceptance criteria

- [x] Identify the cache filename and generated fixture path causing repeated writes.
- [x] Add a deterministic regression check for worker temp/cache isolation.
- [x] Full parallel mutation run passes repeatedly without lowering the supported worker count.
- [x] Full build, contracts, Flay, and Reek gates pass repeatedly.

## Diagnosis

The deep scope fixture included `Process.pid` in its source path. Each mutation therefore generated a new Flay cache key and repeated reference-cache writes. The cache filename also percent-encoded the complete key, leaving a file operation dependent on arbitrary path length and content; parallel runs repeatedly failed writing the status file with `Errno::ENOENT` although the worker cache directory existed. Deep-scope fixtures now use a stable filename inside each worker's unique temp root. Cache filenames use a bounded deterministic digest and store the complete key beside the result; a digest collision is treated as a cache miss. The harness clears copied caches and checks worker temp/cache isolation.

## Answer

Resolution: worker-scoped temporary files prevent cross-worker output access; stable deep fixture paths allow immutable Flay references to be reused within each worker; bounded cache filenames avoid filesystem path failures while full-key verification protects correctness. `make mutation JOBS=8` passed all eight shards and caught every configured mutant in 207.19s. Final `make -B check JOBS=8` passed all 33 workers, all mutations, Flay score 0, and Reek warnings 0 in 282.07s.
