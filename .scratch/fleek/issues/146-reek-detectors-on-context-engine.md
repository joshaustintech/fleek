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
- **NilCheck.** Migrated as a port of `NodeFinder` over method contexts. It flags `nil?` sends, and `==`/`===` sends where nil is the receiver or an argument; `local_nodes` stops at classes and modules. It also flags `when` clauses with a nil condition. Safe navigation (`&.nil?`) and `!=` are not reported. On the Rails manifest it is complete on 25/25 sources (previously 19/25) and reports Reek's 4/4 warnings, including the previously missing `User#authenticated?`. The bounded C detector, its 3 mutations and the stale contract dispatches were removed. Three engine mutations are caught: nil queries, case equality and `when nil`.
- **DuplicateMethodCall.** Migrated as a port of `CallCollector`, which groups sends and then blocks by parser-node structural equality (the engine's `node.key`). It skips `new` calls and receiverless calls without arguments. The send search stops at `mlhs`, classes and modules, and the block search at classes and modules. Call text comes from `format_to_ruby`. `max_calls` and `allow_calls` come from configuration or the nearest directive; a directive list replaces the configured list. On the Rails manifest it is complete on 25/25 sources (previously 19/25) and reports Reek's 5/5 warnings, including the previously missing `SessionsController#create` `params[:session]`. The bounded C detector, its stale mutation and its dispatch were removed. Six engine mutations are caught: object creation, simple calls, blocks, assignment targets, the directive limit and allowed calls.
- **ControlParameter.** Migrated as a port of `ControlParameterFinder` and `CallInConditionFinder` over every parameter name, block parameters included. The port follows Reek's per-node `body_nodes` rules for methods, `if`, `case` and `and`/`or`. A parameter is a legitimate use when it appears in a non-comparison call in a condition or in a branch body, and the search recurses into nested conditionals. `each_node` now follows Reek's `look_for` root rule: an ignored root is only left unsearched when it also matches. On the Rails manifest it is complete on 25/25 sources (previously 19/25) and is clean like Reek, which removes the extra warning. The bounded C detector, its four helpers, the dead `fleek_any_parameter_used` and four mutations were removed, and the shared UnusedParameters scanner no longer counts control findings. Five engine mutations are caught: calls in conditions, comparisons, body uses, logical bodies and nested branches.
- **UnusedParameters.** Migrated as a port of `MethodContext#unused_params`, which checks argslist components with destructured `mlhs` parameters flattened. Block arguments, anonymous splats (`*`, `**`, `...`, `**nil`) and `_`-prefixed names are skipped, and a parameter counts as used when a local `lvar`/`lvasgn` names it; the search stops at classes and modules. Methods whose body contains `zsuper` are skipped. ControlParameter shares the flattened parameter list, so destructured parameters are now considered there too. On the Rails manifest it is complete on 25/25 sources (previously 19/25) and is clean like Reek. The shared C method-API scanner, its block and implicit-super helpers and three mutations were removed; one of those mutations now targeted another detector's helper. The block-shadowing contract became a row in the pinned nested-case table. Six engine mutations are caught: implicit super, underscore markers, reads, assignments, block arguments and destructuring.
- **BooleanParameter, LongParameterList and LongYieldList.** Migrated together on the shared parameter components:
  - BooleanParameter flags `optarg`/`kwoptarg` parameters that default to `true`/`false`.
  - LongParameterList counts every non-block parameter. `max_params` comes from the nearest directive, else from the configured `overrides.initialize` value when the context's full name contains `initialize`, else from the configured limit.
  - LongYieldList checks each `yield`'s arguments, stopping at classes and modules.

  Directive resolution now ports `CodeComment#config`: on each context the last directive for a detector replaces earlier ones, a bare directive means `{ enabled: false }`, and options resolve key by key up the parent chain. The existing repeated-directive suppression contract caught this. On the Rails manifest all three are complete on 25/25 sources (previously 22/25) and are clean like Reek. The three bounded C detectors, eight mutations, including one whose target had become a generic visitor line, and their dispatches were removed. Ten engine mutations are caught: false and keyword boolean defaults, block arguments in counts, the initialize override, the parameter directive, the yield limit boundary, last-directive-wins, comment suppression, parent suppression and the statement directive.
- **TooManyConstants, TooManyInstanceVariables, TooManyMethods and ModuleInitialize.** Migrated over module contexts whose expression type each detector accepts (`class`/`module`, `class` or `module`):
  - Constants count `casgn` nodes that do not define modules.
  - Instance variables count distinct `ivasgn` names outside `||=`.
  - Methods count every `def` below the class, including those in `class << self`.
  - All three counts stop at nested classes and modules.
  - ModuleInitialize looks for an instance-method child (method or attribute) named `initialize`.

  The three size detectors share one table-driven `module_size`, and the engine now has shared `configured_limit` and `count_record` helpers, which keeps bin Flay at zero. On the Rails manifest all four are complete on 25/25 sources (previously 23/25) and are clean like Reek. The bounded C size scanner, the ModuleInitialize scanner and 11 mutations were removed. The nested size contracts became rows in the pinned nested-case table, which drops the test Flay score from 1007 to 818. Eleven engine mutations are caught, including the updated limit-helper targets.
- **Attribute, InstanceVariableAssumption, SubclassedFromCoreClass, MissingSafeMethod and ManualDispatch.** Migrated together:
  - Attribute reports public attribute contexts whose argument is a symbol, named `Outer#attr` through a new `sym` naming case.
  - InstanceVariableAssumption subtracts names assigned in `initialize` from instance variables read outside `||=` across the class's `def` nodes.
  - SubclassedFromCoreClass reads a class's superclass, or the first argument of a bare `Class.new` constant, by const name, so namespaced `::Hash` does not match.
  - MissingSafeMethod checks the class's bang `def`s for a same-named companion without the bang, honoring a directive `exclude` list.
  - ManualDispatch collects `respond_to?` send lines per method.

  On the Rails manifest all five are complete on 25/25 sources (Attribute was already complete; the rest were previously 19 to 23 of 25) and match Reek, including Attribute 3/3 and InstanceVariableAssumption 4/4. The bounded C scanners, the MissingSafeMethod singleton branch in the shared method scanner, the dead `fleek_parameter_count` and 13 mutations were removed. Object-scope contracts that expected incomplete coverage now assert complete Reek parity through a shared `AnalysisRunner.assert_complete_parity`. Nine engine mutations are caught.
