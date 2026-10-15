# 18: Namespaced ClassVariable contexts

**What to build:** `reek:ClassVariable` analyzes ordinary namespaced Rails classes and modules with the same finding contexts, grouping, source lines, and configuration scope as Reek 6.6.0. Parent specification: Language support and real-project parity.

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

- [x] Add failing CLI/reference cases for `module ApplicationCable; class Connection < Base; ... end; end`, including clean and class-variable finding cases.
- [x] Preserve qualified context, occurrence grouping and lines, suppression/config semantics, and fail-closed behavior for unsupported deeper/reopened scope.
- [x] Mutation checks prove namespace traversal/context changes are detected.
- [x] Full project build, tests, Flay, Reek, mutation, and both code-review axes pass.

**Release gate:** Closed for ClassVariable: the exact 25-file Rails corpus now completes with the same clean result as Reek. Overall Rails parity remains blocked by ticket 19's Flay gap.

## Answer

ClassVariable now supports a single module namespace around one simple class or module, with qualified Reek contexts, and reports incomplete for deeper/sibling namespaces or class variables declared on the outer namespace. The pinned Rails app's complete 25-file Ruby manifest now matches Reek's clean ClassVariable result (25 analyzed, 0 failed). ADR 0021 records the boundary. Flay's class-method gap remains ticket 19 and continues to block release.
