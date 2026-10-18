# ADR 0118: Grow the duplication report buffer

## Status

Accepted

## Context

Scoped method candidate storage became size-driven, but the native duplication report still used an 8,192-byte static buffer. A generated 2,200-method Flay-compatible group exceeded that buffer and caused incomplete analysis despite successful candidate collection.

## Decision

Replace the fixed report buffer with a process-owned buffer that grows geometrically as groups are appended. Check capacity and arithmetic overflow, preserve a trailing NUL for the Spinel FFI string, and reject group-mass/score overflow before appending. A generated public CLI contract crosses the old capacity, compares mass with Flay, and checks group kind, score, all expected ordered locations, and complete coverage. A focused mutation caps buffer growth at the old size.

## Consequences

Large duplicate groups can be serialized without a fixed byte ceiling. The allocation is retained for reuse for the process lifetime and reset between source analyses.
