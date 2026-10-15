# ADR 0032: Package the first native archive with explicit partial coverage

## Status

Accepted.

## Context

The full pinned Rails manifest still contains unsupported Flay forms, while Fleek already has useful bounded checks and a truthful incomplete status. The standalone archive ticket originally depended on complete Rails Flay parity, which would otherwise prevent proving native installation behavior for the supported subset.

## Decision

Build the versioned macOS arm64 archive for Fleek 0.1.0 from the current native executable. Include Fleek's Apache 2.0 license, the statically linked Prism MIT notice, executable/reference/compiler identities, supported scope, and clean/finding/incomplete examples. Treat `Status: incomplete` with exit 1 as a valid example of honest partial behavior; do not imply that this archive completes the Rails parity gate or is the published release.

## Consequences

An extracted archive passes representative CLI checks with an empty child `PATH`, and its only dynamic library is macOS `libSystem`. Its Mach-O carries an ad hoc linker signature with no Team ID and is not notarized. The archive SHA-256 and installation evidence are recorded in the native archive receipt. Ticket 19 and downloadable release ticket 17 remain open.
