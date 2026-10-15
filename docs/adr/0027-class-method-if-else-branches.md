# ADR 0027: Support class-method if and else branches

## Status

Accepted.

## Context

Rails controllers and helpers use conditional branches inside ordinary methods. The bounded class-method AST collector rejected these nodes, leaving otherwise comparable methods unanalyzed. A pinned Flay 2.14.4 fixture with matched `if`/`else` trees reports a similar `:defn` group at mass and score 62. Adding conditional candidates to the 16-entry combined-input limit displaced the already-supported UsersController pair in the 25-file corpus. The corpus also has possible cross-class `:class` groups; rejecting one must not suppress an unrelated verified method group.

## Decision

Include Prism `IfNode` and `ElseNode` in the supported class-method AST tree when their child expressions and statements fit the existing bounded node grammar. Preserve branch topology in tree equality. For Flay mass, do not count the `ElseNode` wrapper; continue excluding keyword-hash wrappers. Raise the combined candidate limit from 16 to 24; the 18-method fixture covers candidates past the old bound without triggering Spinel's 64 KB stack warning. When a cross-class pair could be an upstream `:class` group, skip that candidate pair and mark analysis partial; retain any independent supported `:defn` group. If no independent group exists, fail incomplete. Other control-flow nodes, including `UnlessNode`, remain unsupported and produce partial coverage until separately compared with Flay.

## Consequences

The public CLI contract compares identical conditional fixtures against Flay 2.14.4 for group kind, mass, score, and source lines. A combined fixture proves that a possible `:class` group does not hide an independent `:defn` group; mutations protect branch behavior, mass, candidate capacity, and finding preservation. The exact 25-file corpus retains its UsersController finding and remains incomplete because other unsupported forms persist; this does not close the manifest gate.
