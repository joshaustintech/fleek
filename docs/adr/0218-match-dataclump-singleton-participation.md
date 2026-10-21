# ADR 0218: Match DataClump singleton participation

## Status

Accepted for Ticket 81.

## Context

Reek 6.6.0 includes methods declared inside `class << self` with direct instance methods when deriving parameter clumps. It excludes `def self.method` definitions. Different parameter sets can produce overlapping clumps with different participating method counts.

## Decision

Collect supported `class << self` method parameter lists alongside direct instance methods. Derive each candidate clump from the intersection of parameter names in each frequent participation group, then count methods containing the complete clump. Keep the existing direct `def self.method` exclusion to match Reek.

## Consequences

The public CLI contract pins both overlapping clumps and the `min_clump_size` control. A mutation that counts methods without requiring every clump parameter must fail.

## Evidence

Pinned Reek 6.6.0 and Fleek report `['destination', 'origin']` across 9 methods and `['destination', 'origin', 'weight']` across 8; `min_clump_size: 3` retains only the latter. Full gate evidence is in issue 81.
