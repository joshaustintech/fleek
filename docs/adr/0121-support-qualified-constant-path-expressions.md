# ADR 0121: Support qualified constant-path expressions

## Status

Accepted

## Context

Method bodies containing `Namespace::Converter` were marked unsupported even though qualified constant paths are common Ruby expressions and Flay 2.14.4 can analyze them.

## Decision

Include Prism constant-path nodes in method candidate trees and compare each terminal constant name with Flay's value semantics. A public contract checks identical qualified paths against Flay's group mass, classification, locations, and coverage, then checks that a changed terminal name remains ungrouped. Focused mutations remove path support and terminal-name comparison.

## Consequences

Qualified constant paths can participate in supported method expressions. Other unsupported Prism node types remain explicit incomplete results until separately compared with Flay.
