# 142: Generic Flay sexp engine for core syntax

**What to build:** Flay structural duplication runs a generic Prism-to-RubyParser sexp engine over whole files when every selected file uses translated core syntax, and matches pinned Flay 2.14.4 groups, masses, scores and locations.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 141

**Status:** open
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Translate the core node families: program and statements, class, module, singleton-free `def` and `def self.` with every parameter kind, calls with and without receivers and safe navigation, literals (integer, float, string, symbol, nil, true, false, self), arrays, hashes and keyword hashes, local, instance, class and global variable reads and writes, constants, constant paths and constant writes, `if`/`unless`/ternary, `while`/`until`, `and`/`or`/`not`, `return`, and parentheses. Apply Flay's root exclusion, singleton pruning, conservative and liberal pruning, identity and scoring. Any untranslated node falls back to the candidate engine. Fuzzy and legacy-parser runs stay on the candidate engine.

## Acceptance criteria

- [ ] Differential fixtures covering each core family, top-level statements and Rails class-body calls match pinned Flay groups, masses, scores and ordered locations through the public CLI.
- [ ] A file with untranslated syntax still produces the candidate engine's result.
- [ ] Mutations of mass, root exclusion, pruning, identity and representative translation rules are caught.
- [ ] The full repository gate, Flay/Reek self-checks and the Rails manifest contract pass; record results in `## Answer`.

## Execution and stop condition

Follow [ADR 0256](../../../docs/adr/0256-generic-flay-sexp-engine.md). Leave the candidate engine in place; deletion is a later ticket once generic coverage is complete.
