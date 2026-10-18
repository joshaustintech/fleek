# ADR 0114: Match Flay block-expression candidates

## Status

Accepted

## Context

Flay 2.14.4 reports a similar method group for two `map` calls with block parameters, at mass 16. Fleek rejected the candidate because its bounded method AST did not accept Prism block nodes. Prism also represents block parameters through block-parameter and parameter wrapper nodes.

## Decision

Accept block, block-parameter, parameter-list, and required-parameter nodes inside method candidate trees. Compare required block parameter names when classifying candidates. Apply a two-unit mass correction per block to align Prism's tree count with Flay's translated `:iter` candidate. Continue to reject unsupported block parameter forms through the existing fail-closed node support check.

The public contract compares Fleek and unchanged Flay output for two same-named methods whose block parameter names differ while their bodies remain otherwise equal. It checks Flay's mass, group kind, source locations, and complete coverage. Focused mutations disable candidate support, mass correction, and block parameter identity.

## Consequences

Simple blocks with required parameters are supported in method candidates. Other block parameter forms and block-specific AST nodes remain explicitly unsupported until separately matched against Flay. Dynamic tree storage must reserve a parent's closing marker after child traversal, including when the child is a block.
