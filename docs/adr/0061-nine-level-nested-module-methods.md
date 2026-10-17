# ADR 0061: Support nested module methods with a fixed depth bound

## Status

Superseded by [ADR 0069](0069-eleven-level-nested-module-methods.md).

## Context

Flay 2.14.4 reports a complete module group for matching direct methods inside a sole chain of nested modules. Fleek supports these bounded scopes while keeping candidate storage and recursive traversal explicitly finite.

## Decision

Support sole nested-module method chains through ten levels. Store up to ten module names in a candidate and retain up to ten names while walking the constant path. Mark chains deeper than ten incomplete. Preserve the existing partial result behavior for the unsupported deeper scope.

## Consequences

Historical result: ten-level module method groups are eligible for complete reporting; eleven-level chains remain partial. ADR 0069 extends direct module method chains through eleven levels and keeps twelve-level chains partial. The class-under-module and relative-qualified-class bounds remain independent.

## Evidence

`test/fixtures/duplication_nine_level_module_boundary.rb` matches Flay's similar module group at mass/score 48 and declaration lines 1 and 25. `test/fixtures/duplication_ten_level_module_boundary.rb` matches Flay's mass/score 50 group at lines 1 and 27 with complete coverage. `test/fixtures/duplication_eleven_level_module_boundary.rb` matches Flay's mass/score 52 group at lines 1 and 29 while Fleek reports incomplete coverage. The public contract checks all three results, and the `Flay eleventh nested module boundary` mutation raises the guard to eleven so the boundary contract must detect the regression.
