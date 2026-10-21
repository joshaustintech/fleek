# Record Rails detector residuals

Accepted for Ticket 96.

## Context

The pinned Rails manifest exercises all 29 Reek detectors and Flay, but many selected files remain unsupported or produce semantic differences. The existing manifest contract intentionally covers only a partial set and must not imply full parity. An opt-in `UnusedPrivateMethod` run also exposed a Fleek crash on an ordinary framework superclass.

## Decision

Keep the existing partial parity contract unchanged. Record every detector's pinned reference result, Fleek result, findings, coverage and source-shape failures in an evidence receipt. Leave unresolved behavior explicitly incomplete and assign it to the existing residual tickets 97–101. Track the distinct `UnusedPrivateMethod` framework-subclass crash as its own minimal child, issue 127, with the pinned reference expectation and public CLI reproduction.

## Consequences

Ticket 96 is an inventory and evidence slice, not analyzer completion. A matching finding set does not count as parity when source coverage is incomplete. Parent issue 24 and gate 102 remain open until all residual tickets close. Future implementation tickets can use the receipt to select bounded cases without repeating the full census.
