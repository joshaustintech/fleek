# ADR 0082: Reuse compiled mutation contracts within a shard

## Status

Accepted.

## Context

The mutation suite rebuilds Fleek for every source mutant. It also used `spinel -E` for each mutant, recompiling the same public contract file repeatedly within each isolated mutation shard. Contract compilation is independent of the mutated `bin/fleek.rb`; the contract executable launches the freshly rebuilt `build/fleek` binary from the shard's working directory.

## Decision

Compile each mapped public contract to a native executable on first use in a mutation process. Reuse it for later mutants mapped to the same contract. Keep rebuilding Fleek and running the full mapped public contract for every mutant. Compile mutated Fleek binaries at `-O0` to reduce repeated native optimization work; the ordinary full build and test gates continue to build the unmutated binary at the default `-O2`. Use a process-specific executable name, delete any stale file at that path before compiling, and store it under the shard's disposable `build` directory so workers remain isolated and normal cleanup removes the cache.

## Consequences

Mutation assertions and mutant coverage stay unchanged while repeated contract compilation and optimization of mutant binaries are removed. Each mutation process pays one contract compile per distinct contract file it exercises. A contract compile failure remains a mutation-suite failure. Mutation contracts must continue to catch the same faults at `-O0`; the separate full build gates retain optimized-build coverage.

## Evidence

The focused twelve-, thirteen-, and fourteen-level nested-module mutations all remained detected. Their measured runtime fell from 56.18 seconds at the default optimized mutant build to 43.30 seconds at `-O0` (23% faster). The full pinned `make check` gate passed all 25 workers in 470.43 seconds at `JOBS=4`, compared with 660.66 seconds before mutant builds used `-O0` (28.8% faster). On this 8-logical-CPU host, running the same full gate with `JOBS=8` passed all 29 workers in 407.76 seconds, 17.3% faster than the prior `JOBS=4` run with unchanged mutant coverage. Keep `JOBS` host-tunable; this measurement does not establish eight workers as a universal optimum. The full gate retains the default optimized native build.
