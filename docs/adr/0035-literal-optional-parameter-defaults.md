# ADR 0035: Support literal optional defaults in Flay class methods

## Status

Accepted.

## Context

Ticket 19's pinned Rails corpus contains class methods with optional positional parameters. Rejecting every optional parameter made otherwise analyzable methods incomplete. Flay 2.14.4 counts a scalar optional parameter and its default in similar method mass, and different default literals prevent identical classification.

## Decision

Accept up to eight combined required and optional positional parameters in bounded class methods. Restrict optional defaults to integer, string, symbol, true, false, or nil literals. Add the optional node and its literal value to method mass, and include parameter names and default values in identical-method comparison. Flay does not group methods with different optional-parameter counts, so exclude those pairs from similar grouping too. Continue rejecting rest, post, keyword, keyword-rest, block, and non-literal defaults as incomplete.

## Consequences

Paired fixtures match Flay 2.14.4 at mass/score 52 with the same locations and similar classification when integer defaults differ. A second reference-backed fixture covers string, symbol, boolean, and nil defaults; a focused mutation protects symbol acceptance. A different optional-parameter count matches Flay's no-group result, protected by its own mutation. Other mutations protect parameter acceptance, the literal boundary, mass, and default identity. The pinned 25-file Rails manifest still reports the same score-48 finding but all 25 sources remain partial because other method bodies, module helper methods, and class-level declarations are unsupported; this slice does not close ticket 19.
