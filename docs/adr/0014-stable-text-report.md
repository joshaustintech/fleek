# ADR 0014: Stable text report

## Status

Accepted.

## Context

Ticket 08 requires output that humans and agents can parse without guessing, while machine formats remain out of scope. Previous CLI output mixed bare source names, warning text, checks, and repeated per-source status lines. Pinned Spinel does not implement Ruby `String#dump`, so it cannot be used as the path-field escaping primitive.

## Decision

Analysis emits stable text report version 1 with these sections in order: report version, pinned references, selected checks, checks run, scope limits, selected sources, findings, coverage, status. A source row has a double-quoted source field and `included`, `excluded`, or `failed` scope. Failed input paths appear in Sources as failed rows and keep their detailed diagnostics on stderr, including in mixed good/failed runs. A finding row has check, source, line list, context, name, and message fields. The message preserves Reek's finding wording and URL.

Quoted fields escape backslash, double quote, tab, line feed, and carriage return as `\\`, `\"`, `\t`, `\n`, and `\r`. Other UTF-8 characters remain literal. Paths in diagnostics use the same quoted representation. Output never requires color.

Findings and report structure go to stdout; diagnostics go to stderr. `Checks selected` identifies requested supported coverage; `Checks run` identifies a check invoked for at least one non-excluded Ruby input. Invocation counts as a run even when parsing or an unsupported form fails; those inputs count as failures and status is incomplete. `Checks run` is `none` when all inputs are excluded before invocation. Coverage reports selected, successfully analyzed, failed, and excluded source counts. Clean and finding-producing sources count as analyzed; excluded sources are separate. Status is `complete`, `findings`, or `incomplete`, matching exit codes 0, 2, and 1.

Named stdin sources matched by `exclude_paths` are reported as excluded, with no check run, zero analyzed sources, incomplete status, and exit 1. Reek 6.6.0 returns exit 0 for that same excluded input; Fleek retains its explicit rule that success proves a selected check ran.

Only text output is supported. Requests using `--format`, `--json`, `--yaml`, or `--sarif` fail before source analysis. Help and version output identify the one implemented check, unsupported checks/formats, and reference/compiler pins.

## Consequences

The human report differs from Reek's legacy presentation, while each finding's message, location, context, and reference URL remain comparable. Consumers should treat report version 1 fields as the stable interface and should not infer check coverage from a zero finding count. `String#dump` was rejected due to the pinned compiler limitation; the explicit escaper is covered with newline, tab, quote, and non-ASCII path examples.

## Evidence

`test/text_report_contract.rb` checks fields, section order, deterministic repeated output, path escaping, non-ASCII findings, clean and findings states, and explicit format rejection. Existing CLI contracts check partial-result streams and status. Mutation checks cover escaping, source order, completion, findings, and partial-input precedence.
