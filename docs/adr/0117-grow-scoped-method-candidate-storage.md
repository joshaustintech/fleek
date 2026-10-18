# ADR 0117: Grow scoped method candidate storage

## Status

Accepted

## Context

Flay 2.14.4 groups 40 repeated class methods in one source file. Fleek's scoped collector used fixed 24-entry candidate/group arrays and rejected scopes with more than 32 body entries. The fixed limits were unrelated to input requirements and caused Flay-compatible candidates to be omitted.

## Decision

Grow scoped candidate metadata geometrically with the number of discovered methods. Check growth and element-size overflow, initialize newly allocated method records, and free both candidate contents and backing arrays on all normal/error exits. Allocate group members, line lists, grouped flags, and covered flags to the discovered candidate count. Remove the 24-candidate and 32-body-entry rejections. A generated 40-method CLI contract compares group kind, mass, score, all ordered locations, and complete coverage with pinned Flay 2.14.4. Focused mutations restore the 24-candidate and 32-body-entry limits.

## Consequences

Scoped method collection and grouping use memory proportional to scanned candidates, with checked allocation failures remaining incomplete analysis. The top-level two-method adapter and non-Flay detector limits remain separate.
