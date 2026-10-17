# ADR 0067: Support classes under ten nested modules

## Status

Superseded by [ADR 0078](0078-eleven-level-nested-module-classes.md).

## Context

Flay 2.14.4 reports module groups for direct class methods under a sole nested-module chain of ten modules. Fleek supported eight modules and reported this reference-supported shape incomplete. This class-under-module bound is independent of direct module-method traversal.

## Decision

Extend direct class collection under sole nested-module chains through ten modules. Preserve the separate direct module-method bound and mark eleven-module class paths incomplete.

## Consequences

Historical decision: ten-module class groups are complete; eleven-module class paths were partial at the time. ADR 0078 extends the bound through eleven modules and keeps twelve-module chains partial. No change is made to qualified module syntax or nested class depth.

## Evidence

Historical evidence is retained in [ADR 0078](0078-eleven-level-nested-module-classes.md), which records current 11/12-level contracts and mutation checks.
