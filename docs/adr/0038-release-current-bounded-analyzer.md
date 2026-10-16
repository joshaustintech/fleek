# ADR 0038: Publish the current bounded analyzer as a new release

## Status

Accepted.

## Context

The published `v0.1.0` tag points to `f5380ebad9e07958f659a1820d03060622d58b97`. `main` contains later Flay behavior, including literal optional parameters and direct module-method candidates. The committed `v0.1.0` archive and live GitHub asset still contain the older binary. Users downloading the only release cannot run the current resolved Ticket 19 behavior.

## Decision

Preserve `v0.1.0` and publish the current bounded analyzer as `v0.2.0`. Build the archive from the current main source after the version bump. Include a module-method example and verify it from the extracted binary with an empty child `PATH`. Re-measure the current binary on the identical immutable reference workloads before claiming current runtime targets. Keep the Ticket 19 boundary from [ADR 0037](0037-bounded-rails-flay-release-acceptance.md): unsupported Flay candidates remain partial and combined analysis exits incomplete.

## Consequences

The release tag, archive identity, installation guide, CLI version, root README, performance receipt, project spec status, and downloaded-artifact proof must all identify the same current release. The old tag and assets remain reproducible historical artifacts. The release still supports only macOS arm64 and is not Developer ID signed or notarized.
