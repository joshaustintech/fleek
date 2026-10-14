# First useful slice: source feasibility

Research date: 2026-10-14. Eight additional versioned source lookups, plus the tagged evidence in [combined-cli-conflicts.md](combined-cli-conflicts.md). No compiler build, dependency install, parser integration, or analyzer execution occurred. This note recommends experiments; it does not select pins or architecture.

## Reference runtime and analyzed syntax

Reek 6.6.0 requires CRuby-compatible Ruby >= 3.2.0 and declares Parser `~> 3.3.0`, dry-schema `~> 1.13`, Logger `~> 1.6`, Rainbow `~> 3.0`, and REXML `~> 3.1`. Its analyzed source uses `Parser::CurrentRuby`, not Spinel's accepted implementation subset. It forces source to UTF-8 and associates parser comments with AST nodes. Thus selecting Reek 6.6.0 alone does not pin a syntax contract: lock a particular reference Ruby and Parser version. [Gemspec](https://github.com/troessner/reek/blob/v6.6.0/reek.gemspec), [source parser](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/source/source_code.rb).

Flay 2.14.4 defaults to Prism's RubyParser translation; `--legacy` requires RubyParser. Its declared runtime dependencies are Prism `~> 1.7`, sexp_processor `~> 4.0`, Erubi `~> 1.10`, and path_expander `~> 2.0`; Ruby2Ruby is needed for diff generation. These ranges are not exact versions. A modern Prism grammar does not establish equivalent Reek coverage of the same syntax. [Flay parser and diff](https://github.com/seattlerb/flay/blob/v2.14.4/lib/flay.rb), [dependencies](https://github.com/seattlerb/flay/blob/v2.14.4/Rakefile).

Recommendation: first choose and lock a shared reference Ruby syntax target, then prove examples against both tools. Do not claim Ruby 3.4 or Ruby 4 syntax compatibility merely because Spinel or Prism can parse it. Exact supported syntax and package Ruby requirements remain a dependency-lock followup.

## Pinned Spinel: possible parser seam

Spinel 2026.09.12 describes a self-contained C compiler using libprism to parse implementation source, emitting C and linking native executables. It supports source packages carrying `.c` files. That is evidence of a native parser in the compiler, **not evidence that a compiled Fleek program can call it automatically**. [Pinned README](https://github.com/matz/spinel/blob/2026.09.12/README.md).

Its documented FFI permits direct scalar/string/pointer C calls, `ffi_lib`, `ffi_cflags`, embedded `ffi_source`, struct accessors, and callbacks. `:str` is NUL-terminated; binary-safe returns have a separate `:binstr` convention. C pointers are not GC-managed, must be destroyed explicitly, and cannot be stored directly in polymorphic arrays/hashes. Static-link overrides can stop after C generation and drive linking separately. [Pinned FFI specification](https://github.com/matz/spinel/blob/2026.09.12/docs/FFI.md).

Source-feasible experiment: compile one tiny Spinel Ruby program calling a narrow native parser adapter, returning a diagnostic and source location for one input. Use explicit ownership and an explicit input byte length. Then test static linkage and clean-machine runtime independence. This is a proposed seam, not architecture approval or a passed build. The exact vendored Prism version, public API/ABI, node conversion cost, licensing, and static build flags remain unverified.

Directly compiling all upstream Ruby is not established. Spinel's limitations restrict dynamic evaluation, runtime-generated methods and ancestors, runtime-name reflection, encodings, and integer behavior. Explicit AST visitors and closed dispatch may avoid some problems; successful compilation still would not establish reference equivalence. [Pinned limitations](https://github.com/matz/spinel/blob/2026.09.12/docs/limitations.md).

## Smallest useful Reek check

Recommend **ClassVariable** before LongParameterList. This is a named real upstream detector with a small observable rule: for each class/module context, group local `cvar`, `cvasgn`, and `cvdecl` nodes by variable name; emit one finding per name with all occurrence lines, message `declares the class variable '<name>'`, and name metadata. Reads count too, despite the word "declares". Local traversal ignores nested classes/modules, so nested contexts receive their own findings. [Detector source](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/smell_detectors/class_variable.rb), [local traversal](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/context/code_context.rb), [detector docs](https://github.com/troessner/reek/blob/v6.6.0/docs/Class-Variable.md).

Required reference cases: one assignment; repeated reads/writes of one name; two names; class versus module; nested class/module ownership; use inside a method; top-level use; reopening a class; singleton-class context; comments/strings containing `@@`; suppression and enabled/exclude configuration. Last cases need executed receipts before exact behavior is promised. A text search for `@@` is not this detector.

LongParameterList is also small at its final rule: compare `expression.arg_names.length` against configured `max_params` (default 3; default `initialize` override 5), emit above the limit with the source line, count metadata, and `has <count> parameters`. But parameter extraction across positional/optional/keyword/rest/block/destructuring/forwarded arguments requires upstream AST helpers; counting commas cannot reproduce it. The detector prose mentions methods/blocks but does not settle exact context/extraction behavior. [Detector source](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/smell_detectors/long_parameter_list.rb), [docs](https://github.com/troessner/reek/blob/v6.6.0/docs/Long-Parameter-List.md).

## Smallest useful duplication check

Recommend **Flay's default structural duplication analysis**, initially with a documented supported source grammar. Flay does not expose a small independent detector comparable to Reek ClassVariable. Supporting only byte-identical methods would create a different rule, not a compatible subset of the default analyzer. Flay ignores literal values and names when structurally hashing nested S-expressions; it includes nodes with children whose mass reaches the threshold (default 16), removes singleton groups, and conservatively prunes covered subtrees. It scores the surviving group as first-node mass times occurrence count, multiplied again by occurrence count for identical groups, then sums total score. Locations and ordering are part of the result. [Default options, structural hash, traversal, pruning, scoring, and report source](https://github.com/seattlerb/flay/blob/v2.14.4/lib/flay.rb).

Required reference cases: equal methods; renamed method/variables and changed literal values; genuinely different node structure; two files; mass immediately below/at threshold; nested duplicate subtrees; identical multiplier versus merely similar structure; stable ties/locations; no findings; malformed syntax. Exact `Sexp#mass`, equality, and Prism-to-Sexp translation belong to locked dependencies and remain followups. Do not infer these from printed source length or token counts.

Start with normal pruning and no fuzzy/liberal/diff behavior; explicitly reject those unsupported requests. A source grammar restriction must fail when encountered outside its supported boundary. A first fixture is useful integration evidence, but passing one fixture is not release-level Flay compatibility.

## Decisions needed before implementation

1. Select reference Ruby/package locks and the analyzed syntax target.
2. Agree whether ClassVariable and default structural duplication are the first useful acceptance targets.
3. Approve a bounded native parser experiment; decide architecture only from compile/runtime evidence.
4. Define supported grammar/settings and require explicit failure outside that scope.
