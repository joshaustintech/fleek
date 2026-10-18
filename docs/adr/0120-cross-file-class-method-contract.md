# ADR 0120: Verify class-method parity across source files

## Status

Accepted

## Context

Flay groups matching method candidates across input files. Existing cross-file contracts covered top-level methods, while method-expression ticket 22 required evidence for scoped class methods and original input-path line mapping.

## Decision

Add a generated two-file CLI contract with matching class methods and deliberately different sibling methods. This prevents identical class-subtree grouping from hiding the method-level Flay result. Compare class-method classification, mass, weighted score, ordered original paths and lines, and complete coverage with Flay 2.14.4. Map the class-candidate mutation to this focused contract.

## Consequences

The contract proves cross-file class-method candidates remain grouped as methods when containing classes differ, and checks canonical path and line ordering when inputs arrive in reverse lexical order. Broader cross-file parity for unsupported method forms remains part of ticket 22.
