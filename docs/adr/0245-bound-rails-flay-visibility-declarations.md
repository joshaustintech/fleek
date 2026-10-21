# ADR 0245: Bound Rails Flay visibility declarations

## Status

Accepted

## Context

Direct Rails callback declarations are now supported in simple class bodies, but the pinned 25-file manifest remains partial. `UsersController` also contains a bare `private` declaration among its methods. Flay's method group candidates come from method definitions; a bare visibility call does not add a candidate. Treating arbitrary calls as harmless could conceal unsupported class-body behavior.

## Decision

Support bare, receiver-free `private`, `protected`, and `public` calls in a simple class body as non-candidate declarations. Require no arguments and no block. Keep calls with arguments, receiver-qualified calls, and other unsupported class-body statements incomplete. Compare exact public Flay output and coverage before accepting the behavior.

## Consequences

Issue 131 verifies the reference fixtures and mutation boundary. The pinned `UsersController` now has complete one-file coverage and exact score-48 findings. The combined 25-file manifest remains incomplete because other source shapes still need work. The default-configuration contract asserts that the opt-in detector stays disabled without constraining aggregate status, which can include findings from other selected analyzers after Flay coverage becomes complete.

