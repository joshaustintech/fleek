# ADR 0106: Reject check-inapplicable options before analysis

## Status

Accepted.

## Context

Ticket 23 requires Flay-specific settings to be validated before analysis. A Reek-only invocation with `--mass` previously treated the option and its value as failed source paths, then still analyzed valid sources and emitted findings.

## Decision

Validate check-specific options before dispatching a single selected check. Reject `--mass` on Reek-only selections and reject `--reek-config` on Flay-only selections. Combined Flay/Reek invocations continue routing each supported option to its owning analyzer.

## Consequences

Invalid cross-check settings produce an input error before any analyzer runs, so no findings can accompany the diagnostic. The compiled CLI contract and a named mutation protect this ordering. Repeated, malformed, and unsupported Flay settings remain covered by their existing validation path or future Ticket 23 slices.
