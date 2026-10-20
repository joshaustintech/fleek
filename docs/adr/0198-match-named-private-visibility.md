# ADR 0198: Match named private-method visibility

## Status

Accepted for Ticket 61.

## Context

Ticket 60 added bounded `UnusedPrivateMethod` analysis for visibility section markers. Reek 6.6.0 also treats a method passed to `private :name` as private. Reopening visibility with `public` must stop later methods from being considered private, and calls from one private method make another private method used.

## Decision

Support one literal symbol argument to `private`, `public`, or `protected` when the named direct method has already appeared in the simple class. Update only that method's tracked visibility. Keep bare visibility markers as class-wide state for following methods. Treat calls between tracked method bodies as evidence that a private method is used. Keep dynamic dispatch and other unsupported class-body forms incomplete.

Preserve Reek's opt-in default. Explicit selection runs the detector; configuration enables it in default selection and may disable it, including scoped overrides.

## Consequences

The bounded implementation matches pinned visibility changes without inferring runtime visibility from arbitrary expressions or method definitions that appear later. Calls between direct methods are covered, while reflection and inherited behavior remain explicit gaps.

## Evidence

Public CLI contracts compare findings, status, coverage, and streams against Reek 6.6.0 for named visibility, public visibility reopening, cross-private calls, explicit selection, configured default enablement, and configured disablement. Focused mutation checks exercise named visibility updates and public reopening.
