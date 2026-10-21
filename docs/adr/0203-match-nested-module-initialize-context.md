# ADR 0203: Match nested ModuleInitialize context

## Status

Accepted for Ticket 66.

## Context

Reek 6.6.0 reports `ModuleInitialize` for a direct `initialize` method in a module nested one level inside another module. Fleek supported one simple module and reported nested module declarations as incomplete.

## Decision

Support exactly one direct nested module declaration with no classes or other module scopes. Scan only the nested module's direct instance methods. Report the qualified module name and the nested module declaration line. Keep deeper, sibling, wrapped, or mixed class/module scope trees incomplete.

## Consequences

Nested-module findings retain Reek's context and source line, while ordinary methods remain clean. Qualified configuration exclusions can target the reported module name. The support boundary stays finite and explicit.

## Evidence

The compiled CLI contract compares the nested finding and clean method behavior with pinned Reek 6.6.0, then verifies a qualified module exclusion. Focused mutations cover scope acceptance, finding presence, and qualified context.
