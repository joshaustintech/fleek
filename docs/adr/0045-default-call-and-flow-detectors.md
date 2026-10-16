# ADR 0045: Add bounded Reek call and flow detectors

## Status

Accepted.

## Context

Ticket 05 adds seven Reek 6.6.0 default detectors to Fleek's Spinel-compiled native analyzer. The parser and reporting paths must remain bounded and expose unsupported source as incomplete coverage.

## Decision

Implement DuplicateMethodCall, FeatureEnvy, ManualDispatch, MissingSafeMethod, NestedIterators, NilCheck, and RepeatedConditional on supported direct method/class syntax. Keep syntax outside each detector's stated scope incomplete. Match pinned Reek findings and preserve line, context, name, and message formatting.

Honor `DuplicateMethodCall.max_calls` and regex `allow_calls`; `NestedIterators.max_allowed_nesting` and regex `ignore_iterators` including Reek defaults `tap` and `Tempfile.create`; and `RepeatedConditional.max_ifs`. Honor detector exclusions for MissingSafeMethod and existing context/path exclusions for other findings. Keep YAML list parsing limited to these known settings and block-list syntax.

## Consequences

The default profile runs all seven checks. Tests compare each supported detector and configured setting with pinned Reek 6.6.0 and mutation contracts prove findings remain observable. Block-list values aggregate within a setting, a more-specific scope replaces a global list, and an explicit empty list clears inherited values. Unsupported AST shapes return incomplete status instead of false-clean results. Pattern matching uses POSIX extended regular expressions, the bounded native runtime available to the compiled analyzer.

## Evidence

`test/default_argument_api_contract.rb` checks default parity, numeric settings, allow-call patterns, ignored iterators, and MissingSafeMethod exclusions. `make check` runs the full native build, contracts, three mutation shards, Flay, Reek, and reference checks.
