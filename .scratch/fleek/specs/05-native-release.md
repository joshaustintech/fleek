# Standalone native release and performance evidence

Publication: active specification.

## Problem Statement

Build success and a local demonstration do not give users an installable standalone tool or prove speed. Users need a downloadable native executable with truthful coverage, identity, and runtime behavior.

## Solution

Measure cold CLI runtime after correctness, package the proven arm64 executable with required notices, verify installation without Ruby or the original analyzers, and publish a downloadable artifact whose identity and behavior are checked.

## User Stories

1. As a macOS Apple Silicon developer, I want a downloadable native archive, so that I can install Fleek without building a compiler.
2. As a developer, I want Fleek to run without Ruby, Flay, or Reek installed, so that installation has few moving parts.
3. As an agent, I want executable version and reference identities, so that I can connect a result to the release evidence.
4. As a user, I want required license notices included, so that reused components retain their notices.
5. As a developer, I want a clear supported-check and language statement, so that a first release is not presented as complete upstream replacement.
6. As a maintainer, I want measured cold runtime on identical source, so that speed claims come from executed evidence.
7. As a maintainer, I want a target chosen from measurements, so that no arbitrary performance promise overrides correctness.
8. As a user, I want archive contents and installation instructions verified, so that I can run the documented command successfully.
9. As an agent, I want clean, finding, and incomplete statuses checked after installation, so that packaging cannot change the CLI contract unnoticed.
10. As a user, I want the actual downloadable asset verified, so that a build receipt is not mistaken for a published release.

## Implementation Decisions

- First platform is macOS arm64. Distribute a versioned executable archive with reference/compiler identities, supported scope, required notices, and integrity evidence.
- Preserve runtime independence; no delegation to original analyzers or unbundled Ruby runtime. Inspect linkage and prove execution in an environment where those tools are unavailable.
- Measure cold process startup plus analysis over identical immutable input and supported settings for Fleek and the originals. Distinguish total combined work from per-analyzer results and document any comparison limitations.
- Record repeated timings, host/build identity, run order, outputs/status parity, and summary statistics. Define cold precisely; do not claim a purged filesystem cache without evidence.
- Choose a performance target from recorded measurements only after correctness; report unmet targets honestly rather than weakening checks.
- Use pinned Spinel Ruby for measurement, packaging orchestration, and one-off verification helpers; existing platform commands may be invoked.
- A release is delivered only when the downloadable artifact exists and its retrieved identity, installation, and CLI behavior match recorded proof.

## Testing Decisions

- Continue using CLI process behavior as the acceptance seam, now against the installed artifact rather than a development executable.
- Re-run selected parity examples and clean/finding/incomplete statuses from the extracted archive without original runtime dependencies available.
- Verify architecture, native linkage, artifact identity, version, notices, documented invocation, and supported-scope information.
- Benchmark only after real-project correctness evidence. Repeated runs must verify outcomes, not time a shortcut that omitted checks.
- Run all required quality gates before release commits and verify the published asset separately from build/test evidence.

## Out of Scope

Linux, Intel macOS, other architectures, new package-manager integrations, a universal speed promise, machine formats, and full upstream coverage.

## Further Notes

Signing and distribution behavior must be recorded from the actual release environment; none is claimed by this plan. If a clean-environment or publication check is unavailable, keep delivery incomplete and state the missing evidence.
