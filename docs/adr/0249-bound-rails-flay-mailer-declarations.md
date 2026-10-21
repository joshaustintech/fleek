# ADR 0249: Bound Rails Flay mailer declarations

## Status

Accepted

## Context

Pinned Rails `ApplicationMailer` contains two direct class-body calls: a `default` keyword hash with one string-valued `from` entry and a `layout` call with one string argument. Flay 2.14.4 reports no duplication for this source; Fleek currently marks it incomplete.

## Decision

Accept only receiver-free, block-free `default from: <string literal>` and `layout <string literal>` calls as non-candidate declarations in simple classes. Keep other class-body calls and call shapes incomplete.

## Consequences

Issue 135 owns the CLI fixture, pinned Rails assertion, and mutation boundary. This is not general Rails macro support and does not execute source code. Issue 97 remains open until all remaining manifest shapes resolve.
