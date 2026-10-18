# ADR 0092: Support twenty-component qualified module class paths

## Status

Accepted. Supersedes [ADR 0091](0091-nineteen-component-qualified-module-classes.md).

## Context

Flay 2.14.4 reports class-method module groups under relative qualified module paths with twenty constant components. Fleek supported nineteen. Candidate identity storage needs one slot per module name plus one for the class name.

## Decision

Raise the qualified module component limit to twenty and the fixed identity capacity to twenty-one. Reject a candidate when its module names plus class name exceed that capacity. Keep twenty-one-component paths incomplete.

## Consequences

Twenty-component groups report complete coverage and match Flay's node mass, score, locations, and ordering. Twenty-one-component paths remain explicitly partial without a candidate; the collector rejects them before writing candidate identity.

## Evidence

`test/fixtures/duplication_qualified_namespace_twenty_components.rb` matches Flay 2.14.4 at similar `:module` mass/score 92 and lines 1/12. `test/fixtures/duplication_qualified_namespace_twenty_one_components.rb` matches Flay at mass/score 94 and lines 1/12 while Fleek reports incomplete coverage. Public CLI contracts compare both outputs; mutations detect losing 19- or 20-component support, insufficient identity capacity, and dropping incomplete status at twenty-one.
