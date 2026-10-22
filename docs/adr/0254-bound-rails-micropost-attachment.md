# ADR 0254: Bound Rails Flay Micropost attachment declaration

## Status

Accepted

## Context

Pinned Rails `Micropost` declares a single Active Storage attachment with a block-local variant. Flay 2.14.4 reports no duplication; Fleek currently marks the file incomplete.

## Decision

Accept only `has_one_attached :image` with one block parameter and one statement calling `variant :display, resize_to_limit: [500, 500]` on that parameter. Require literal names, one keyword pair, and the exact two integer values. Keep other attachment and block DSL shapes incomplete.

## Consequences

Issue 140 owns the public CLI fixture and mutation boundaries. This adds no general block or Active Storage DSL support. The Micropost validations and User model remain outside this decision, and issue 97 stays open.
