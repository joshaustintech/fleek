# ADR 0085: Support eighteen-component qualified module class paths

## Status

Superseded by [ADR 0091](0091-nineteen-component-qualified-module-classes.md). Historical record; its eighteen-component limit was extended.

## Context

Flay 2.14.4 reports class-method module groups under relative qualified module paths with eighteen constant components. Fleek supported seventeen and marked this reference-supported shape incomplete. Candidate identity storage must hold eighteen module names plus the class name.

## Decision

Support qualified module class paths through eighteen components. Keep nineteen-component paths incomplete. Use one named component limit for validation, and retain enough buffer capacity to represent the supported path plus the first unsupported boundary without truncating identity.

## Consequences

Eighteen-component groups report complete coverage and match Flay's node mass, score, locations, and ordering. Nineteen-component paths remain explicitly partial.

## Evidence

`test/fixtures/duplication_qualified_namespace_eighteen_components.rb` matches Flay 2.14.4 at similar `:module` mass/score 88 and lines 1/12. `test/fixtures/duplication_qualified_namespace_nineteen_components.rb` matches Flay at mass/score 90 and lines 1/12 while Fleek reports incomplete coverage. Public CLI contracts compare both outputs; mutations detect losing 16-, 17-, and 18-component support and accepting 19 components.
