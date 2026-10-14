# One combined Fleek CLI: upstream conflicts

Research date: 2026-10-14. Scope: one analysis mode that reports duplicate code and code smells. No implementation or upstream execution was performed. Facts below come from tagged source and official release registries; recommendations remain proposals.

## Reference candidates

The official RubyGems APIs currently report **Flay 2.14.4**, released 2026-04-14, and **Reek 6.6.0**, released 2026-10-02, as current, non-yanked releases. `git ls-remote --tags` verified Flay `v2.14.4` at `1ec4d87f2209a3ae216aece69a4ecc8b688cd459` and Reek `v6.6.0` at peeled commit `e0048db109ea13630630bf130492025cd1c786a5`. These are candidates, **not selected pins**. Pinning must also lock reference dependencies and the Ruby interpreter, because parser behavior can vary.

Sources: [Flay registry](https://rubygems.org/api/v1/gems/flay.json), [Reek registry](https://rubygems.org/api/v1/gems/reek.json), [Flay tag](https://github.com/seattlerb/flay/tree/v2.14.4), [Reek tag](https://github.com/troessner/reek/tree/v6.6.0).

## Options cannot be combined unchanged

The option definitions establish five direct short-option conflicts. Long names generally separate the behavior, but plugin options can add further names. Neither core parser defines a general `--quiet`, `--exclude`, or `--threshold` option. Do not promise these as upstream-compatible options.

| Option | Flay 2.14.4 | Reek 6.6.0 | Proposed Fleek resolution |
|---|---|---|---|
| `-f` | `--fuzzy [DIFF]`, optional integer | `--format FORMAT` | Require long names initially; avoid this alias. |
| `-l` | `--liberal`, changes pruning | `--list`, lists detectors and exits | `--liberal` and `--list-checks`. |
| `-s` | `--summary`, per-file scores | `--single-line`, editor locations | Keep distinct long options; reject ambiguous alias. |
| `-t` | Both `--timeout TIME` and `--legacy` register `-t` in this release | `--todo`, writes configuration | Long names only. Upstream Flay alias behavior needs an executed fixture before any promise. |
| `-v` | `--verbose`, file progress | `--version`, prints version and exits | `--version` for Fleek version and reference pins; `--verbose` for diagnostics. |
| `-h`, `--help` | Help and exit | Help and exit | Shared Fleek help. |
| `-m`, `--mass` | Node mass threshold, default 16 | No shared CLI threshold; detectors have individual settings | `--mass` affects duplication only. No shared numeric lint threshold. |
| `-o`, `--only NODE` | Filters displayed node type; total score is computed before this display filter | `--smell SMELL` selects detectors and can repeat | Separate check selection from report filtering. Do not interpret `--only` as both. |
| `-c`, `--config` | No core general configuration file option | YAML configuration file | Prefer explicit `--reek-config` if importing an upstream file. A unified configuration format needs a decision. |
| `-#` / `-n` | Disable duplication report numbering | Enable line numbers in current option implementation; `--no-line-numbers` disables | Keep numbering and source locations separate. Tagged Reek prose says `-n` suppresses numbers, contrary to implementation: verify source behavior with a fixture. |
| `-P`, `-V`, `-U` | No equivalent core aliases | Progress, empty headings, documentation links | Shared presentation controls must specify which finding types they affect. |
| `--sort-by` | Fixed score ordering | `smelliness` or `none` | Do not rank duplication mass against smell count. |
| `--success-exit-code`, `--failure-exit-code` | No equivalents | Configurable outcome statuses | Reject overrides that permit incomplete analysis to report success. |

Sources: [Flay options/defaults and report implementation](https://github.com/seattlerb/flay/blob/v2.14.4/lib/flay.rb) (`parse_options`, `default_options`, `report`), [Reek option implementation](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/cli/options.rb), [Reek command-line prose](https://github.com/troessner/reek/blob/v6.6.0/docs/Command-Line-Options.md).

For example, `fleek -f json lib` cannot preserve both tools: Flay expects a fuzzy-difference integer while Reek expects a format name. `fleek -v lib` cannot both analyze with progress and exit after printing a version. A combined mode therefore needs a deliberate CLI contract even when finding behavior stays compatible.

## Inputs, configuration, and analysis

| Area | Verified difference | Proposed resolution |
|---|---|---|
| Paths | Flay uses `path_expander`, including directories, `@argument-file`, subtractive paths, `.flayignore`, and plugin extensions. Reek traverses `.rb` files, prunes hidden directories, and applies `exclude_paths`; `--force-exclusion` changes exclusion of explicit paths. | Start with explicit Ruby paths and directories; document unsupported expansion features. Preserve analyzer-specific exclusions rather than silently applying their union to both analyzers. |
| Default input / stdin | Reek, with no paths, reads non-TTY stdin; otherwise it uses the current directory. `--stdin-filename` supplies origin for configuration. Flay's entry point expands filesystem arguments and its Ruby parser reads files with `File.binread`; no Reek-style stdin branch appears there. Flay's no-path policy belongs to its dependency and is not verified here. | Prefer explicit paths or explicit stdin selection for deterministic CI. Decide no-argument behavior separately. Never treat an empty CI pipe as a successful directory scan. |
| Configuration | Reek reads one YAML file: explicit path, nearest `.reek.yml` from working directory upward, then home. It has `detectors`, `directories`, `exclude_paths`, and per-scope suppression comments. Flay uses `.flayignore` and CLI analysis options; it does not have the same YAML detector model. | Import supported upstream settings with their own scope and precedence. Validate all enabled checks before analysis; identify unsupported checks and settings. A unified file must not accidentally broaden an exclusion. |
| Parser | Flay defaults to Prism's RubyParser translation and offers `--legacy` RubyParser. Reek uses `Parser::CurrentRuby`, a custom AST builder, comment association, and UTF-8 source handling. Its gem dependency is `parser ~> 3.3.0`; the executable requires Ruby >= 3.2. | Pin an analyzed Ruby syntax target independently of Spinel. Do not assume one AST can drive both analyzers unchanged. Prove adapters and source locations before claiming equivalent findings. |
| Other file types | Flay loads installed `flay_*.rb` plugins and lets them register options; bundled ERB and external formats are part of its ecosystem. Reek source discovery accepts `.rb`. | Ruby-only first scope is a deliberate limitation requiring agreement. Unsupported requested formats/plugins must fail explicitly, not vanish from a scan. |

Sources: [Flay entry point, plugins, file processing](https://github.com/seattlerb/flay/blob/v2.14.4/lib/flay.rb), [Flay path/plugin documentation](https://github.com/seattlerb/flay/blob/v2.14.4/README.rdoc), [Reek input dispatch](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/cli/application.rb), [Reek source discovery](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/source/source_locator.rb), [Reek configuration discovery](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/configuration/configuration_file_finder.rb), [Reek configuration and comments](https://github.com/troessner/reek/blob/v6.6.0/README.md), [Reek parser](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/source/source_code.rb), [Reek dependencies](https://github.com/troessner/reek/blob/v6.6.0/reek.gemspec).

## Reports and exit status

Flay reports groups spanning multiple locations, a mass/identical multiplier, and total/per-file scores. It sorts groups by descending score then source file, line, and node type; locations sort by file and line. Reek reports smell type, context, message, and potentially several lines for one finding; it has text, HTML, YAML, JSON, XML, and GitHub formats. Its file ordering can be processing order or descending smell count. Those metrics are not interchangeable. [Flay analysis/report/score source](https://github.com/seattlerb/flay/blob/v2.14.4/lib/flay.rb), [Reek report options](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/cli/options.rb), [Reek report command](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/cli/command/report_command.rb).

Proposal: one report with distinct duplication and smell sections first. Preserve upstream finding content, grouping, scores, and order inside each section. A machine format requires an explicit schema with finding kind, check identifier, locations, and type-specific data. Concatenating Flay text and Reek JSON produces invalid JSON; combined output cannot be byte-for-byte identical to both originals. Diagnostics and progress belong on stderr. Supporting every upstream output format is separate work.

Reek defines 0 for success, 1 for errors, and 2 for smells, with customizable success/finding codes. Its report command chooses status solely from `reporter.smells?`. Configuration/invalid-option failures explicitly exit 1, but missing paths merely warn in `SourceLocator`, and the logging handler warns on analysis exceptions. Error diagnostics therefore do not by themselves prove a failing status. Flay's CLI simply calls `Flay.run.report`; findings do not explicitly cause a nonzero status. Its processing catches parsing failures/timeouts, warns, and skips files. These are source-derived facts, not executed CLI receipts. [Reek statuses](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/cli/status.rb), [Reek application](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/cli/application.rb), [Reek logging](https://github.com/troessner/reek/blob/v6.6.0/lib/reek/logging_error_handler.rb), [Flay executable](https://github.com/seattlerb/flay/blob/v2.14.4/bin/flay), [Flay processing](https://github.com/seattlerb/flay/blob/v2.14.4/lib/flay.rb).

Proposal: **0 complete and no findings; 2 complete with findings; 1 invalid or incomplete analysis**, including unsupported enabled checks, missing requested sources, parser failure, and timeout. Errors take precedence over findings. This intentionally changes Flay's findings status and skipped-input behavior; record it as a compatibility exception rather than hiding it in normalization.

## Native runtime and reuse

Calling either original executable or loading arbitrary Ruby plugin gems would violate the accepted independent-native-runtime requirement. Flay depends on Prism, `sexp_processor`, `path_expander`, and Erubi; its diff feature requires Ruby2Ruby. Reek depends on Parser, `dry-schema`, Rainbow, REXML, and Logger. This establishes needed behavior, not approval to add dependencies. Native parser reuse, Spinel integration, YAML support, and AST adapters require feasibility proof. [Flay dependency declaration](https://github.com/seattlerb/flay/blob/v2.14.4/Rakefile), [Flay diff implementation](https://github.com/seattlerb/flay/blob/v2.14.4/lib/flay.rb), [Reek gemspec](https://github.com/troessner/reek/blob/v6.6.0/reek.gemspec).

Flay and Reek include MIT permission notices requiring copyright and permission notices in copies or substantial portions. Preserve these notices if reusing source or covered fixtures. Audit separately the exact parser/plugin code selected for reuse; upstream analyzer licenses do not determine dependency licenses. No parser source is selected by this note. [Flay license](https://github.com/seattlerb/flay/blob/v2.14.4/README.rdoc#license), [Reek license](https://github.com/troessner/reek/blob/v6.6.0/License.txt).

## Remaining decisions

1. Accept a new unambiguous CLI contract while retaining supported finding/configuration behavior?
2. Accept separate report sections and the proposed 0/2/1 status contract?
3. Choose reference releases, reference dependency locks, and analyzed Ruby syntax target.
4. Decide Ruby-only first scope, stdin/no-argument behavior, configuration import and exclusion precedence.
5. Prove one useful supported duplication check and one supported smell check end to end; measure cold CLI time on the identical selected source set only after correctness is established.
