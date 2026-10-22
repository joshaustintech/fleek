# ADR 0255: Bound Rails Flay Micropost presence and length validations

## Status

Accepted

## Context

Pinned Rails `Micropost` declares `user_id` presence and `content` presence with a maximum length of 140. Flay 2.14.4 reports no duplication; Fleek marks the file partial.

## Decision

Accept only the exact `user_id` presence validation and the exact `content` presence plus `length: { maximum: 140 }` validation. Require receiver-free, block-free calls with the specified attributes and keyword/hash shape. Leave other validation DSL forms incomplete.

## Consequences

Issue 141 owns focused public CLI fixtures and mutation boundaries. Image validation remains unsupported, and issue 97 stays open.
