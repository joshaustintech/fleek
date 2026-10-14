# ADR 0012: Named stdin analysis

## Status

Accepted for ticket 06.

## Decision

Use `--checks reek:ClassVariable --stdin SOURCE [PATH...]`. `SOURCE` is a required display origin and future configuration-scope key; Fleek does not open or execute it. Read stdin once, report findings and syntax diagnostics against that origin, then analyze any explicit paths. Missing origin fails before analysis. Mixed stdin/path input is supported, and failures keep the overall report incomplete while retaining useful findings. Zero-byte stdin is a valid named empty Ruby source and reports complete clean analysis. Stdin alone never selects the current directory.

## Consequences

Named stdin and the same file produce identical reports when given the same origin. The origin is carried through findings and parse errors without implying the named file exists. Empty and mixed input behavior is explicit and covered through the compiled CLI.
