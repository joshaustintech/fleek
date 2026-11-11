# 146: Migrate the remaining Reek detectors to the context engine

**What to build:** The remaining 28 detectors run on the ported context engine, one detector per commit, each matching pinned Reek on the Rails manifest and on differential fixtures with complete coverage.

**Part of:** Ticket 24.

**Blocked by:** 145

**Status:** claimed
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Start with the largest census gaps: TooManyStatements (7 missing), NestedIterators (15 incomplete sources), the call and flow group (DuplicateMethodCall, FeatureEnvy, NilCheck, ControlParameter, ManualDispatch, RepeatedConditional, UnusedParameters, UtilityFunction), then data, size and naming detectors, and UnusedPrivateMethod last. Delete each bounded native implementation with its mutations when it migrates.

## Acceptance criteria

- [ ] The ticket 96 census shows every detector complete and identical to pinned Reek on the Rails manifest.
- [ ] Each migrated detector has differential fixtures and caught mutations.
- [ ] Full gate passes after every migration; record results in `## Answer`.

## Progress

- **TooManyStatements.** Migrated to the engine using Reek's StatementCounter rules from `ContextBuilder`: def body, `begin`/`kwbegin`, `if`, `while`/`until`, `for`, `rescue`/`resbody`, `case`/`when` and block bodies. Method names follow `def`/`defs` naming (`Outer#name`, `Outer#self.name`). Directive `max_statements` and suppression come from the context chain, and Reek's default `exclude: ['initialize']` now applies when no exclude is configured. One known gap: an explicitly empty `exclude: []` cannot be distinguished from "unset". On the Rails manifest it reports Reek's exact 7 warnings with 25/25 complete coverage, where before it had 0 of 7 and 12 sources incomplete. The bounded C detector and its 4 mutations were removed. Ten engine mutations are caught: each counting rule, the directive limit, singleton names and the default exclusion.
- **NestedIterators.** Migrated as a port of Reek's `scout` recursion. It finds `block` nodes without entering them, nests through each block's body and keeps the call at the same depth. Iterators matching `ignore_iterators` patterns or taking no block arguments are ignored. Warnings group by depth with their iterator lines, and directive `max_allowed_nesting` and suppression come from the context chain. On the Rails manifest it is complete on 25/25 sources (previously 10/25) and clean like Reek. The bounded C detector and its mutation were removed. Five engine mutations are caught: ignored-iterator depth, argument-less blocks, nesting inside calls, depth grouping and ignore patterns.
- **FeatureEnvy and UtilityFunction.** Migrated together because both rely on the same new engine state. The context tree now follows Reek's context classes more closely:
  - `GhostContext` registers `class << self` children with the enclosing context and gives them singleton kind; the ghost no longer appears in names or directive chains.
  - `refine` blocks open a `RefinementContext` named after the refined constant.
  - `VisibilityTracker` covers `private`/`public`/`protected`/`module_function`, named and inline (`private def`) modifiers, and `public_class_method`/`private_class_method`.
  - `attr_writer`/`attr_accessor`/writable `attr` register attribute contexts.
  - Send contexts and per-context `ObjectRefs` come from `record_call_to` and `record_use_of_self`, covering sends, `op_asgn`, `self`, `super`/`zsuper` and instance variables.
  - Method directives fall back to the parent expression's comment.

  FeatureEnvy reports each most-referenced local receiver unless self ties or wins. UtilityFunction ports `depends_on_instance?`, the send count that ignores classes and modules, and `public_methods_only` from configuration or directive. On the Rails manifest both are complete on 25/25 sources and match Reek exactly: FeatureEnvy now reports the warning it used to miss, 2/2, and UtilityFunction gives 1/1. The bounded C detectors, the visibility branches in the shared C method scanner and 5 mutations were removed. Thirteen engine mutations are caught: self-as-max, object creation, self calls, self dependence, operator assignment, module_function, call-free methods, the public-only directive, named visibility, ghost methods, refinements, parent-expression comments and `super`.
