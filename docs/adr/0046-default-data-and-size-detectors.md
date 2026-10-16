# ADR 0046: Add bounded Reek data and size detectors

## Status

Accepted.

## Context

Ticket 06 adds five Reek 6.6.0 defaults to Fleek's compiled native analyzer. These checks cover repeated parameter groups, class data shape, and method statement count. The analyzer must keep configuration and coverage behavior consistent with existing detectors.

## Decision

Implement DataClump, TooManyConstants, TooManyInstanceVariables, TooManyMethods, and TooManyStatements for bounded direct class/module and method syntax. Honor Reek's defaults and numeric settings: `max_copies: 2`, `min_clump_size: 2`, `max_constants: 5`, `max_instance_variables: 4`, `max_methods: 15`, and `max_statements: 5`. Preserve Reek's `initialize` exclusion for TooManyStatements. Honor detector context and path exclusions.

DataClump considers each candidate method as a possible start for a shared parameter group; an earlier method without parameters must not hide later groups. Emit every distinct supported group once. If unsupported direct methods coexist with supported clumps, retain the supported findings and return incomplete coverage. Return incomplete coverage for unsupported or ambiguous scope shapes, including `class << self` methods for TooManyStatements because the bounded direct-method scanner does not visit those bodies. Singleton method definitions (`def self.name`) are supported with Reek's `Class#self.name` context. Class-scoped detectors return clean when source has no class or module context, matching Reek's context selection. Explicit `--checks` uses the same detector implementation as default selection.

## Consequences

The default profile runs all five checks. CLI contracts compare supported findings, thresholds, exclusions, and explicit selection against pinned Reek 6.6.0. Mutation contracts remove each detector dispatch and require the public contract to fail. Unsupported nested scopes remain visible as incomplete instead of clean results.

## Evidence

`test/default_argument_api_contract.rb` covers all five default findings, threshold changes, exclusions, explicit selection, DataClump after empty methods, multiple clumps, partial findings with incomplete coverage, singleton method parity, and unsupported nested scopes. `make check` runs native build, contracts, mutation shards, reference checks, Flay, and Reek.
