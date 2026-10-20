# ADR 0191: Match bounded Flay fuzzy method candidates

## Status

Accepted for Ticket 53.

## Context

Ticket 53 adds explicit `--fuzzy` distance-one matching to the native Flay path. Flay 2.14.4 only fuzzy-processes code-bearing candidates whose S-expression has at most 10 immediate elements and whose integer average mass (`mass / size`) is at most 12. It removes one direct code child while forming candidates. ADR 0016's statement that fuzzy is unsupported and ADR 0017's fuzzy exclusion are superseded for the bounded behavior below.

## Decision

For supported method candidates, accept explicit `--fuzzy` without a value and report a fuzzy group only when deleting one direct method-body statement makes the method shapes equal, the retained mass meets the selected threshold, and both original Flay method candidates satisfy the size and average-mass limits. The method S-expression size is three fixed elements (`defn`, name, and `args`) plus the direct body statement count. Average mass uses integer division, matching Flay.

Only supported top-level and class method candidates enter this path. Unsupported syntax continues through the existing incomplete-result behavior. The option remains inapplicable to Reek-only selection. Fuzzy location metadata marks the method with the extra statement; the group retains Flay mass and score weighting.

## Consequences

Default Flay grouping stays unchanged when `--fuzzy` is absent. The native path does not promise Flay parity for other candidate types or explicit fuzzy distances. `--fuzzy N` with a value remains outside this ticket. A fixture above Flay's 10-element cap protects the size boundary; the native guard also enforces Flay's average-mass cap.

## Evidence

The compiled public CLI contract compares default distance-one, exact, unrelated, a below-cap pair at mass 40, and a separate above-cap pair with candidate masses 26 and 23 using Flay 2.14.4. This proves the above-cap zero is caused by Flay's size bound rather than the default mass threshold. It asserts findings, fuzzy locations, mass, score, default non-fuzzy behavior, and Reek-only rejection. Full project gates and non-equivalent mutations are recorded in Ticket 53's Answer.
