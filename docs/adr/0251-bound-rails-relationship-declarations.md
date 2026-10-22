# ADR 0251: Bound Rails Flay Relationship declarations

## Status

Accepted

## Context

Pinned Rails `Relationship` contains two direct `belongs_to` declarations and two direct `validates` declarations. Flay 2.14.4 reports no duplication for the model; Fleek currently marks it incomplete.

## Decision

Accept only the exact follower/followed associations with `class_name: "User"` and the matching follower_id/followed_id presence validations with `presence: true`. Keep other class-body calls and shapes incomplete.

## Consequences

Issue 137 owns the public CLI fixtures, pinned Rails assertion, and mutation boundary. This is bounded to the pinned model and does not implement general Active Record macros. Issue 97 stays open until all residual model files are resolved.
