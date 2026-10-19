# ADR 0156: Support bare-call positional defaults

## Status

Superseded by [ADR 0158](0158-share-optional-default-policy.md)

## Context

Pinned Flay 2.14.4 analyzes optional positional parameters defaulted to a bare, receiverless method call with no arguments or block. Different call names produce a similar method group at mass and score 10. Fleek previously rejected these otherwise shared-parseable methods.

## Decision at adoption

Accept only bare receiverless calls with no arguments and no block as positional optional defaults. Retain the existing two mass units and compare call names for identical-versus-similar classification. Keep optional keyword defaults on their separately verified literal/constant boundary.

## Consequences

This bounded default form matches Flay without implying support for arbitrary default expressions. A dedicated compiled-CLI contract and focused mutations cover acceptance, mass, and call-name identity.
