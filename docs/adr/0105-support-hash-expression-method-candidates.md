# ADR 0105: Support hash expressions in method candidates

## Status

Accepted.

## Context

Ticket 22's next paired Flay case uses a hash expression inside class methods. Adding the hash node exposed a mass mismatch: Fleek counted each association wrapper while Flay 2.14.4 excludes hash association wrappers from candidate mass.

## Decision

Accept `HashNode` and treat `AssocNode` nodes whose direct parent is `HashNode` as massless in class-method fingerprints. Keep traversing association keys and values so their expression structure remains part of equality.

## Consequences

The paired compiled CLI/Flay contract matches the similar class group at mass/score 62 and lines 1/8. Separate named mutations prove that hash candidates are collected and association wrappers remain excluded from mass.
