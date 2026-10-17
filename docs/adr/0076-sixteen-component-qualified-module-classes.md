# ADR 0076: Support sixteen-component qualified module class paths

## Status

Superseded by [ADR 0080](0080-seventeen-component-qualified-module-classes.md).

## Context

Flay 2.14.4 reports class-method module groups under relative qualified module paths with sixteen constant components. Fleek stopped at fifteen. Candidate identity and module path buffers need seventeen constant slots: sixteen module names plus the class name.

## Decision

Expand both fixed buffers to seventeen names and support direct classes with supported methods under relative qualified module paths through sixteen constant components. Keep seventeen-component paths incomplete.

## Consequences

Historical decision: sixteen-component groups are complete; seventeen-component paths were partial at the time. ADR 0080 extends qualified paths through seventeen components and keeps eighteen-component paths partial.

## Evidence

Historical evidence is retained in [ADR 0080](0080-seventeen-component-qualified-module-classes.md), which records the current 17/18-component contracts and mutation checks.
