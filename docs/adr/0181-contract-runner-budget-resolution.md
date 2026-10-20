# ADR 0181: Test runner-resolved mutation precompile budgets

## Status

Accepted

## Context

Ticket 108's process-boundary regression passed numeric `JOBS` values directly to mutation precompile. It tested fan-out and compiler isolation but did not prove that CheckRunner resolved an unset or over-CPU request and forwarded that effective value. Its prior unset and over-request evidence came from manual runner probes.

## Decision

Extend `check_runner_precompile_budget_contract.rb` to launch the real CheckRunner mutation mode with a fake Spinel child. The child records `JOBS` only when invoked for mutation precompile. Exercise unset, explicit one, explicit three, and over-request one hundred. Keep the existing direct precompiler scenarios for deterministic fan-out, selected-contract caps, distinct temp roots, dependency selection, and `-O 1`. No wall-clock assertions or production runner mode are added.

## Evidence

With 8 logical CPUs, the child observed 8, 1, 3, and 8 for unset, one, three, and one hundred respectively. Removing the runner's `JOBS=#{@jobs}` child assignment made the contract fail at the unset-budget assertion; restoring it passed. Full `make check JOBS=4` passed 61 workers and caught all 273 mutations, with 49 shared binaries restored. Flay score was 0, Reek warnings 0, and all 126 ticket documents passed validation. Pinned Spinel 2026.09.12, Flay 2.14.4, Reek 6.6.0.

## Consequences

The runner's environment resolution and the precompiler's bounded fan-out now have separate deterministic proofs. Runner behavior and user-facing options remain unchanged.
