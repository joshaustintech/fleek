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

The cache status-write failure occurred only under the full eight-worker check. Diagnostics showed `.out`, `.err`, and `.key` files present in an existing cache directory, but the `.status` write intermittently failed with `ENOENT`. The relevant cache paths and status were inline interpolation values passed to native `File` calls. Hoisting them into local variables is a plausible cause-specific fix; temporary lifetime across those calls is an inference, not confirmed runtime behavior. With this change, two consecutive pinned `make check JOBS=8` runs passed all 33 workers and mutations, Flay score 0, and Reek warnings 0 (290.42s and 284.45s). This resolves the repeatable full-gate failure without reducing worker count.

## Answer

Resolution: worker-local capture/cache roots, copied-cache cleanup, stable deep-fixture paths, bounded digest filenames with full-key validation, and local cache path values remove cross-worker interference and the full-load status-write failure. The consecutive full-gate evidence above passes with all eight workers.
