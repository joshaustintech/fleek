# ADR 0061: Support nine-level nested module methods

## Status

Accepted.

## Context

Flay 2.14.4 reports a complete module group for matching direct methods inside a sole chain of nine nested modules. Fleek previously supported eight levels and marked this reference-supported shape incomplete. Extending without an explicit bound would make native candidate storage and recursive traversal unbounded.

## Decision

Extend the fixed nested-module method bound from eight levels to nine. Store up to nine module names in a candidate, retain up to nine names while walking the constant path, and mark chains deeper than nine incomplete. Preserve the existing partial result behavior for the unsupported deeper scope.

## Consequences

Nine-level module method groups are eligible for complete reporting. Ten-level chains remain partial while retaining any independent supported findings. The class-under-module and relative-qualified-class bounds are unchanged.

## Evidence

`test/fixtures/duplication_nine_level_module_boundary.rb` matches Flay's similar module group at mass/score 48 and declaration lines 1 and 25. `test/fixtures/duplication_ten_level_module_boundary.rb` matches Flay's mass/score 50 group at lines 1 and 27 while Fleek reports incomplete coverage. The public contract checks both results, and the `Flay tenth nested module boundary` mutation raises the guard to ten so the ten-level contract must detect the regression.
