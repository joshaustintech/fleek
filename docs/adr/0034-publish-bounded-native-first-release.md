# ADR 0034: Publish the bounded native first release

## Status

Accepted.

## Context

The 0.1.0 arm64 archive passes extracted-runtime checks without Ruby or the reference analyzers, and bounded cold-runtime comparisons meet their measured targets. Full Flay parity on the pinned Rails corpus remains open in ticket 19. The archive accurately reports partial coverage and exit 1 for incomplete Flay analysis.

## Decision

Publish Fleek 0.1.0 as the first downloadable release for macOS arm64 with explicit check selection and the bounded supported syntax already documented in the archive. Include the reference versions, exact archive identity, installation steps, output and exit-status differences, and measured runtime evidence in release notes. Verify the uploaded asset by retrieving it, matching its SHA-256, extracting it, and running the installed CLI contract. Keep the full Rails Flay parity limitation visible; publication does not close ticket 19 or claim unsupported checks are complete.

## Consequences

This lets users install and evaluate the supported subset while preserving truthful coverage status. The Mach-O is ad hoc signed and not notarized. Release `v0.1.0` was published from source commit `f5380ebad9e07958f659a1820d03060622d58b97`; the downloaded asset matched the expected digest and passed the extracted-runtime contract. Ticket 19 remains open for full Rails Flay parity.
