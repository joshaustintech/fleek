# Native foundation

Publication: draft for review.

## Problem Statement

Developers cannot use or verify Fleek yet: the repository has engineering guidance but no native executable, analysis tests, or reproducible reference environment. A parser that runs only inside the compiler does not prove an installed analyzer can parse source independently.

## Solution

Establish a reproducible native CLI and reference harness, then demonstrate that a narrowly integrated native parser can inspect Ruby 4.0 and pinned Spinel source without executing it. Make successful usage distinct from successful analysis.

## User Stories

1. As a developer, I want to build with the exact agreed Spinel compiler, so that results do not depend on a moving compiler release.
2. As a maintainer, I want compiler and vendored-parser identities recorded, so that ambient packages cannot silently change a build.
3. As a developer, I want native help and version output, so that I can discover the CLI and identify the executable.
4. As a CI user, I want an empty invocation to fail visibly, so that an accidental missing argument cannot look like a clean scan.
5. As a maintainer, I want locked original tools and dependencies, so that shared-syntax comparisons are repeatable.
6. As an agent, I want one documented verification entry point, so that I can run required gates without inventing helper commands.
7. As a developer, I want a native parser experiment, so that parser reuse is selected from compilation and runtime evidence.
8. As a Ruby developer, I want explicit Ruby 4.0 grammar selection, so that acceptance does not drift with a latest grammar mode.
9. As a Spinel developer, I want documented syntax extensions recognized, so that source intended for the pinned compiler can be inspected.
10. As a developer, I want original source locations and diagnostics, so that a finding can lead me to the correct code.
11. As a developer, I want analysis never to execute source or load its dependencies, so that inspection remains independent of application runtime.
12. As a release user, I want native execution without Ruby or the original analyzers, so that installation stays simple.

## Implementation Decisions

- Spinel release 2026.09.12 at commit 00ce35bb96e489620358ffbc48791001a73778a5 remains fixed. Verify its version and actual parser identity.
- Reference Flay 2.14.4 and Reek 6.6.0 at their accepted commits; establish exact reference Ruby and dependency locks before treating outputs as evidence.
- Keep the CLI and analysis in Spinel Ruby. Prefer native parser reuse through a minimal adapter only after a bounded experiment passes; library, adapter, and linkage choices remain experiment outcomes.
- Keep argv/process I/O at the CLI boundary. Unsupported checks, options, settings, and formats fail explicitly.
- No arguments prints usage to stderr and exits 1. Explicit help exits 0. An unimplemented analysis request cannot report clean success.
- Parser support is a bounded declared capability, not an assumption of full analyzer equivalence. Preserve original locations through any required syntax transformation.
- Establish full build/test, Flay, Reek, mutation, and reference-run commands using pinned Spinel Ruby helpers. Respect required sequential passing commits and pushes.

## Testing Decisions

- Primary seam: compiled CLI process with observable stdout, stderr, and status. No existing application tests provide prior art; engineering guidance prescribes behavioral CLI tests.
- A temporary native parser probe is justified by the integration experiment; use real parsing, never mock ASTs as proof of integration.
- Verify help, empty invocation, invalid options, unsupported analysis, compiler identity, locked reference runs, accepted/invalid grammar, diagnostic locations, comments, repeated parsing, and non-execution of source.
- Check input byte-length handling, ownership, and standalone linkage with real runtime evidence. Inspecting an FFI declaration is not proof it compiles or handles memory correctly.
- Mutation checks must detect altered usage status, falsely accepted invalid input, and incorrect location attribution where relevant.

## Out of Scope

Implemented smell/duplication checks, broad parser architecture, compiler upgrades, other platforms, arbitrary plugins, and performance claims.

## Further Notes

The experiment must leave an honest receipt even if no parser is feasible. A failure keeps downstream work blocked; it does not justify changing the pin or declaring completion. Exact dependency selections and licensing must be verified before reuse.
