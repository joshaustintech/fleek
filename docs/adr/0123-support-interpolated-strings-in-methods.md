# ADR 0123: Support interpolated strings in method candidates

## Status

Accepted

## Context

Top-level methods with interpolated strings were marked unsupported, although Flay 2.14.4 groups renamed interpolations as similar methods. Prism's interpolation tree also weighs two more than Flay's tree for the generated example.

## Decision

Support interpolated strings and their embedded variable and statement nodes in method candidates. Reduce method mass by one per interpolated-string node to match Flay. Compare the compiled CLI with pinned Flay and use a focused mutation to protect candidate support.

## Consequences

Methods using supported interpolation expressions are analyzed with Flay-compatible mass. Other interpolation expressions remain subject to the existing method-node support boundary.
