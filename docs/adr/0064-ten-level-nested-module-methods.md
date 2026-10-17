# ADR 0064: Support ten-level nested module methods

## Status

Accepted.

## Context

Flay 2.14.4 reports complete module groups for matching direct methods inside a sole chain of ten nested modules. Fleek stopped at nine, despite candidate storage already having room for ten scope names after the qualified-path extension.

## Decision

Extend sole nested-module method traversal through ten module levels. Keep the traversal and candidate storage bounded, and mark eleven-level chains incomplete.

## Consequences

Ten-level nested module groups are complete. Deeper chains keep incomplete coverage while independent candidates retain their existing behavior. Direct classes under nested modules keep their separate seven-module limit.

## Evidence

`test/fixtures/duplication_ten_level_module_boundary.rb` matches Flay 2.14.4 at similar `:module` mass/score 50 and lines 1/27. `test/fixtures/duplication_eleven_level_module_boundary.rb` matches Flay at mass/score 52 and lines 1/29 while Fleek reports incomplete status. The public contract checks both and the eleventh-level mutation protects the new boundary.
