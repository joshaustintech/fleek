# 144: Translate Prism trees into Reek's parser-gem AST

**What to build:** Native translation of every Prism node into the parser-gem AST shape Reek 6.6.0 receives, serialized for Fleek's Ruby with node types, children, atoms, lines, expression ranges and comments.

**Part of:** Ticket 24.

**Blocked by:** 143

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Follow `Prism::Translation::Parser` from prism 1.9.0 with the parser gem's legacy builder defaults and Reek's `emit_lambda`. Cover definitions, calls (`send`/`csend`, legacy `[]`), blocks, arguments (`arg`, `optarg`, `restarg`, `kwarg`, `kwoptarg`, `kwrestarg`, `blockarg`, `shadowarg`), assignments, control flow, literals, interpolation, patterns and `rescue`/`ensure`. Add a Ruby reader that rebuilds uniform nodes.

## Acceptance criteria

- [x] Golden fixtures pin the serialized AST for each node family, written from the parser gem's documented shapes.
- [x] Translation mutations for representative families are caught.
- [x] Full gate passes; record results in `## Answer`.

## Answer

The native translator emits the parser-gem AST Reek 6.6.0 builds: `Parser::CurrentRuby` is Ruby34 under Ruby 3.4.9, with every legacy builder mode except `emit_lambda`. It covers definitions, legacy `[]` sends, `csend`, blocks and numbered blocks, all argument kinds, assignments and op-assigns, multiple assignment, control flow, `rescue`/`ensure`, interpolation, per-line string composition, `match_with_lvasgn`, and the legacy pattern-matching nodes. An `annotate` flag adds `@line:begin:end` expression ranges for the coming Ruby context engine. `fleek --reek-ast SOURCE` prints the un-annotated tree.

Instead of hand-written golden files, `test/reek_ast_contract.rb` compares against the pinned parser gem's own `ruby-parse` with Reek's flags; the reference is the oracle. Its fixtures cover core shapes, patterns, strings and flow. A development sweep over all 487 Ruby sources in the repository fixtures and the Rails manifest matched exactly for all 481 sources the reference parser accepts. The six that differ are Ruby 4-only extension fixtures the pinned parser rejects. Six translation mutations are caught.

Two Spinel 2026.09.12 runtime defects surfaced in the long-running harness: redirected child output can still be landing after `waitpid2` returns, and `String#split(/\s+/)` intermittently returns wrong tokens. The contract has children write their own files through `sh -c` and splits without a regexp; see [issue 147](147-spinel-runtime-defects.md).
