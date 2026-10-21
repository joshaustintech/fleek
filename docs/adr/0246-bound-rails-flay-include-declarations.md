# ADR 0246: Bound Rails Flay include declarations

## Status

Accepted

## Context

The pinned Rails `ApplicationController` contains `include SessionsHelper` alongside a method body already supported by Fleek. Flay's `:defn` candidates come from method definitions; the direct include declaration does not add a method candidate. Treating arbitrary class-body calls as harmless could hide unsupported structure or execute code.

## Decision

Support only receiver-free `include` calls with no block and one or more constant or constant-path arguments in simple class bodies. Keep dynamic arguments, receiver-qualified calls, blocks, and other class-body statements incomplete. Compare public output against Flay 2.14.4 before marking the source complete.

## Consequences

Issue 132 is implemented and resolved. Its public contract matches Flay 2.14.4 for the supported `:defn` group, and the pinned Rails `ApplicationController` analyzes completely when selected alone. Dynamic arguments, receiver calls, blocks, `extend`, `prepend`, and module singleton behavior remain outside the accepted boundary. Rails-wide parity remains open in issue 97 until all remaining manifest shapes resolve.

