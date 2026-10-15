# ADR 0025: Analyze class methods in one-level namespaces

## Status

Accepted.

## Context

The pinned Rails manifest wraps Action Cable classes in `ApplicationCable` modules. Fleek previously rejected the module node before inspecting its child class, even when that class's method candidates fit the supported Flay grammar.

## Decision

Allow one-level module namespaces to contain direct simple class declarations for Flay candidate collection; multiple top-level namespaces are permitted in one selected source. Continue rejecting deeper namespace nesting. Other namespace-body statements are skipped only with partial status; module-level methods are not treated as class methods. Preserve FFI declaration modules as their existing separate input form.

## Consequences

The public CLI fixture compares a namespace-wrapped class-method group against Flay 2.14.4. The pinned Rails corpus still has incomplete Flay coverage because method parameters, common Rails body AST forms, and module-level helper methods remain unsupported; this extension does not close the 25-file gate.
