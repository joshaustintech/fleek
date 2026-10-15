# ADR 0024: Collect Flay method candidates across simple classes

## Status

Accepted.

## Context

Flay analyzes methods from multiple class declarations in one selected source set. Fleek previously accepted only one class declaration, so combined Rails inputs failed before comparing otherwise supported methods. Comparing only within each class would also miss Flay groups spanning distinct classes.

## Decision

Collect bounded, direct, parameterless methods from multiple simple class declarations in the combined source. Retain the existing limit of 16 supported candidates total and at most 32 direct body entries per class. Compare candidates across classes when the upstream result is a supported `:defn` pair. Reject a possible Flay `:class` group when similarly shaped classes have equal body sizes and every direct entry is a modeled method; this avoids inferring whole-class similarity from partial ASTs. Unsupported callbacks and method forms mark sources partial, while verified method findings remain visible with incomplete status; matching unsupported subtrees or ambiguous method groups fail closed.

## Consequences

An independent fixture places an unrelated method in one class and a Rails-shaped similar pair in another. Its public CLI result matches Flay 2.14.4 for group kind, mass, score, ordered source locations, and findings status. A second reference fixture proves a possible `:class` group remains incomplete until implemented. Nested modules, unsupported class contents, and the pinned 25-file corpus remain explicit gates.
