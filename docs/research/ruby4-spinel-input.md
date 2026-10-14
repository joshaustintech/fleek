# Ruby 4 and Spinel analyzed source

Research date: 2026-10-14. The requested analyzed-source targets are Ruby 4 and pinned Spinel source. Fleek's implementation compiler remains Spinel 2026.09.12. Eight bounded primary-source lookups; no build, installation, or executed grammar test. Existing analyzer evidence comes from [combined CLI research](combined-cli-conflicts.md).

## Runtime is not grammar

Reek 6.6.0's `required_ruby_version >= 3.2.0` does not certify Ruby 4 analyzed grammar. Its source parser calls `Parser::CurrentRuby` and its dependency permits Parser `~> 3.3.0` (3.3.x, below 3.4). The current published Parser is **3.3.12.0**, which is within that range. Its tagged `current.rb` has no Ruby 4 branch: an unrecognized runtime version falls back to Ruby33 with a syntax-deviation warning. Its own documentation says use Prism for Ruby 3.4+. Upgrading within the currently published allowed range therefore does **not** give stock Reek a Ruby 4 parser. Some source accepted by Ruby 4 will still work because it also uses older syntax; that does not establish whole-language compatibility. [Reek gemspec](https://github.com/troessner/reek/blob/v6.6.0/reek.gemspec), [Reek source parser](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/source/source_code.rb), [Parser registry](https://rubygems.org/api/v1/gems/parser.json), [Parser 3.3.12.0 dispatch](https://github.com/whitequark/parser/blob/v3.3.12.0/lib/parser/current.rb), [Parser/Prism integration guide](https://github.com/whitequark/parser/blob/v3.3.12.0/doc/PRISM_TRANSLATION.md).

Flay 2.14.4 defaults to Prism RubyParser translation and permits Prism `~> 1.7` (1.x, below 2). **Prism 1.7.0 itself already declares a CRuby 4.0 syntax mode**, separately from 3.3, 3.4, and latest (4.1). It exposes `pm_options_version_set`; omitting an explicit version uses the current Prism behavior. This establishes an available Ruby 4 native grammar within Flay's dependency range, but not that Flay explicitly selects 4.0 or that every translated node yields correct duplication semantics. Do not infer that `latest` means Ruby 4.0. A later patch is not needed merely to obtain the documented mode; no exact dependency pin is selected here. [Flay parser](https://github.com/seattlerb/flay/blob/v2.14.4/lib/flay.rb), [Flay dependency declaration](https://github.com/seattlerb/flay/blob/v2.14.4/Rakefile), [Prism 1.7.0 syntax modes and API](https://github.com/ruby/prism/blob/v1.7.0/include/prism/options.h).

## Spinel source target

The pinned Spinel Makefile specifies Prism **1.9.0** as its default fetched version, prefers a vendored tree, otherwise can use an installed gem, and links `build/libprism.a`. Thus a tag alone must not allow an ambient parser to silently determine the build. Record the actual vendored parser identity with the compiler receipt. [Pinned Makefile, lines 22–34 and dependency rules](https://github.com/matz/spinel/blob/2026.09.12/Makefile#L22-L34).

Spinel's frontend resolves `require` inputs, performs syntax-sugar rewrites, and then calls `pm_parser_init(..., NULL)` before flattening the AST. It does not select an explicit Ruby 4 grammar option there. Its frontend is a compiler pipeline, not a neutral analysis API: importing it wholesale can splice dependencies or rewrite the user's source before finding attribution. [Pinned frontend](https://github.com/matz/spinel/blob/2026.09.12/src/spinel_parse.c) (`sp_parse_emit`).

Spinel also supplies FFI declarations as Ruby-shaped DSL calls and gives string literals frozen semantics. These are source/runtime semantics beyond ordinary CRuby usage, not evidence of a wholly separate grammar. The known limitations restrict dynamic features and encoding behavior. The phrase “Spinel source” needs a defined contract: recommend source accepted by this pinned compiler, including documented declarations, analyzed without running or loading it. Do not require Ruby 4 source to compile under Spinel. [Pinned FFI](https://github.com/matz/spinel/blob/2026.09.12/docs/FFI.md), [pinned limitations](https://github.com/matz/spinel/blob/2026.09.12/docs/limitations.md).

No exhaustive Spinel extension list or Prism 1.9.0 grammar parity is certified by this research. The Makefile default is verified; actual release-archive contents, syntax tests, and diagnostics still need an executed receipt.

## Reference verification when originals cannot parse

Proposal: retain unchanged pinned originals as the compatibility oracle for the shared grammar. Treat parser rejection as a recorded boundary, never as a clean finding result.

For Ruby 4-only syntax, separately prove acceptance/rejection and locations with an explicitly versioned Ruby 4/Prism parser. Define detector expectations in reviewed fixtures and carry ordinary-syntax metamorphic pairs where their semantics are comparable. Label those fixtures as Ruby 4 extension behavior, not unchanged-Reek equivalence.

A secondary Reek experiment using Prism's Parser translation could reuse detector logic, but it is a **modified reference**. The Parser guide requires a compatible custom builder base for Prism and warns that new node types can lack old Parser counterparts. Reek has its own builder/comment association, so swapping parser construction alone does not establish a trustworthy oracle. If pursued, lock it separately and compare its common-grammar outputs to stock Reek first. [Parser integration and custom builder requirements](https://github.com/whitequark/parser/blob/v3.3.12.0/doc/PRISM_TRANSLATION.md), [Reek parser/builder wiring](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/source/source_code.rb).

## Native parser experiment: required proof

1. Explicit Ruby 4.0 syntax selection; accepted Ruby 4 examples plus invalid examples; no accidental 4.1/latest behavior.
2. Pinned Spinel-source declarations and sugar examples; original byte offsets/lines survive any required transformation.
3. Native parser ownership, binary-safe length, diagnostics, comments, and deterministic repeated parsing.
4. AST adapters preserve ClassVariable scopes/names/occurrence lines and Flay structural shape/mass/pruning on the shared grammar.
5. Ordinary Ruby analysis never executes `require`, FFI declarations, or analyzed code.
6. Static linkage and standalone Apple Silicon runtime without Ruby, Flay, or Reek.

These are acceptance proposals, not passed checks. No compiler change or new dependency pin follows automatically from expanding the analyzed-source target.
