# ADR 0160: Make method candidate translation data-driven

## Status

Accepted

## Context

Ticket 22 asks for Flay parity across method parameters, statements, control flow, and expressions. The shared candidate tree is already used for top-level and class methods, but supported Prism nodes are maintained in several independent allowlists and equality/mass branches. Adding each syntax node separately creates repeated code, mutations, fixtures, ADRs, and commits without a useful completion boundary.

## Decision

Complete ticket 22 by replacing repeated node-family allowlists and per-family equality/mass switches with one data-driven Prism-to-Flay descriptor path. Descriptors define accepted node type, child translation, identity fields, and mass adjustment; adapters handle only proven representation differences between Prism and Flay's RubyParser tree. Unsupported grammar remains explicitly incomplete. Completion is measured by generated coverage of descriptors and differential comparison with pinned Flay 2.14.4, including grouping, mass, pruning, score, locations, and ordering.

## Consequences

New syntax support should extend the translation descriptor or a documented representation adapter rather than add a detached allowlist branch. Existing fixed regression cases remain as examples; generated contracts and mutation checks prove the shared translation rules. This is an implementation boundary, not a promise to accept syntax outside pinned Prism's grammar.
