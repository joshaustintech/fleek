# ADR 0250: Bound Rails Flay helper hash default

## Status

Accepted

## Context

Pinned Rails `UsersHelper#gravatar_for` uses an optional positional parameter default `{ size: 80 }`. Flay 2.14.4 reports no duplication for the helper; Fleek currently marks it incomplete.

## Decision

Accept only a one-entry hash default with symbol key `size` and integer literal value `80` for an optional positional parameter. Preserve Flay's candidate mass and identity. Keep other keys and dynamic or unsupported values incomplete.

## Consequences

Issue 136 owns the public CLI fixture, pinned Rails assertion, and mutation boundary. General hash defaults remain unsupported. Issue 97 stays open until every residual manifest shape is resolved.
