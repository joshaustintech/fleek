# ADR 0170: Generate Flay contracts from the descriptor inventory

## Status

Accepted

## Context

Supported method-body and parameter descriptors had individually maintained Flay fixtures, so adding a descriptor could leave its behavior without a contract. A generated contract must cover the whole inventory while keeping analyzer work bounded and deterministic.

## Decision

Maintain a compact catalog of generated Ruby node and parameter forms in one public contract. Compare each two-method case independently against Flay 2.14.4 and Fleek, checking finding kind, mass, score, exact locations and order, and complete coverage. Compare the catalog to the native descriptor tables so either an unrepresented implementation rule or stale catalog entry fails. Keep clean and unsupported-boundary examples and focused support and mass mutations.

Independent cases prevent unrelated descriptors from combining into a cross-case duplicate group. Run them with a bounded worker count and reap whichever process finishes first to avoid head-of-line waiting. Retain fixed fixtures only for distinct mapping, identity, or boundary behavior.

## Consequences

Every supported descriptor must have a generated Flay-backed public case. Changes to descriptor inventory or mapping fail deterministically. A generated case validates its own report behavior without depending on other catalog entries or report grouping between unrelated descriptors.
