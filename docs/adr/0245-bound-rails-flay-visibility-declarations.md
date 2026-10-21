# ADR 0245: Bound Rails Flay visibility declarations

## Status

Accepted

## Context

Direct Rails callback declarations are now supported in simple class bodies, but the pinned 25-file manifest remains partial. `UsersController` also contains a bare `private` declaration among its methods. Flay's method group candidates come from method definitions; a bare visibility call does not add a candidate. Treating arbitrary calls as harmless could conceal unsupported class-body behavior.

## Decision

Support bare, receiver-free `private`, `protected`, and `public` calls in a simple class body as non-candidate declarations. Require no arguments and no block. Keep calls with arguments, receiver-qualified calls, and other unsupported class-body statements incomplete. Compare exact public Flay output and coverage before accepting the behavior.

## Consequences

Issue 131 owns the reference fixtures and mutation boundary. This extends only candidate collection for simple class scopes. Rails-wide Flay parity remains open in issue 97 until the remaining source shapes are implemented and the exact 25-file contract passes with complete coverage.

