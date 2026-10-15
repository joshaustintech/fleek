# ADR 0024: Collect Flay method candidates across simple classes

## Status

Accepted.

## Context

Flay analyzes methods from multiple class declarations in one selected source set. Fleek previously accepted only one class declaration, so combined Rails inputs failed before comparing otherwise supported methods. Comparing only within each class would also miss Flay groups spanning distinct classes.

## Decision

Collect bounded, direct, parameterless methods from multiple simple class declarations in the combined source. Retain the existing limit of 16 supported candidates total and at most 32 direct body entries per class. Compare candidates across classes when the upstream result is a supported `:defn` pair. When similarly shaped classes have the same number of direct body entries and could instead yield Flay's `:class` group, fail incomplete rather than relabeling it as `:defn`. Class callbacks, parameterized methods, and unsupported method ASTs mark sources partial; matching unsupported subtrees or ambiguous method groups fail closed.

## Consequences

An independent fixture places an unrelated method in one class and a Rails-shaped similar pair in another. Its public CLI result matches Flay 2.14.4 for group kind, mass, score, ordered source locations, and findings status. A second reference fixture proves a possible `:class` group remains incomplete until implemented. Nested modules, unsupported class contents, and the pinned 25-file corpus remain explicit gates.
