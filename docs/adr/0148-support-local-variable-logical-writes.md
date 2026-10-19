# ADR 0148: Support local-variable logical writes in method candidates

## Status

Accepted

## Context

Prism represents `&&=` and `||=` as dedicated local-variable write nodes, separate from `LocalVariableOperatorWriteNode`. Flay 2.14.4 includes each node in method candidates and adds two mass points. It classifies same-operator writes with different target names as similar, but does not group `&&=` against `||=`.

## Decision

Accept Prism `LocalVariableAndWriteNode` and `LocalVariableOrWriteNode` in method candidate trees, add two mass points per node, and compare target names for each node type. Keep the two node types structurally distinct.

## Consequences

Compiled CLI contracts compare identical `&&=` and `||=` methods (mass 20), target-name changes as similar groups, and `&&=` versus `||=` as a clean no-group result. Focused mutations protect candidate support, mass, and target-name identity for both node types.
