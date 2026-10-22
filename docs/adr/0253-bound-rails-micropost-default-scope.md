# ADR 0253: Bound Rails Flay Micropost default scope

## Status

Accepted

## Context

Pinned Rails `Micropost` declares `default_scope -> { order(created_at: :desc) }`. Flay 2.14.4 reports no duplication; Fleek currently marks the file incomplete for this and other remaining declarations.

## Decision

Accept only a direct, receiver-free, block-free `default_scope` call with one lambda whose sole body statement is a receiver-free, block-free `order(created_at: :desc)` call. Keep other lambda bodies and class-body forms incomplete.

## Consequences

Issue 139 owns the public CLI fixture and mutation boundary. This does not resolve the attachment or validation declarations in Micropost and does not introduce general lambda or Active Record DSL support. Issue 97 stays open.
