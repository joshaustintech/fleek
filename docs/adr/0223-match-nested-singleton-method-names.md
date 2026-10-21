# Match nested singleton method names

Accepted for Ticket 86.

## Context

Reek 6.6.0 reports uncommunicative names on singleton methods declared with `def self.name` inside a direct nested class and uses the qualified nested class context. Fleek's method-name scanner only accepted one class or module.

## Decision

Support direct method definitions in one direct nested class within a single top-level class for `UncommunicativeMethodName`. Pass the qualified class context to the existing name-pattern analyzer and preserve configured reject/accept patterns. Deeper nesting remains incomplete.

## Consequences

The contract covers a one-letter singleton method, a descriptive control, configuration that accepts the one-letter method and rejects the descriptive method, and a deeper unsupported class chain.
