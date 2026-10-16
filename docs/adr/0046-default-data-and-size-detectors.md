# ADR 0046: Add bounded Reek data and size detectors

## Status

Accepted.

## Context

Ticket 06 adds five Reek 6.6.0 defaults to Fleek's compiled native analyzer. These checks cover repeated parameter groups, class data shape, and method statement count. The analyzer must keep configuration and coverage behavior consistent with existing detectors.

## Decision

Implement DataClump, TooManyConstants, TooManyInstanceVariables, TooManyMethods, and TooManyStatements for bounded direct class/module and method syntax. Honor Reek's defaults and numeric settings: `max_copies: 2`, `min_clump_size: 2`, `max_constants: 5`, `max_instance_variables: 4`, `max_methods: 15`, and `max_statements: 5`. Count the instance-variable write forms Reek 6.6.0 counts: `=`, `||=`, and `&&=`; ignore other operator assignments to preserve reference parity. Preserve Reek's `initialize` exclusion for TooManyStatements. Honor detector context and path exclusions.

DataClump considers each candidate method as a possible start for a shared parameter group; an earlier method without parameters must not hide later groups. Emit every distinct supported group once. If unsupported direct methods coexist with supported clumps, retain the supported findings and return incomplete coverage. Return incomplete coverage for unsupported or ambiguous scope shapes, including `class << self` methods for TooManyStatements because the bounded direct-method scanner does not visit those bodies. Singleton method definitions (`def self.name`) are supported with Reek's `Class#self.name` context. Class-scoped detectors return clean when source has no class or module context, matching Reek's context selection. Explicit `--checks` uses the same detector implementation as default selection.

When a supported direct TooManyStatements method and an unsupported singleton-class method share a file, retain the direct finding and return incomplete coverage. The detector uses a distinct partial result so the report counts that source as analyzed and failed.

Apply the same partial-result rule when an unsupported direct method body follows a supported method. The native scanner keeps findings already collected before it encounters the unsupported body; the public contract covers both mixed-syntax paths.

For TooManyMethods, count supported direct instance methods even when nested method syntax makes scope incomplete. Preserve an over-threshold direct-method finding and return incomplete coverage; do not claim exact parity for unsupported nested definitions.

## Consequences

The default profile runs all five checks. CLI contracts compare supported findings, thresholds, exclusions, and explicit selection against pinned Reek 6.6.0. Mutation contracts remove each detector dispatch and require the public contract to fail. Unsupported nested scopes remain visible as incomplete instead of clean results.

## Evidence

`test/default_argument_api_contract.rb` covers all five default findings, instance-variable write forms, threshold changes, exclusions, explicit selection, DataClump after empty methods, multiple clumps, partial findings with incomplete coverage, singleton method parity, and unsupported nested scopes. `make check` runs native build, contracts, mutation shards, reference checks, Flay, and Reek.
