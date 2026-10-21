# Preserve combined analysis outcomes

Accepted for Ticket 94.

## Context

Fleek can run Flay and Reek together, with independent selection and exclusion rules. A combined report may contain verified findings while another selected analysis is incomplete. The report and process status must preserve both facts without mixing per-check source accounting.

## Decision

Keep the public outcome meanings consistent across default, explicit subset, opt-in, and combined runs: exit 0 means complete with no findings; exit 2 means complete with findings; exit 1 means incomplete. Incomplete takes precedence when any selected analysis has unresolved input, while findings already produced by another selected analysis remain visible. Report source counts independently for Flay and Reek, and apply their exclusion controls only to their own analysis.

## Consequences

The focused invocation and combined contracts cover the bounded selection matrix and assert status, coverage, findings, and section order against pinned analyzer behavior where applicable. This ticket adds no implementation because existing public contracts already verify these outcomes. It does not claim that all analyzer combinations or unsupported syntax are complete.
