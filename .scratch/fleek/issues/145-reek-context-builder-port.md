# 145: Port Reek's context builder and IrresponsibleModule

**What to build:** A Ruby port of Reek's AST helpers, sexp extensions and `ContextBuilder` over the translated AST, proven by migrating IrresponsibleModule.

**Part of:** Ticket 24.

**Blocked by:** 144

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Port root, module, class, singleton class, method, singleton method, attribute, send, ghost and refinement contexts with visibility tracking, references and statement counts. Migrate IrresponsibleModule through `run_native_reek_detector` and delete its bounded native implementation.

## Acceptance criteria

- [x] IrresponsibleModule matches pinned Reek on the Rails manifest (25 warnings, including both `ApplicationCable` constants) with complete coverage.
- [x] Differential fixtures cover nested, namespaced, `Class.new`, `Struct.new` and comment-documented modules.
- [x] Full gate passes; record results in `## Answer`.

## Answer

`bin/reek_engine.rb` ports Reek 6.6.0's AST node helpers (`format_to_ruby`, `leading_comment`, statements) and the parser gem's comment `Associator` in its structural-equality mode. It also ports the TreeDresser comment dressing, `ContextBuilder` (root, module/class, module-defining `casgn`, ghost, method and singleton method contexts), constant full names, `CodeComment#descriptive?`, and inherited directive suppression. The native translation now annotates nodes with expression ranges, marks heredocs, and exports comment ranges.

IrresponsibleModule is the first detector on the engine. Its bounded C implementation, helpers and 7 mutations were deleted. On the pinned Rails manifest it now reports Reek's exact 25 warnings with 25/25 complete coverage; previously both `ApplicationCable` sources were incomplete. `test/reek_engine_contract.rb` compares fixtures directly with pinned Reek. They cover namespaces, constant-path modules, `Struct.new`/`Class.new`/`Data.define`, plain constants, mixed modules, directive suppression of a class and its child, trailing and one-word comments, and a single-statement file. Bounded-shape object-scope checks that expected "unsupported" now assert Reek parity.

Six engine mutations are caught: the descriptive threshold, namespace modules, directive suppression, parent suppression, `Struct` modules and root naming. One mutation was excluded as equivalent: changing `leading_comment` from `<` to `<=` cannot affect module contexts, because a comment on a module's first line always decorates the constant-name child, which is visited first.

Spinel note: values taken from nested arrays must be passed through `to_s` before `Process.spawn`, or they are silently dropped from the argument list.
