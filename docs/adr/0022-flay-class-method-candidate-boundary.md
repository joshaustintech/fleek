# ADR 0022: Flay class-method candidate boundary

## Status

Accepted.

## Context

The pinned Rails corpus reports a similar Flay `:defn` group for methods nested directly in `UsersController`. Fleek's initial Flay adapter only collected methods at the program root, so every class declaration failed closed before useful Flay candidates could be analyzed.

## Decision

Extend the bounded Flay adapter to accept exactly one simple class containing exactly two direct parameterless methods, using the existing supported method-body statement grammar. Continue rejecting other class contents, class nesting, additional methods, parameters, and unsupported statements. Do not execute source or infer that omitted candidates were analyzed.

## Consequences

The class-method seam now matches unchanged Flay 2.14.4 on a public CLI fixture, including node mass and source lines. This is only an implementation slice: the complete 25-file Rails manifest remains the release gate, and unsupported source shapes continue to report incomplete. Further AST support requires its own reference-backed contracts and mutations.

## Evidence

`test/duplication_contract.rb` compares a direct class with two methods against locked Flay 2.14.4 at an explicit mass threshold. A mutation disabling class-method candidate collection is required to fail that public CLI contract.
