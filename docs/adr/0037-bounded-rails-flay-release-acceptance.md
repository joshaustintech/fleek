# ADR 0037: Accept bounded Rails Flay coverage for the first release

## Status

Accepted.

## Context

Ticket 19's exact Rails manifest gate has consistently shown the supported Flay finding at `users_controller.rb:51,58` with the same mass and score as Flay 2.14.4, while all 25 sources remain partial because Fleek does not implement every Flay candidate shape. The selected Reek ClassVariable check analyzes all 25 sources and matches its clean reference result. Fleek reports the Flay check as incomplete and exits 1, so the manifest run cannot be mistaken for a complete Flay analysis.

The first-release specification excludes full upstream check coverage, requires explicit capability limits, and distinguishes incomplete results from success. The user-approved release boundary accepts partial coverage when the supported findings are useful and the CLI reports the limitation truthfully.

## Decision

Resolve Ticket 19 when its supported class and module method cases have exact Flay 2.14.4 fixture parity, its pinned Rails manifest comparison reproduces and explains every observed difference, Reek remains complete on that manifest, and all quality gates and review axes pass. Treat the incomplete Flay result as an accepted capability boundary for the bounded first release, not as full-manifest parity. Do not advertise complete Rails Flay coverage or convert partial Flay results into success.

Any future expansion of Flay syntax coverage requires its own reference-backed fixtures and must preserve explicit partial status until every relevant candidate shape is modeled. Reopening full-manifest parity requires a new scoped issue and evidence-based release decision.

## Consequences

Ticket 19's bounded feature is complete: paired fixtures match Flay on group kind, mass, score, classification, and ordered locations; `make rails-manifest-parity` automates the exact 25-file comparison and records Flay's matching score-48 finding, its incomplete 0/25 analyzed status and exit 1, plus Fleek Reek's matching clean findings, 25/25 coverage, and exit 0. `rails-controller-parity` delegates to this full-manifest gate. The shipped capability remains explicitly limited; full upstream Flay parity is not claimed. The unchanged report semantics and release artifact need no behavior change.
