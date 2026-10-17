# ADR 0069: Support eleven-level nested module methods

## Status

Superseded by [ADR 0077](0077-twelve-level-nested-module-methods.md).

## Context

Flay 2.14.4 reports module groups for direct methods under a sole nested-module chain of eleven modules. Fleek supported ten modules and marked this reference-supported shape incomplete. Class-under-module traversal has an independent depth bound.

## Decision

Extend direct method collection under sole nested-module chains through eleven modules. Keep twelve-module chains incomplete and preserve the separate class-under-module depth bound.

## Consequences

Historical decision: eleven-module method groups are complete; twelve-module method chains were partial at the time. ADR 0077 extends the bound through twelve modules and keeps thirteen-module chains partial. No change is made to nested class or qualified namespace syntax.

## Evidence

Historical evidence is retained in [ADR 0077](0077-twelve-level-nested-module-methods.md), which records the current 12/13-level contracts and mutation checks.
