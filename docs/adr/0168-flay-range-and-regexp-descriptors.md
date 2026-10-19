# ADR 0168: Describe Flay ranges and regular expressions

## Status

Accepted

## Context

Ticket 22's method candidates include Prism range and regular-expression nodes. Flay treats an exclusive range differently from an inclusive one, subtracts two units for a range node, and compares regular-expression pattern contents and options. Interpolated patterns also include embedded expression structure and a distinct mass adjustment.

## Decision

Keep these shapes in the shared node descriptor table. Use Prism's exclusive-end flag for range identity and the descriptor's `-2` mass adjustment. Compare static regexp pattern values and options; compare interpolated pattern parts structurally and preserve their `-1` mass adjustment. No synthetic RubyParser wrapper is needed for these nodes.

Use focused compiled-CLI contracts against pinned Flay 2.14.4 for inclusive/exclusive ranges and static/interpolated regular expressions. Route each range and regexp mutant to the matching public contract.

## Consequences

Range, pattern-content, option, interpolation, and mass differences remain observable at the public report boundary. The full duplication contract still runs in the main gate for composed behavior.
