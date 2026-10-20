# ADR 0197: Bound unused private method analysis

## Status

Accepted for Ticket 60.

## Context

Reek 6.6.0 treats `UnusedPrivateMethod` as opt-in. Fleek already preserved the opt-in choice in configuration reports but could not analyze the detector. The supported implementation compiler does not provide Reek's runtime object model, so a broad approximation could silently miss calls or visibility changes.

## Decision

Support one simple class with direct instance methods and bare `private`, `public`, or `protected` visibility changes. Analyze implicit or explicit-`self` calls across those method bodies; a private method called by another method is used. Unsupported scopes, singleton methods, nested methods, and blocks return incomplete analysis. Keep the detector out of unconfigured defaults, run it for an explicit selection, and run it in defaults only when Reek configuration enables it. Preserve configured per-path disables.

## Consequences

This bounded call graph matches the pinned basic unused and directly called private-method cases without pretending to support aliasing, reflection, inherited calls, or dynamic dispatch. Unsupported syntax remains visible as incomplete coverage. Configuration can enable the detector without changing the default check set.

## Evidence

The public contract compares context, line, detector message, coverage, streams, and status against Reek 6.6.0 for an unused private method and for a private method called by a public method. Existing contracts protect default exclusion, explicit selection, configured enablement, scoped precedence, and configured disablement.
