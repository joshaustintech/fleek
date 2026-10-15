# ADR 0026: Support required positional parameters in class methods

## Status

Accepted.

## Context

The pinned Rails corpus contains ordinary class methods with required positional parameters. Rejecting every parameterized method hid otherwise reference-comparable Flay candidates and kept even these sources partial. Flay 2.14.4 compares a bounded fixture with one required parameter per method as a similar `:defn` group at mass and score 48. When formal parameter names differ, the reference still reports a similar group rather than an identical one.

## Decision

For class-method candidates, accept at most eight required positional parameters. Optional, rest, post, keyword, keyword-rest, and block parameters remain unsupported and keep the source partial. Required parameter count and names do not affect similar-group matching, as verified against Flay 2.14.4 even when paired methods have different required arity. Parameter names and local-variable reads participate in identical-group classification. Preserve the existing bounded method-body AST grammar, candidate limit, mass threshold, and incomplete-result behavior.

## Consequences

CLI contracts compare identical fixture inputs against Flay 2.14.4 for same-arity and different-arity required-parameter findings, scores, locations, and the similar-versus-identical classification. Mutations prove that required candidates are collected and differing parameter names are not classified as identical. This extension does not close the 25-file Rails manifest: callbacks, unsupported method parameters, and unsupported body forms still require separate reference-backed slices.
