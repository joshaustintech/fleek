# ADR 0008: Use pinned Prism for the native parser prototype

- Status: accepted for prototype; not a production parser contract
- Date: 2026-10-14

## Context

Fleek needs to inspect Ruby 4.0 and Spinel source without loading or executing analyzed files. Reek's locked Parser dependency does not provide Ruby 4 grammar. Spinel's own source frontend performs compiler-specific source rewriting and dependency resolution, so it is not a neutral analyzer parser. The pinned Spinel release already vendors Prism 1.9.0 and exposes its C API.

## Decision

Use the Prism C API embedded in the Fleek executable for a developer parser probe. Compile it with the pinned Spinel compiler and link the Prism archive from the exact pinned Spinel checkout. Set `PM_OPTIONS_VERSION_CRUBY_4_0` explicitly. The probe parses source bytes only, reports parse success or Prism's first syntax diagnostic with its byte offset and line/byte-column, and always labels success as parsing only. It does not claim an analysis check ran. Missing and unreadable files return a concise CLI error and status 1.

Initialize parser options and parser state for each input and free both after parsing. Reject embedded NUL bytes before calling Prism because NUL may otherwise terminate or truncate parser input ambiguously. Use the input's explicit byte length. Repeated parses of the same input produce identical results.

The prototype accepts a Ruby 4.0 newline-logical-operator form that is rejected when a test mutation selects Prism's Ruby 3.3 grammar. It also accepts a source fixture with a comment, an inert `require`, and a Spinel `ffi_func` declaration. It does not load the required file, resolve the FFI declaration, execute source, or claim general Spinel syntax compatibility. These fixtures define the demonstrated syntax boundary; broad grammar coverage remains unproven.

## Consequences

- The executable is standalone with respect to Ruby, Flay, and Reek runtimes; `otool -L` shows only macOS `libSystem`.
- The parser is a pinned implementation detail of the current Spinel toolchain, not a separately selected dependency. Its upstream license is MIT.
- Prism error locations are exposed as original byte offsets and 1-based lines/byte-columns. Multi-byte display columns and complete diagnostic messages are not part of this prototype.
- Spinel source is analyzed as Ruby syntax. Spinel compiler acceptance, lowering, or type checking is not required.
- Embedded NUL source is reported unsupported, never successful.
- This parser command is a feasibility probe, not an enabled lint check or evidence that any finding was evaluated.
- The probe does not expose or compare ASTs. AST fidelity and analyzer parity remain later acceptance gates.
