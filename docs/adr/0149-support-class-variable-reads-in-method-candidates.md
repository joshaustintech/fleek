# ADR 0149: Support class-variable reads in method candidates

## Status

Accepted

## Context

Flay 2.14.4 includes class-variable reads inside method candidates. Two methods that read the same class variable match at mass 12; changing only the variable name keeps the group but classifies it as similar.

## Decision

Accept Prism `ClassVariableReadNode` in method candidate trees and compare its name when classifying candidate identity. The node uses the ordinary Flay mass with no adjustment.

## Consequences

Compiled CLI contracts compare identical and renamed class-variable reads against pinned Flay for kind, mass, score, locations, and coverage. Focused mutations protect candidate support and name identity.
