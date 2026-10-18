# ADR 0126: Size focused mutation runs to selected mutants

## Status

Accepted

## Context

A one-label mutation run with `JOBS=8` started eight isolated workers even though only one worker could contain the selected mutation. Each worker copied the 95 MB repository. The run took 32.299 seconds and reported seven empty workers. PIT reduces work by selecting tests that cover a mutant and prioritizing faster relevant tests. Fleek already maps each mutant to a public contract, so it can apply the same relevance principle without JVM instrumentation.

## Decision

For a focused mutation selection, cap mutation worker count at the number of unique selected labels. Sort selected labels in the registry's canonical order, and assign them deterministically. In `check` mode, preserve the configured concurrency for public contracts and style checks; only mutation workers use the smaller count. Keep the full unfiltered mutation shard layout unchanged. Map the `for` loop mutation to a small dedicated public CLI contract that compares Fleek with pinned Flay.

## Consequences

A one-label mutation run creates one isolated worker and compiles one small public contract. The repeated measured run completed in 10.138 seconds and still killed the mutation. Full runs keep bounded parallelism and execute every mapped contract. The repository retains explicit mutant-to-contract mappings rather than importing PIT's Java bytecode coverage mechanism.

## References

- [PIT FAQ: test selection and prioritization](https://pitest.org/faq/)
