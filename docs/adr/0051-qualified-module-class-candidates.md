# ADR 0051: Collect class groups under qualified module paths

## Status

Accepted.

## Context

Flay 2.14.4 reports module groups for a direct class under relative qualified module declarations such as `module Current::Versioned`. Fleek's namespace collector accepted only a single constant-read node or an explicit nested-module chain, so it marked these shared-grammar candidates incomplete.

## Decision

Flatten simple relative constant paths into their ordered constant names and collect one direct simple class beneath a qualified module path containing two through seven components. Carry the full module and class names into candidate identity, retain the module declaration line, and account for the qualified path in the module group's mass. Keep empty paths clean. Mark absolute or otherwise unsupported paths, paths with eight or more components, and qualified module bodies other than one direct class incomplete.

## Consequences

Qualified module class groups retain the existing bounded class-method AST support and fail closed when the class or its methods are unsupported. A source may retain a verified seven-component group while reporting incomplete coverage for a separate eight-component candidate. No general qualified namespace, sibling-class, or nested-class parity claim follows from this slice.

## Evidence

`test/duplication_contract.rb` compares a two-component qualified module group with Flay 2.14.4 at similar `:module` mass/score 56 and lines 1/12. A second fixture compares seven- and eight-component paths: Flay reports mass 66 and 68, while Fleek preserves the supported seven-component mass-66 group and marks the source incomplete for the eight-component boundary. Mutation checks remove qualified candidate collection, alter its mass, and lower the supported depth; each is caught by the public CLI contract. The full Ticket 21 parity boundary remains open.
