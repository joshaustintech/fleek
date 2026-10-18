# ADR 0091: Support nineteen-component qualified module class paths

## Status

Accepted. Supersedes [ADR 0085](0085-eighteen-component-qualified-module-classes.md).

## Context

Flay 2.14.4 reports class-method module groups under relative qualified module paths with nineteen constant components. Fleek supported eighteen and marked this reference-supported shape incomplete. Candidate identity storage has twenty slots, enough for nineteen module names and the class name.

## Decision

Raise the qualified module component limit to nineteen. Keep twenty-component paths incomplete because their class name cannot fit in the fixed scope identity capacity.

## Consequences

Nineteen-component groups report complete coverage and match Flay's node mass, score, locations, and ordering. Twenty-component paths remain explicitly partial.

## Evidence

`test/fixtures/duplication_qualified_namespace_nineteen_components.rb` matches Flay 2.14.4 at similar `:module` mass/score 90 and lines 1/12. `test/fixtures/duplication_qualified_namespace_twenty_components.rb` matches Flay at mass/score 92 and lines 1/12 while Fleek reports incomplete coverage. Public CLI contracts compare both outputs; mutations detect losing 16- through 19-component support and dropping incomplete status at twenty.
