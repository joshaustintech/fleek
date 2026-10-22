# ADR 0252: Bound Rails Flay Micropost association

## Status

Accepted

## Context

Pinned Rails `Micropost` begins with `belongs_to :user`. Flay 2.14.4 reports no duplication; Fleek currently marks the file incomplete for this and other unsupported model declarations.

## Decision

Accept only a direct receiver-free, block-free `belongs_to :user` call with exactly one symbol argument as a non-candidate declaration. Keep option-bearing associations and other forms incomplete.

## Consequences

Issue 138 owns the public CLI contract and mutation boundary. This does not resolve the remaining Micropost declarations or implement general Active Record support. Issue 97 stays open.
