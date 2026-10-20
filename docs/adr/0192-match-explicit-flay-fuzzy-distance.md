# ADR 0192: Match explicit Flay fuzzy distance

## Status

Accepted for Ticket 54.

## Context

Ticket 53 matched Flay 2.14.4 fuzzy distance one for bounded method candidates. Flay's `--fuzzy` accepts an optional integer; omitted distance means one, repeated options use the last value, and integer values at or below zero produce no fuzzy findings. It removes up to the requested number of direct code children when comparing candidates.

## Decision

Parse `--fuzzy` with Ruby `Integer` semantics. A bare option means distance one when it has no following non-option token; place source paths before a bare option. Attached (`--fuzzy=2`) and separate (`--fuzzy 2`) integer values are accepted. Repeated occurrences use the last value. Zero and negative values disable fuzzy findings. A malformed attached value or non-integer token after a bare option fails before analysis, matching Flay's optional-argument behavior.

For supported method candidates, compare each candidate after removing up to the requested number of direct roots. Keep the size and average-mass caps established in ADR 0191. Cap the internal distance at ten; larger values cannot expose more supported method candidates under the existing size cap. Reek-only selections reject fuzzy options, and combined analysis strips the option and its optional integer value from Reek inputs.

## Consequences

Default fuzzy output remains distance one. Explicit distances work on the same bounded top-level and class method candidates. Unsupported candidate types remain incomplete under the existing native syntax boundary. Non-integer attached values now receive a Fleek diagnostic before analysis.

## Evidence

The compiled public CLI contract compares Flay 2.14.4 and Fleek for distance one versus two, attached and separate values, repeated-option precedence, zero, negative values, bare-option default, malformed attached values, and Reek-only rejection. The distinguishing pair has two extra direct statements and reports mass/score 40 only at distance two.
