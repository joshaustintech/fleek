# Verify Reek directory settings use the most specific scope

Accepted for Ticket 91.

## Context

Reek 6.6.0 applies directory directives by selecting the longest matching directory key. Fleek already resolves one effective settings scope per source, but prior contracts did not compare a parent threshold against a more specific child threshold under both explicit and discovered configuration.

## Decision

Keep the current bounded longest-prefix scope selection. Verify it through the public CLI with a parent threshold of three and child threshold of four for the same four-parameter method. Compare discovered `.reek.yml`, explicit `--config`/`--reek-config`, and no-config default behavior against Reek 6.6.0.

## Consequences

The parent path reports at line 2 and the child path is clean under the scoped config; explicit and discovered runs agree. With no config, the child's four parameters exceed the default threshold of three and report. This verifies one detector, one nested scope, and the no-config fallback; other config syntax stays in its own tickets.
