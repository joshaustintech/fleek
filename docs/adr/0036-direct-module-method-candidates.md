# ADR 0036: Analyze direct methods in a single module scope

## Status

Accepted.

## Context

The pinned Rails corpus has helper methods declared directly inside modules. Ticket 19 already supports bounded methods inside classes, but treats these module methods as unsupported and incomplete. The Flay reference can report `:defn` groups from these methods.

## Decision

For a single module with a simple constant name, collect direct instance methods with the same bounded candidate analyzer used for class methods. Retain the existing limits on method count, parameter forms, body AST, and partial reporting. Empty modules remain clean. Nested modules, mixed direct methods and class declarations, and unsupported body entries remain partial or unsupported; do not claim general module parity.

## Consequences

A paired fixture matches Flay 2.14.4 at similar `:defn` mass/score 48 and ordered lines 2/9. A mutation proves the module candidate boundary. The pinned 25-file run remains unchanged: same score-48 `UsersController` group, 0/25 files fully analyzed, 25 partial, and exit 1. Real helper methods contain additional body and parameter forms, and class-level declarations elsewhere remain partial; Ticket 19 stays open.
