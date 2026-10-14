# ADR 0010: ClassVariable occurrence grouping and scope boundary

## Status

Accepted for ticket 04.

## Reference behavior

Reek 6.6.0 groups a class's reads and writes by class-variable name, lists all occurrence lines in the warning, and reports different names separately. Method-body and `class << self` occurrences belong to the surrounding class context. A class-variable expression at top level produces no ClassVariable finding. Nested classes and modules produce their own qualified contexts without leaking their occurrences into the enclosing class. Reopened class declarations produce findings separately for each declaration.

## Decision

Extend the native slice to group all Prism class-variable node forms by name within one simple top-level class declaration, preserving source occurrence lines and sorting distinct names like Reek. This includes plain writes, `+=`, `||=`, `&&=`, reads, and multi-target assignment. Include method and singleton-class descendants. Match Reek's clean behavior when source contains only top-level class-variable expressions.

Reject nested class/module declarations, multiple class declarations (including reopenings), modules, inheritance, and complex class names with an explicit error. This keeps context attribution honest until qualified and repeated contexts have a tested ownership model. It does not claim complete nested/reopened-class coverage.

## Consequences

The supported findings now match Reek across repeated reads/writes, multiple names, method use, singleton use, and top-level-only source. Other contexts remain errors instead of partial clean results. Mutations verify grouping and nested-scope rejection.
