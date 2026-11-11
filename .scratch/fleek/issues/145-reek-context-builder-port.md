# 145: Port Reek's context builder and IrresponsibleModule

**What to build:** A Ruby port of Reek's AST helpers, sexp extensions and `ContextBuilder` over the translated AST, proven by migrating IrresponsibleModule.

**Part of:** Ticket 24.

**Blocked by:** 144

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Port root, module, class, singleton class, method, singleton method, attribute, send, ghost and refinement contexts with visibility tracking, references and statement counts. Migrate IrresponsibleModule through `run_native_reek_detector` and delete its bounded native implementation.

## Acceptance criteria

- [ ] IrresponsibleModule matches pinned Reek on the Rails manifest (25 warnings, including both `ApplicationCable` constants) with complete coverage.
- [ ] Differential fixtures cover nested, namespaced, `Class.new`, `Struct.new` and comment-documented modules.
- [ ] Full gate passes; record results in `## Answer`.
