# ADR 0018: Combined analysis and independent exclusions

## Status

Accepted.

## Context

Ticket 12 joins the supported Flay structural-duplication and Reek ClassVariable checks in one explicitly selected native CLI invocation. Their flags, exclusions, result formats, and current supported syntax differ. One analyzer can also retain findings when the other fails.

## Decision

Select both checks with `--checks flay:StructuralDuplication,reek:ClassVariable`. Unknown or duplicate selections fail before analysis. Route `--mass` only to Flay and `--reek-config` only to Reek; validate both before either analyzer starts. Combined `--stdin` is rejected because Flay requires file paths. Keep long options explicit because upstream short aliases conflict.

Emit separate `Duplication` and `Smells` sections with per-check coverage and score fields. Do not calculate a combined score. Emit one final `Overall status`: `complete` exits 0, `findings` exits 2, and `incomplete` exits 1. Any analyzer failure overrides findings from the other check. Source paths excluded by one analyzer remain available to the other.

Read `.flayignore` from the current working directory, matching Flay 2.14.4's locked PathExpander 2.0.1 subset: a no-slash pattern matches file paths, a trailing-slash pattern matches a directory, and a slash pattern matches a relative path glob. Apply these patterns only to duplication. Reek `exclude_paths`, detector exclusions, and suppressions remain smell-only. Display per-check excluded paths and coverage.

The currently supported Flay grammar (top-level parameterless methods) and Reek grammar (one simple class) do not fully overlap. Combined runs therefore fail closed when either check cannot analyze its selected files. To get complete combined results today, use `.flayignore` and Reek exclusions to give each analyzer only sources inside its proven syntax subset. Expanding the overlapping grammar requires reference comparisons and explicit coverage tests.

## Consequences

The report has one global outcome and two analyzer-specific coverage counts. It can show findings from one section alongside an incomplete global status. Combined stdin is a deliberate unsupported case. A failed analysis has exit 1 even when another section has findings.

Flay 2.14.4 exits 0 on findings while Reek 6.6.0 exits 2. Fleek normalizes complete findings to exit 2 and incomplete coverage to exit 1. This preserves Reek's findings status and deliberately changes Flay's findings status to match the stable CLI contract. Their native text formats also differ, so parity is checked on normalized finding identity, source locations, group kind/mass/score, aggregate score, and coverage instead of byte-for-byte output. The combined report preserves analyzer order (duplication before smells), keeps analyzer-specific fields, and emits one overall status.

## Evidence

`test/combined_contract.rb` compares Flay 2.14.4 and Reek 6.6.0 results on equivalent post-exclusion source sets and settings. It checks findings, source locations, score/mass, pinned exit status, report ordering, and the deliberate Flay exit-status mapping. It covers retained findings with incomplete overall status, clean combined status, separated exclusions and coverage, unknown checks, and absence of a combined score. Mutation cases target global failure precedence and Flay-ignore leakage.
