# ADR 0048: Verify complete default-profile parity

## Status

Accepted.

## Context

Ticket 08 closes the default-profile rollout after tickets 01–07 add selection policy and bounded analyzer support. The highest risk is a selected default silently disappearing from the runnable profile, or default execution losing complete findings and status semantics while explicit selection remains a subset.

## Decision

Keep the pinned default check set as the single source of truth for runnable defaults. Add end-to-end CLI contracts for a fully supported clean default run, a fully supported default run with findings, and explicit selection of one default. Verify opt-in `UnusedPrivateMethod` remains absent from ordinary defaults and is still selected when enabled by configuration. Mutation-test omission of the runnable default set.

## Consequences

Default-profile completion is proved through the compiled CLI and real source fixtures. The clean fixture must return 0 with no unsupported checks and match pinned Flay's total score. The finding fixture must return 2 with complete coverage and match pinned Reek's ordered detector, location, and message records. Explicit `--checks` must report only the requested detector. Existing configuration, exclusion, CWD, and named-stdin contracts remain separate focused checks.

## Evidence

`test/default_invocation_contract.rb` covers the default list, opt-in exclusion, clean and findings statuses, explicit subset behavior, ordered Reek parity, and Flay score parity. `test/default_configuration_contract.rb`, the detector parity contracts, and input contracts cover config settings, exclusion behavior, CWD, and named stdin. `test/mutation_contract.rb` removes the runnable defaults and requires the public invocation contract to fail. `make check` validates the native build, all contracts and mutations, reference checks, Flay, and Reek.
