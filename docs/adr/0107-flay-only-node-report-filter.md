# ADR 0107: Preserve Flay totals when filtering node types

## Status

Accepted.

## Context

Ticket 23 needs parity for Flay's `--only NODE` selector. In pinned Flay 2.14.4, the selector filters displayed groups and per-file contributions after computing all groups. The total duplication score remains unfiltered, a selector with no matching groups exits clean, and repeated selectors use the last value.

## Decision

Accept one or more `--only NODE` pairs for Flay. Filter printed groups and per-file scores by the last selected node while preserving the full computed total. Use the filtered group set to choose clean versus findings status. Reject a missing node and reject the option on Reek-only selections before analysis; route it away from Reek in combined runs.

## Consequences

Report total and visible contributions intentionally describe different scopes, matching Flay. The differential contract and named mutations cover filtering, total preservation, repeated-option precedence, and check applicability.
