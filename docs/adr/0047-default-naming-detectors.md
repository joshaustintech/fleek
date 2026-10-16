# ADR 0047: Add bounded Reek naming detectors

## Status

Accepted.

## Context

Ticket 07 adds Reek 6.6.0's four uncommunicative-name checks to the default profile. Reek allows detector-specific `reject` and `accept` regular expressions. The native Prism analyzer can cover common direct method syntax, while nested and less common scopes require explicit coverage limits.

## Decision

Implement UncommunicativeMethodName, UncommunicativeModuleName, UncommunicativeParameterName, and UncommunicativeVariableName in the default profile. Use the pinned Reek defaults and accept newline-delimited `reject` and `accept` lists through the existing configuration parser and POSIX regular-expression matcher.

Match messages, contexts, and source lines for direct method names, simple class/module constant names, required/optional/post/keyword method parameters, and local assignments in direct method bodies. Preserve Reek's rule that unused underscore-prefixed parameters are ignored unless used. Report qualified class/module paths, class/module declarations whose Prism node ranges are contained by another declaration, singleton methods, rest/block parameters, nested scope shapes, block-variable arguments, and class/module variable assignments as unsupported. Skip findings for unsupported nested declarations, retain earlier supported findings, and return incomplete coverage.

## Consequences

All four checks run by default and can be selected explicitly. Configuration and findings parity are covered against pinned Reek. The bounded scanners do not claim whole-file naming parity; unsupported forms remain visible in coverage. Mutations that suppress each detector's findings must be caught by public contracts.

## Evidence

`test/default_argument_api_contract.rb` covers default and custom regex parity for each detector, unsupported scopes, and retained VariableName findings with incomplete coverage. `test/mutation_contract.rb` mutates each detector's reject-pattern behavior and requires the public contract to fail. `make check` validates the native build, contracts, mutations, Flay, and Reek.
