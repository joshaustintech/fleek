# ADR 0205: Match LongParameterList around block bodies

## Status

Accepted for Ticket 68.

## Context

Reek 6.6.0 applies `LongParameterList` to method definitions. It ignores callback block parameter lists, even when they exceed `max_params`. Fleek previously marked any method body containing a block incomplete, which lost the method's otherwise-supported parameter result.

## Decision

Count only the enclosing method's parameters, using the configured maximum and Reek's `initialize` override. Do not reject or count block parameters found in the method body. Continue to validate the method's parameter-list AST; other detector scope boundaries remain unchanged.

## Consequences

Methods containing blocks can be analyzed completely without treating callback parameters as method parameters. Findings retain the enclosing method context and definition line for default and configured thresholds.

## Evidence

The compiled CLI contract verifies a block-only source is clean and complete, checks enclosing method parameter counts at the default threshold and threshold+1, and repeats the comparison with a configured threshold. Focused mutations cover missing findings and block-body completeness.
