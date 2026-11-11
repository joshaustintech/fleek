# ADR 0256: Replace shape allowlists with a generic Flay sexp engine

## Status

Accepted

## Context

Flay 2.14.4 parses each file with RubyParser and hashes every sexp node that has at least one sexp child and a mass at or above the threshold. The root sexp of each file is never hashed, because `Sexp#deep_each` yields only descendants. Groups are keyed by structural hash, which ignores atoms. Identity compares full values. Conservative pruning removes every group whose hash occurs below the first node of another group, and the score is `mass × count`, multiplied by `count` again when identical.

Fleek's current engine only recognizes method "candidates" and a growing list of exact class-body shapes (ADRs 0244–0255). Each new real-world file needs another bespoke predicate, fixture set and mutation group, and the 25-file Rails manifest still reports 0/25 complete. The approach does not converge on parity.

## Decision

Add a generic engine beside the candidate engine:

1. Parse each selected file separately with pinned Prism. Use Prism's start line so node lines match the combined-source numbering the reporter already uses.
2. Translate every Prism node into a RubyParser-shaped sexp: a type, ordered children and atom values. A node with no translation rule makes the run untranslatable.
3. Hash-cons sexp shapes (type plus child shapes) and values (type plus children and atoms). This gives exact structural grouping and identity without Flay's 32-bit hash collisions.
4. Reproduce Flay's mass, root exclusion, singleton pruning, conservative and liberal pruning, identical bonus and scoring. Emit the existing tab-separated group records.
5. When every selected file translates, the generic engine's result is authoritative. Otherwise the candidate engine runs unchanged. Fuzzy and legacy-parser modes stay on the candidate engine until generic support for them is proven.

Coverage grows by adding translation rules per Prism node family, each verified against `ruby_parse` output and pinned Flay results. When the generic engine covers everything the candidate engine accepts, plus fuzzy and legacy modes, the candidate engine and the shape predicates from ADRs 0244–0255 are deleted.

## Consequences

- Rails-style class bodies, top-level statements and nested scopes need no shape-specific code; any translated syntax is analyzed.
- Existing public contracts double as differential tests: a file the generic engine accepts must still match Flay exactly.
- Some fixtures that asserted incomplete coverage become complete when their syntax gains a translation rule. Those expectations are updated to the pinned Flay result, never weakened.
- RubyParser quirks (branch swapping for `unless`, `s(:nil)` empty bodies, `args` atoms such as `:"*rest"`, `iter` with `0` for no params) live in one translator, not across detached predicates.
