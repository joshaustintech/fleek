# ADR 0248: Bound Rails Flay primary_abstract_class declaration

## Status

Accepted

## Context

The pinned Rails `ApplicationRecord` contains a direct `primary_abstract_class` call in its class body. Flay 2.14.4 reports no duplication for that source, while Fleek currently marks it incomplete as an unsupported class-body call.

## Decision

Accept only a receiver-free `primary_abstract_class` call with no arguments and no block as a non-candidate declaration in a simple class. Keep all other unsupported class-body calls and call shapes incomplete.

## Consequences

Issue 134 owns the public fixture, exact Flay assertion, pinned Rails check, and mutation boundary. This does not authorize arbitrary Rails macros or execute source code. Issue 97 remains open until all remaining manifest shapes resolve.
