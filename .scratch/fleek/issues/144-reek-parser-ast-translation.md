# 144: Translate Prism trees into Reek's parser-gem AST

**What to build:** Native translation of every Prism node into the parser-gem AST shape Reek 6.6.0 receives, serialized for Fleek's Ruby with node types, children, atoms, lines, expression ranges and comments.

**Part of:** Ticket 24.

**Blocked by:** 143

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Follow `Prism::Translation::Parser` from prism 1.9.0 with the parser gem's legacy builder defaults and Reek's `emit_lambda`. Cover definitions, calls (`send`/`csend`, legacy `[]`), blocks, arguments (`arg`, `optarg`, `restarg`, `kwarg`, `kwoptarg`, `kwrestarg`, `blockarg`, `shadowarg`), assignments, control flow, literals, interpolation, patterns and `rescue`/`ensure`. Add a Ruby reader that rebuilds uniform nodes.

## Acceptance criteria

- [ ] Golden fixtures pin the serialized AST for each node family, written from the parser gem's documented shapes.
- [ ] Translation mutations for representative families are caught.
- [ ] Full gate passes; record results in `## Answer`.
