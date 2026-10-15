# ADR 0019: Reviewed Ruby 4 and Spinel analysis boundaries

## Status

Accepted.

## Context

The parser prototype accepts one Ruby 4.0-only newline-leading `&&` form and a pinned Spinel `ffi_func` declaration, but parser acceptance alone does not prove an analyzer ran correctly. Flay 2.14.4 and Reek 6.6.0 have narrower or different parser and shape behavior, so reference rejection and analyzer-unsupported input must remain visible.

T12's report also printed Flay's identical-group score in the `mass` field. Pinned Flay reports the underlying mass separately and doubles it only for identical-group score, so an identical group with mass 32 has score 64.

## Decision

Keep analyzed source parsing pinned to Prism 1.9.0's explicit Ruby 4.0 grammar. ClassVariable analyzes exactly one simple top-level class (including a superclass) or one simple top-level module, with no nested class/module scopes. It reports direct class-variable occurrences with original source lines and honors the existing adjacent `# :reek:ClassVariable` suppression comment for either scope. A simple module can contain Spinel's compile-time `ffi_func` declaration and ordinary inert calls; Fleek reads but never loads `require`, invokes FFI declarations, or executes source.

The demonstrated Ruby 4 behavior is limited to the newline-leading `&&` expression inside one method, plus direct class-variable detection and suppression in the containing simple class. Reek 6.6.0's Parser 3.3.12 rejects that source with `unexpected token tAMPER` on stderr while returning exit 0. Treat its diagnostic as reference rejection, never as a clean result or parity proof. Ruby 4 findings are separately reviewed extension behavior.

The demonstrated Spinel behavior is limited to a single simple module containing a pinned `ffi_func` declaration, one direct class-variable assignment, and inert source operations. Reek 6.6.0 parses this Ruby-shaped module and matches the ClassVariable finding, context, and line; this is shared-detector parity on that fixture, while FFI non-execution is a Spinel-specific contract.

Extend Flay's bounded two-method subset in two reference-backed shapes: a single top-level simple module whose body contains one `ffi_func` declaration, followed by exactly two top-level parameterless methods; and those same two methods using at most one Ruby 4 multiline `&&` expression with an integer left operand and `true` right operand as the final statement. The operator's operands participate in equality; other operand shapes and non-final/multiple operators remain incomplete. Do not descend into or execute the FFI module. The verified Ruby 4 operator shape is treated as a similar group when method names or integer values differ, matching Flay's reported kind, mass, score, and method locations. All other non-method declarations, nested modules, method parameters, receivers, blocks, and unsupported statements remain incomplete.

Do not introduce a modified Reek reference. Keep unchanged pinned tools for shared syntax and explicit fixture expectations where Reek rejects Ruby 4.

Report Flay node mass and group score as separate values, including for identical groups, and compare both to unchanged Flay output.

## Consequences

Fleek analyzes one simple class or module for ClassVariable while continuing to fail closed on nested scopes. A class superclass is accepted; namespace nesting is still unsupported. A Spinel FFI source example produces a real ClassVariable finding with its original path and line; Ruby 4-only syntax produces a separately reviewed finding with original location. Structural duplication supports only the two reference-verified extension shapes above; unsupported variants remain incomplete. See [ADR 0020](0020-rails-parity-corpus-and-release-gate.md) for the real Rails coverage gate.

## Evidence

`test/language_extensions_contract.rb` checks the Ruby 4 finding and suppression, captures Reek's Ruby 4 parser diagnostic despite its zero exit status, compares the Spinel module finding with unchanged Reek, compares Ruby 4 and Spinel Flay findings, scores, and locations with unchanged Flay 2.14.4, and confirms an embedded require/FFI/module-body side effect did not run. Mutation cases cover Spinel ClassVariable traversal/location, Spinel Flay module traversal and ordering, and Ruby 4 operator operands/final position. The syntax examples and compiler boundary are recorded in [ADR 0008](0008-native-parser-prototype.md) and [the language research note](../research/ruby4-spinel-input.md).
