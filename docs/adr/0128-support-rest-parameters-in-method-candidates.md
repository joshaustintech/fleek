# ADR 0128: Support named rest parameters in method candidates

## Status

Accepted

## Context

Pinned Flay 2.14.4 groups methods with named rest parameters and distinguishes methods whose rest-parameter names differ as similar rather than identical. Fleek previously rejected all rest parameters, leaving these otherwise supported method bodies incomplete.

## Decision

Accept named Prism rest parameters in top-level and class-method candidates. Reject anonymous rest parameters and continue rejecting post, keyword, keyword-rest, and block parameters. Compare rest-parameter names when classifying identical method trees; leave candidate mass unchanged. A compiled CLI contract compares Flay kind, mass, locations, and coverage. A focused deterministic source mutation removes rest-name comparison and must make that contract fail.

## Consequences

Named-rest methods can contribute Flay-compatible candidates. Other unsupported parameter forms remain incomplete. Mutation testing remains an explicit, deterministic source mutation harness: each mutant maps to the smallest public contract, matching PIT's coverage-guided selection and targeted execution ideas without assuming JVM bytecode or importing a Java runtime.
