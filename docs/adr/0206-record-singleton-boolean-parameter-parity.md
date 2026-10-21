# ADR 0206: Record singleton BooleanParameter parity

## Status

Accepted for Ticket 69.

## Context

Reek 6.6.0 reports boolean defaults on singleton methods and ignores nonboolean defaults. Fleek's existing bounded analyzer already matched the keyword and instance-method cases, but the positional singleton case lacked a dedicated contract.

## Decision

Keep the existing native behavior. Record compiled-CLI parity for `def self.requeue(force = true)` and a numeric default control, and verify that explicit selection still honors a configured detector disablement.

## Consequences

The contract protects finding identity, method definition line, and singleton context without expanding the analyzer's supported parameter forms.

## Evidence

Pinned Reek 6.6.0 and Fleek produce the same singleton finding. The numeric default is clean. Under an explicit selection with `BooleanParameter` disabled, Reek returns no finding and Fleek reports the configured disablement before analysis.
