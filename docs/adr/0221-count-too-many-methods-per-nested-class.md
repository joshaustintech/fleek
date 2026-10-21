# Count TooManyMethods per nested class

Accepted for Ticket 84.

## Context

Reek 6.6.0 counts direct instance methods independently for each class. Fleek's existing counter handled one class and rejected a top-level class with a direct nested class, losing the nested class's method finding.

## Decision

Support one top-level class with one direct nested class for `TooManyMethods`. Count direct instance method definitions separately in each class and use the qualified class path for the nested context. Apply `max_methods` independently. When unsupported syntax appears beside supported findings, retain those findings and mark the selected source incomplete. Other nested class shapes remain incomplete.

## Consequences

The bounded contract covers an outer class at the default limit and a nested class one above it, a configured threshold that makes both clean, and a mixed top-level method that leaves the source incomplete while retaining the nested finding.
