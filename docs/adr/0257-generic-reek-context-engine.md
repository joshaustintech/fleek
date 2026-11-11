# ADR 0257: Port Reek's context engine instead of bounding detector shapes

## Status

Accepted

## Context

All 29 Reek detectors exist natively, but each accepts only bounded syntax and reports anything else as incomplete. The ticket 96 census, rerun after ADR 0256, still shows only Attribute and ClassVariable complete on the pinned 25-file Rails manifest. Six detectors also have finding differences. Nested-scope support was added one depth at a time (ADRs 0060–0093, 0239–0241). This is the same non-converging pattern that ADR 0256 removed from Flay.

Reek 6.6.0 parses with the parser gem (`Parser::CurrentRuby` 3.3.12, legacy builder defaults plus `emit_lambda = true`). It dresses the AST with node-type extensions and builds a context tree (root, module, class, singleton class, method, singleton method, attribute, send, ghost and refinement contexts) that records references, visibility and statement counts. Each detector inspects the contexts it declares. Findings depend only on that AST and context tree, the detector logic, and configuration.

## Decision

Build one engine that mirrors Reek's pipeline:

1. **Native translation.** C translates each pinned Prism tree into the parser-gem AST shape Reek receives, following `Prism::Translation::Parser` with Reek's builder flags. It serializes uniform nodes: type, children (nodes or typed atoms), first line, and expression byte range. Comments are serialized with their ranges.
2. **Ruby port.** Fleek's Spinel Ruby ports Reek's `AST::Node` helpers, sexp extensions, `ContextBuilder`, contexts and detectors close to line-for-line. Spinel constraints apply: uniform node objects, `yield` instead of block forwarding, and no reflection.
3. **Incremental migration.** Detectors move one at a time behind the existing `run_native_reek_detector` seam, producing the same finding records. Each migrated detector's bounded native implementation is deleted with its mutations, and differential fixtures against pinned Reek replace its boundary fixtures.
4. **Unchanged configuration.** Reek configuration, exclusions and suppression comments keep their existing behavior and tests.

## Consequences

- Detector parity becomes a property of the shared AST and context port, not of per-shape predicates, so Rails and arbitrary nesting work once the port is faithful.
- Differences between Prism's parser translation and the parser gem's own Ruby 3.3 parser are translation bugs, found with differential fixtures against pinned Reek.
- Until a detector migrates, its bounded native implementation remains authoritative and keeps reporting incomplete coverage honestly.
