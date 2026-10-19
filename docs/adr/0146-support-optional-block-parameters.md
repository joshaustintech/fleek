# ADR 0146: Support optional block parameters in method candidates

## Status

Accepted.

## Context

Pinned Flay 2.14.4 includes method candidates whose nested blocks declare optional parameters. Prism exposes each as an `OptionalParameterNode`; rejecting it makes the whole method candidate incomplete. The block parameter list also has one unit of wrapper mass in Flay's RubyParser representation that is not represented by Prism's node count.

## Decision

Include optional block parameter nodes in candidate trees. Compare their names directly, and compare default expressions through the normal AST tree so supported literals, calls, and other supported forms preserve structural identity. Add one mass point to a `BlockParametersNode` when it contains one or more optional parameters; the adjustment belongs to the list, not each parameter.

## Consequences

Compiled CLI contracts match one optional block parameter (mass 20), two optional block parameters (mass 24), differing names, differing literal defaults, and differing supported call defaults against Flay. A one-versus-two-parameter pair matches Flay's clean result. Focused mutations protect candidate acceptance, wrapper mass, parameter names, literal values, and default-call identity.
