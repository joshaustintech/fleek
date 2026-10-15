# ADR 0030: Support local-variable writes in class methods

## Status

Accepted.

## Context

Several methods in the pinned Rails corpus assign local variables before calling framework and model methods. The bounded class-method collector rejected Prism `LocalVariableWriteNode`, so it could not establish Flay parity for these method bodies. Flay 2.14.4 ignores variable names for structural grouping but treats different names as non-identical code.

## Decision

Support ordinary Prism `LocalVariableWriteNode` in class-method ASTs. Visit and fingerprint its value expression. Compare assigned variable names when deciding identical versus similar groups; keep variable names out of structural shape equality. Compound/operator writes remain unsupported until separately compared with Flay.

## Consequences

Paired fixtures match Flay's similar `:defn` groups at mass/score 38 and lines 2/10 for local assignments, and mass/score 42 and lines 2/20 when the assigned names differ. Focused mutations prove candidate rejection and identical-versus-similar classification. The 25-file Rails release gate remains open for class-level DSL calls and other unsupported nodes.
