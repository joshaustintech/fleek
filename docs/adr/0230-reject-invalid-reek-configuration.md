# Reject invalid Reek configuration before analysis

Accepted for Ticket 93.

## Context

Reek 6.6.0 validates YAML configuration against detector and setting schemas before analyzing sources. Fleek has a bounded native reader for the supported configuration subset and deliberately normalizes its own diagnostics. Existing public coverage checked several malformed forms only on the Fleek side, leaving uncertainty about unknown keys, wrong types, and invalid thresholds.

## Decision

Keep validation in Fleek's native configuration path. Reject malformed YAML, unknown detectors and settings, wrong scalar and list types, and non-integer thresholds before analysis. Compare these cases against the pinned Reek CLI, while asserting Fleek's normalized diagnostics separately. Do not load Reek or add a general YAML dependency to Fleek; record any valid upstream YAML syntax outside this bounded contract as a separate issue.

## Consequences

The public configuration contract now checks that Fleek and Reek both exit unsuccessfully without findings output for malformed YAML, unknown detector, unknown setting, wrong scalar type, wrong list type, and a non-integer threshold. Fleek's diagnostics remain stable and specific. This ticket adds verification only because the bounded cases already behaved correctly; it does not claim full YAML syntax parity.
