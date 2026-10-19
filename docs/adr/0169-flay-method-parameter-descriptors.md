# ADR 0169: Describe Flay method parameters with shared rules

## Status

Accepted

## Context

Ticket 41 covers positional, optional, post, keyword, rest, keyword-rest, and block parameters, plus optional block parameters. Support, names, defaults, mass, and optional-arity logic had accumulated in separate branches, making the semantics easy to drift. Flay 2.14.4 also distinguishes optional positional defaults that call with one integer argument from optional keyword defaults, which reject that form.

## Decision

Use one Prism-node-indexed parameter descriptor table for support, name comparison, optional names, default presence, optional-count contribution, and mass adjustment. Keep default-shape recognition and the positional call-argument exception in the shared default predicate. Route public contracts and parameter mutations to focused parameter contracts. Reject unsupported defaults with incomplete coverage.

Preserve Flay's parameter-list mass adjustment for optional block parameters. Preserve the existing partial-subtree policy: if methods differ in parameter shape but share a qualifying body subtree, Fleek reports incomplete coverage rather than claiming clean analysis. The parameter-count clean-boundary fixture therefore uses distinct method bodies and checks Flay's no-group result.

## Consequences

Adding a supported parameter form requires one descriptor entry and Flay-backed public contracts for its candidate, mass, and identity behavior. Positional optional defaults may accept a one-integer bare call; keyword optional defaults may not. Unsupported defaults and partial subtree matches remain explicit incomplete results.
