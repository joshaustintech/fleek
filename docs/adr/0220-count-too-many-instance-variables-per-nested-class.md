# Count TooManyInstanceVariables per nested class

Accepted for Ticket 83.

## Context

Reek 6.6.0 counts distinct instance-variable writes independently in each class. Fleek's existing counter handled one class and rejected a top-level class containing nested classes, so explicit checks could not report a nested class finding or preserve a clean sibling.

## Decision

Support one top-level class containing exactly two direct nested classes for `TooManyInstanceVariables`. Count distinct supported instance-variable write names separately in each nested class and report each class with a qualified context. Apply the configured `max_instance_variables` threshold independently. Keep other nested shapes incomplete.

## Consequences

The detector matches pinned Reek for the supported sibling boundary, including repeated read/write use of a variable without double counting. A nested class chain, extra outer statements, or other unsupported shapes remain incomplete rather than clean.
