# ADR 0119: Remove the method parameter count cap

## Status

Accepted

## Context

Flay 2.14.4 considers methods with more than eight positional parameters, but Fleek rejected them with a fixed count guard. Parameter collection and equality already iterate parsed parameter arrays, so the guard was an unrelated syntax ceiling.

## Decision

Accept any number of supported required and literal-default optional positional parameters. Keep rejecting rest, post, keyword, keyword-rest, and block parameters until their Flay translation is implemented. Check optional-parameter mass addition for overflow. A generated 40-parameter CLI contract compares group mass, score, locations, and completeness against Flay; a focused mutation restores the eight-parameter rejection.

Required-parameter arity remains part of the candidate tree shape, so the former separate arity mutation became equivalent after removing the count guard and was dropped.

## Consequences

Parameter support scales with parsed input size and available memory instead of an arbitrary count. Other method-shape and candidate-storage boundaries remain independently checked.
