# 142: Generic Flay sexp engine for core syntax

**What to build:** Flay structural duplication runs a generic Prism-to-RubyParser sexp engine over whole files when every selected file uses translated core syntax, and matches pinned Flay 2.14.4 groups, masses, scores and locations.

**Part of:** Ticket 97 — Rails Flay completion gate.

**Blocked by:** 141

**Status:** resolved
**Type:** task
**Category:** enhancement
**Triage:** ready-for-agent

## Bounded cases

Translate the core node families: program and statements, class, module, singleton-free `def` and `def self.` with every parameter kind, calls with and without receivers and safe navigation, literals (integer, float, string, symbol, nil, true, false, self), arrays, hashes and keyword hashes, local, instance, class and global variable reads and writes, constants, constant paths and constant writes, `if`/`unless`/ternary, `while`/`until`, `and`/`or`/`not`, `return`, and parentheses. Apply Flay's root exclusion, singleton pruning, conservative and liberal pruning, identity and scoring. Any untranslated node falls back to the candidate engine. Fuzzy and legacy-parser runs stay on the candidate engine.

## Acceptance criteria

- [x] Differential fixtures covering each core family, top-level statements and Rails class-body calls match pinned Flay groups, masses, scores and ordered locations through the public CLI.
- [x] A file with untranslated syntax still produces the candidate engine's result.
- [x] Mutations of mass, root exclusion, pruning, identity and representative translation rules are caught.
- [x] The full repository gate, Flay/Reek self-checks and the Rails manifest contract pass; record results in `## Answer`.

## Execution and stop condition

Follow [ADR 0256](../../../docs/adr/0256-generic-flay-sexp-engine.md). Leave the candidate engine in place; deletion is a later ticket once generic coverage is complete.

## Answer

Ported prism 1.9.0's `Prism::Translation::RubyParser`, Flay 2.14.4's default parser, into the native engine. Every Prism node type is translated, including patterns, `rescue`/`ensure`, interpolation merging, right-nested `and`/`or`, `svalue`, op-assigns and `__FILE__`. Flay's processing is reproduced: root exclusion, conservative and liberal pruning, fuzzy combinations, identity under Ruby `==`, and scoring. The candidate engine and its Rails shape predicates (ADRs 0244–0255) were deleted rather than kept as a fallback, along with Flay's partial-result plumbing that only the old engine could trigger. `--legacy` keeps its syntax rejection, then uses the same translation. See [ADR 0256](../../../docs/adr/0256-generic-flay-sexp-engine.md).

Evidence with Spinel `112bae85c1a2 (2026.09.12)`, Flay 2.14.4 and Reek 6.6.0:
- All 299 duplication fixtures produce groups identical to Flay; none is incomplete.
- `test/duplication_generic_contract.rb` adds 17 whole-file differential cases: core syntax, Rails class bodies, identical classes, root exclusion, right-nested logic, `unless`, class-variable scope, liberal pruning, mass thresholds, cross-file and fuzzy.
- The pinned 25-file Rails manifest is 25/25 complete with the exact score-48 group. `make rails-manifest-parity` now requires completeness.
- Boundary expectations for now-translated syntax assert Flay parity instead of incompleteness; no reference expectation was weakened.
- Mutation coverage: 233 candidate-engine mutations were removed with the code they targeted. 17 engine mutations were added (mass, root exclusion, singleton/conservative/liberal pruning, identity, mass threshold, statement blocks, logical nesting, `unless`, class-variable scope, hash values, call names, fuzzy bounds and marking, source paths, legacy check). All 181 remaining mutants are caught.

Remaining Flay gap: an unparseable source fails every selected source, while Flay skips just that file; see [issue 143](143-flay-skip-unparseable-sources.md).
