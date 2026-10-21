# Count TooManyStatements in singleton-class methods

Accepted for Ticket 85.

## Context

Reek 6.6.0 applies `TooManyStatements` to methods directly declared in `class << self` bodies. Fleek detected singleton-class syntax and marked the selected source incomplete even when the method bodies were supported.

## Decision

Analyze direct methods in `class << self` alongside direct class methods. Use the same configured statement threshold and Reek method context. If an unsupported method body appears, retain any supported findings and mark the source incomplete. Other singleton-class receiver or placement shapes remain incomplete.

## Consequences

The contract covers a method at the default threshold, one over it, the configured threshold, and mixed supported and unsupported singleton methods.
