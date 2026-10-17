# ADR 0077: Support twelve-level nested module methods

## Status

Superseded by [ADR 0081](0081-thirteen-level-nested-module-methods.md).

## Context

Flay 2.14.4 reports module groups for direct methods under a sole nested-module chain of twelve modules. Fleek previously supported eleven and marked this reference-supported shape incomplete. Class-under-module traversal has an independent depth bound.

## Decision

Extend direct method collection under sole nested-module chains through twelve modules. Keep thirteen-module chains incomplete and preserve the separate class-under-module depth bound.

## Consequences

Historical decision: twelve-module method groups are complete; thirteen-module chains were partial at the time. ADR 0081 extends the bound through thirteen modules and keeps fourteen-module chains partial. No change is made to nested class or qualified namespace syntax.

## Evidence

Historical evidence is retained in [ADR 0081](0081-thirteen-level-nested-module-methods.md), which records the current 13/14-level contracts and mutation checks.
