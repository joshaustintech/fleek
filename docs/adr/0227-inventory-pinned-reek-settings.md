# Inventory pinned Reek settings before closing analyzer parity

Accepted for Ticket 90.

## Context

Reek 6.6.0 exposes 29 built-in detectors. Detector parity and bounded setting cases are spread across Tickets 62–89, while configuration discovery, suppression, and validation remain separate acceptance slices in Tickets 91–93. Treating supported detector inputs as complete configuration parity would hide the remaining gaps.

## Decision

Inventory the pinned detector registry and each detector's default settings directly from Reek 6.6.0 sources and schema. Record generic `enabled`/`exclude` behavior separately from detector-specific settings. Reuse per-detector public CLI contracts as evidence and retain directory precedence, suppression scope, and configuration validation as open downstream work.

Treat the `LongParameterList.overrides` map as a concrete unsupported setting, not as covered by the existing scalar `max_params` support. Track its smallest pinned mismatch in Ticket 126 and leave parent parity acceptance open until it is resolved.

## Consequences

The inventory distinguishes verified bounded detector/settings behavior from unresolved configuration-wide rules. It does not claim arbitrary Reek YAML parity, full directory matching, or custom method overrides. The pinned Reek source locations are `lib/reek/smell_detectors.rb`, `lib/reek/smell_detectors/base_detector.rb`, each detector's `default_config`, and `lib/reek/configuration/schema.rb`.
