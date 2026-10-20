# ADR 0193: Bound Flay legacy parser mode

## Status

Accepted for Ticket 55.

## Context

Flay 2.14.4 defaults to Prism's RubyParser-compatible translation and switches to the separate `RubyParser` gem for `--legacy`. The project bundle did not include RubyParser, so the pinned reference command failed with `LoadError` before comparison. The native Fleek implementation must not execute or shell out to a parser over analyzed source.

## Decision

Pin `ruby_parser` 3.22.0 in the project bundle so Flay's legacy reference path is reproducible. Fleek accepts `--legacy` only with Flay checks, strips it from Reek source inputs, and continues through native Prism analysis for the shared supported syntax. No RubyParser code is loaded by Fleek.

RubyParser 3.22.0 rejects Ruby 4's line-leading `&&`, `||`, `and`, and `or` continuations even though Flay's default Prism mode analyzes them. When one of those AST shapes is present with `--legacy`, Fleek marks the selected source incomplete and reports the affected path instead of treating Flay's skipped file as clean. Other syntax outside the tested shared grammar remains subject to the existing incomplete-result boundary; this ADR does not claim full RubyParser parser parity.

## Consequences

The supported shared-syntax case has the same findings, mass, score, and locations under Flay default, Flay legacy, Fleek default, and Fleek legacy. The known parser-difference case has a Flay default finding, a Flay legacy parse-error warning with zero score, a Fleek default finding, and a Fleek legacy incomplete result. The CLI status difference preserves Fleek's coverage contract.

## Evidence

With Flay 2.14.4 and RubyParser 3.22.0, `duplication_methods_array_expression.rb` reports identical mass 38 and score 76 in both parser modes. The `ruby4_*_duplicate.rb` fixtures report a similar mass/score 36 group in default mode; legacy emits the corresponding parse error and skips each file. The compiled public Fleek contract checks matching shared-syntax findings and locations, each of the four parser-boundary forms, exact coverage and source identity, streams, normalized status, and Reek-only rejection.
