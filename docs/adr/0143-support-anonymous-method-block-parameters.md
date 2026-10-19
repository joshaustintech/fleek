# ADR 0143: Support anonymous method block parameters

## Status

Accepted; supersedes ADR 0133's anonymous-parameter rejection.

## Context

Flay 2.14.4 includes methods with anonymous block parameters (`&`) in identical candidates. Prism represents the missing parameter name with constant ID `0`. Fleek previously treated that sentinel as unsupported; after candidate inclusion, the shared name comparator attempted to look it up in Prism's constant pool and asserted.

## Decision

Accept anonymous block parameters. Compare the optional names by presence first: both absent names match, one absent name differs, and present names use normal constant comparison. Block parameter presence still has to match and adds no candidate mass.

## Consequences

The anonymous `&` fixture matches Flay's identical group at mass 6, score 12, and lines 1 and 5. An `&` versus `&handler` fixture matches Flay's similar group with the same mass and score 6. A focused public contract protects both boundaries, and deterministic mutations protect absent-name equality and the absent-versus-present distinction. Other anonymous rest and keyword-rest forms remain separate syntax cases.
