# ADR 0199: Match two-level ClassVariable namespace contexts

## Status

Accepted for Ticket 62.

## Context

Fleek reported a simple class directly inside one module with a qualified Reek context, but marked a class inside two nested modules incomplete. Reek 6.6.0 reports that class's class-variable reads and writes under the full constant path and aggregates every source line.

## Decision

Support one simple class directly inside two simple nested modules. Build its context from both module names and the class name, and check both namespace bodies for class-variable occurrences outside the class before reporting complete analysis. Keep deeper nesting, wrapped declarations, sibling scopes, and unrelated namespace-level occurrences incomplete.

## Consequences

The supported nested case matches Reek's context and grouped line list. Scope ownership stays bounded to a direct module chain; broader namespace discovery remains explicit incomplete coverage.

## Evidence

The public contract compares the one-level and two-level class contexts and line aggregation against Reek 6.6.0, exercises configured context exclusion for the nested name, and keeps three-level and wrapped class declarations incomplete. Focused mutations verify nested-class acceptance and the direct-child boundary.
