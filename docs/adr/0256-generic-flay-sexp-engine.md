# ADR 0256: Replace shape allowlists with a generic Flay sexp engine

## Status

Accepted. Supersedes the shape-specific boundaries of ADRs 0244–0255.

## Context

Flay 2.14.4 parses each file with its default parser, `Prism::Translation::RubyParser` from prism 1.9.0, using `partial_script: true`. It hashes every sexp node that has at least one sexp child and a mass at or above the threshold. The root sexp of each file is never hashed, because `Sexp#deep_each` yields only descendants. Groups are keyed by structural hash, which ignores atoms. Identity compares full values with Ruby `==`. Conservative pruning removes every group whose hash occurs below the first node of another group. The score is `mass × count`, multiplied by `count` again when identical.

Fleek's original engine only recognized method "candidates" and a growing list of exact class-body shapes (ADRs 0244–0255). Each new real-world file needed another bespoke predicate, fixture set and mutation group, and the 25-file Rails manifest reported 0/25 complete. That approach could not converge on parity.

## Decision

Replace the candidate engine with one generic engine:

1. Parse each selected file separately with pinned Prism, starting line numbers at the file's line in the combined source the reporter uses.
2. Port `Prism::Translation::RubyParser` node by node into C. That covers every node type, `in_def`/`in_pattern` state, line and `line_max` attribution, interpolated-part merging, `and`/`or` right-nesting, `svalue` write values, and `__FILE__` from the selected path.
3. Hash-cons sexp shapes (type plus child shapes) and values (type plus children and canonical atoms). This gives exact structural grouping without Flay's 32-bit hash collisions. Atoms follow Ruby `==`; for example, `1` equals `1.0` and `1r`.
4. Reproduce Flay's processing: mass, root exclusion, singleton and all-fuzzy pruning, conservative and liberal pruning, fuzzy template combinations, identity and scoring. Emit the existing tab-separated group records.
5. Delete the candidate engine. `--legacy` keeps its existing syntax rejection check, then uses the same translation. A source the engine cannot translate is reported incomplete, never silently skipped.

## Consequences

- Rails-style class bodies, top-level statements, nested scopes and every Ruby construct shared with Flay need no shape-specific code.
- The differential contract compares whole-file fixtures with pinned Flay. All 299 existing duplication fixtures and the 25-file Rails manifest match exactly.
- Fixtures that asserted incomplete coverage for now-translated syntax assert Flay parity instead. Expectations were updated to the pinned Flay result, never weakened.
- Mutation coverage moves from candidate predicates to the engine's mass, root exclusion, pruning, identity, fuzzy and representative translation rules.
- `--legacy` assumes RubyParser 3.22 and the Prism translation produce the same sexps for syntax both accept. Any difference found later is a translation bug to fix, not a reason to restore the candidate engine.
