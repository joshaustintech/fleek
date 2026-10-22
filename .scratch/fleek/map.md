# Fleek

## Notes

- Canonical project specification is `spec.md`; detailed slice specifications are linked from it.
- One local Markdown issue per ticket in `issues/`, numbered globally in dependency order.
- Category `enhancement`; triage state `ready-for-agent` until completion. `Status` tracks open/claimed/resolved workflow.
- Triage comments begin with the required AI disclaimer.
- Tickets 01–20 resolved and pushed. Tickets 15 and 17–20 record bounded runtime evidence and verified downloadable release evidence.
- Ticket 19 closes bounded class/module method parity for the first-release scope. The pinned 25-file comparison matches the supported Flay finding and Reek clean result while Flay remains explicitly incomplete; full Rails Flay parity is not claimed. ADR 0037 records the accepted boundary.
- Ticket 20 published v0.2.0 from the current bounded analyzer and verified the downloaded archive, sidecar, and extracted runtime. The v0.1.0 tag/assets remain immutable; see [issue 20](issues/20-release-current-bounded-cli.md), [ADR 0038](../../docs/adr/0038-release-current-bounded-analyzer.md), and the [v0.2.0 archive receipt](../../docs/research/native-archive-0.2.0.md).

## Decisions-so-far

- Ticket 81 matches DataClump participation across `class << self` and instance methods, retaining Reek's distinct counts for overlapping parameter groups. See [ADR 0218](../../docs/adr/0218-match-dataclump-singleton-participation.md).
- Ticket 82 counts TooManyConstants independently for a top-level module and its direct nested module. See [ADR 0219](../../docs/adr/0219-count-too-many-constants-per-nested-module.md).
- Ticket 83 counts TooManyInstanceVariables independently in two direct nested classes under one top-level class. See [ADR 0220](../../docs/adr/0220-count-too-many-instance-variables-per-nested-class.md).
- Ticket 84 counts TooManyMethods independently in one top-level class and its direct nested class, preserving findings beside unsupported syntax. See [ADR 0221](../../docs/adr/0221-count-too-many-methods-per-nested-class.md).
- Ticket 85 analyzes direct `class << self` method bodies for TooManyStatements and keeps findings when another method body is unsupported. See [ADR 0222](../../docs/adr/0222-count-too-many-statements-in-singleton-class.md).
- Ticket 86 matches UncommunicativeMethodName for singleton methods in one direct nested class, including configured accept/reject patterns. See [ADR 0223](../../docs/adr/0223-match-nested-singleton-method-names.md).
- Ticket 87 matches UncommunicativeModuleName for one-level qualified class/module names and applies patterns to the terminal constant; deeper qualified paths stay incomplete. See [ADR 0224](../../docs/adr/0224-match-qualified-module-name-paths.md).
- Ticket 88 confirms Reek 6.6.0 ignores block parameters for UncommunicativeParameterName, including configured patterns; Fleek keeps the selected source clean and complete. See [ADR 0225](../../docs/adr/0225-preserve-reek-block-parameter-boundary.md).
- Ticket 89 supports simple required block parameters and local assignments in direct methods for UncommunicativeVariableName, preserving method context and marking other block parameter shapes incomplete. See [ADR 0226](../../docs/adr/0226-match-uncommunicative-block-variable-names.md).
- Ticket 90 inventories all 29 pinned Reek detector defaults and bounded settings; custom `LongParameterList.overrides` remains an explicit gap in [issue 126](issues/126-reek-long-parameter-overrides.md), while directory precedence, suppression, and config validation remain in issues 91–93. See [ADR 0227](../../docs/adr/0227-inventory-pinned-reek-settings.md).
- Ticket 91 confirms discovered and explicit Reek configuration agree for parent/child `LongParameterList` thresholds, with the more-specific child override and default fallback matching Reek. See [ADR 0228](../../docs/adr/0228-verify-reek-directory-precedence.md).
- Ticket 93 confirms malformed YAML, unknown detector/setting, wrong scalar/list types, and non-integer thresholds fail before analysis in both Fleek and pinned Reek, preserving Fleek's normalized diagnostics. The bounded cases already passed; ADR 0230 records the native validation boundary.
- Ticket 94 verifies default/subset/opt-in and combined outcomes through existing public contracts. Exit 0 is complete clean, 2 complete findings, and 1 incomplete; findings survive beside unresolved work and Flay/Reek source accounting stays independent. See ADR 0231.
- Ticket 95 strengthens extension evidence: Reek acceptance/rejection is recorded before semantic comparison, original lines remain asserted, and a `require_relative` sentinel plus inert FFI/module-body markers prove analyzed source stays unloaded. See ADR 0019.
- Ticket 96 records all 29 pinned Reek detector results plus Flay on the exact Rails manifest. Incomplete source coverage stays incomplete, semantic deltas route to issues 97–101, and the opt-in framework-subclass crash is isolated in issue 127. See the [Rails census](../../docs/research/rails-reek-census-96.md) and [ADR 0232](../../docs/adr/0232-record-rails-detector-residuals.md).
- Ticket 120 adds explicit integer-second Flay timeouts through process isolation; expiry reports selected coverage incomplete, per-file continuation is tracked separately in [issue 128](issues/128-flay-per-file-timeout-continuation.md), and the untimed fast-path decision is in [ADR 0234](../../docs/adr/0234-keep-untimed-flay-runs-on-direct-path.md). See [ADR 0233](../../docs/adr/0233-isolate-flay-timeout-analysis.md).
- Issue 129's untimed Flay fast path and focused mutation routing return the full pinned gate to 351.44 seconds with all 335 mutants caught. Ticket 128's per-file timeout continuation is now complete; see [ADR 0234](../../docs/adr/0234-keep-untimed-flay-runs-on-direct-path.md), [ADR 0235](../../docs/adr/0235-focus-mapped-mutation-contracts.md), and [ADR 0236](../../docs/adr/0236-continue-flay-analysis-after-per-file-timeout.md).
- Issue 128 preserves completed Flay findings after another selected source times out; the combined Reek pass keeps its full input set. See [ADR 0236](../../docs/adr/0236-continue-flay-analysis-after-per-file-timeout.md).
- Ticket 121 keeps Flay presentation modes outside report v1 and verifies their stream effects against Flay 2.14.4. See [ADR 0237](../../docs/adr/0237-keep-flay-presentation-options-out-of-report-v1.md).
- Ticket 122 records inherited and reflective `UnusedPrivateMethod` call graphs as explicit incomplete coverage until Fleek can match pinned Reek behavior. See [ADR 0238](../../docs/adr/0238-keep-call-graph-residuals-incomplete.md).
- Ticket 123 keeps deep and wrapped `ClassVariable` namespaces incomplete until Fleek can preserve Reek's qualified scope attribution. See [ADR 0239](../../docs/adr/0239-keep-deep-class-variable-namespaces-incomplete.md).
- Ticket 124 keeps deeper and wrapped `Attribute` scopes incomplete until Fleek can preserve per-class visibility and scope ownership. See [ADR 0240](../../docs/adr/0240-keep-deep-attribute-scopes-incomplete.md).
- Ticket 125 keeps deeper and module-wrapped `InstanceVariableAssumption` scopes incomplete until Fleek can verify all nested initialization and exclusion contexts. See [ADR 0241](../../docs/adr/0241-keep-deep-instance-variable-assumption-incomplete.md).
- Ticket 126 supports the pinned `LongParameterList.overrides.initialize.max_params` threshold with context-specific precedence and keeps unsupported override shapes as configuration errors. See [ADR 0242](../../docs/adr/0242-support-initializer-parameter-threshold-override.md).
- Ticket 127 treats a null class body as an empty supported scope in `UnusedPrivateMethod`, preventing the framework-subclass crash while keeping unsupported non-null shapes incomplete. See [ADR 0243](../../docs/adr/0243-handle-empty-class-in-unused-private-method.md).
- Ticket 132 supports direct constant and constant-path `include` declarations for Rails Flay analysis; the pinned `ApplicationController` is complete alone, while the 25-file gate stays explicitly incomplete. See [issue 132](issues/132-rails-flay-include-declarations.md) and [ADR 0246](../../docs/adr/0246-bound-rails-flay-include-declarations.md).
- Ticket 133 models empty class method bodies in class candidates without method-level groups; paired class-group mass and locations match Flay. See [issue 133](issues/133-rails-flay-empty-method-bodies.md) and [ADR 0247](../../docs/adr/0247-bound-rails-flay-empty-method-bodies.md).
- Ticket 134 accepts only the pinned Rails `primary_abstract_class` no-argument declaration; other macros remain partial. See [issue 134](issues/134-rails-flay-primary-abstract-class.md) and [ADR 0248](../../docs/adr/0248-bound-rails-flay-primary-abstract-class.md).
- Ticket 135 is the next issue 97 child: accept only the pinned `ApplicationMailer`'s direct `default from: <string>` and `layout <string>` calls. See [issue 135](issues/135-rails-flay-mailer-declarations.md) and [ADR 0249](../../docs/adr/0249-bound-rails-flay-mailer-declarations.md).
- Ticket 80 extends FeatureEnvy receiver counting through one supported method block; multiple blocks stay incomplete. See [ADR 0217](../../docs/adr/0217-analyze-feature-envy-inside-one-block.md).
- Ticket 79 confirms configured ignored iterator names reduce NestedIterators depth; three-level chain at line 5 becomes depth two when `map` is ignored. See [ADR 0216](../../docs/adr/0216-verify-nested-iterator-ignore-depth.md).
- Ticket 78 analyzes RepeatedConditional separately in each direct top-level class; thresholds and findings stay class-local. See [ADR 0215](../../docs/adr/0215-isolate-repeated-conditional-class-scopes.md).
- Ticket 77 matches MissingSafeMethod singleton scope: `class << self` bang methods require a companion in the same singleton body; instance companions do not count. See [ADR 0214](../../docs/adr/0214-match-singleton-missing-safe-method.md).
- Ticket 53 enables default distance-one Flay fuzzy matching for bounded method candidates, preserving default output without `--fuzzy` and enforcing Flay's 10-element and average-mass limits. See [issue 53](issues/53-fuzzy-default-distance.md) and [ADR 0191](../../docs/adr/0191-match-bounded-flay-fuzzy-method-candidates.md).
- Ticket 54 extends bounded fuzzy matching to explicit Flay distances, optional/repeated-value parsing, and zero/negative validation. See [issue 54](issues/54-fuzzy-distance-controls.md) and [ADR 0192](../../docs/adr/0192-match-explicit-flay-fuzzy-distance.md).
- Ticket 55 accepts Flay legacy mode on shared syntax, records the RubyParser 3.22.0 reference dependency, and fails incomplete for tested line-leading `&&`, `||`, `and`, and `or` parser mismatches. See [issue 55](issues/55-legacy-parser-semantics.md) and [ADR 0193](../../docs/adr/0193-bound-flay-legacy-parser-mode.md).
- Ticket 56 matches pinned PathExpander `.flayignore` path selection and fails on an existing unreadable ignore path. See [issue 56](issues/56-flayignore-pattern-semantics.md) and [ADR 0194](../../docs/adr/0194-match-flayignore-path-expansion.md).
- Ticket 58 matches repeated `--mass` precedence and fuzzy-plus-liberal source routing. Timeout behavior is resolved by issues 120 and 128; presentation flags remain deliberately unsupported by Fleek report v1, as verified in issue 121. See [ADR 0196](../../docs/adr/0196-flay-control-precedence-and-boundaries.md), [ADR 0236](../../docs/adr/0236-continue-flay-analysis-after-per-file-timeout.md), and [ADR 0237](../../docs/adr/0237-keep-flay-presentation-options-out-of-report-v1.md).
- Ticket 59 reconciles the pinned Flay control and path inventory with evidence from tickets 10 and 53–58, 120, 121, and 128. Explicit timeout behavior is complete; `-#` is an unnumbered-report no-op while summary, diff, and verbose stay outside report v1. ERB remains outside spec 03. Parent ticket 23 is resolved. See [issue 59](issues/59-close-flay-controls-evidence.md).
- Ticket 60 supports bounded `UnusedPrivateMethod` analysis for direct methods in one simple class, preserves its opt-in default and configured precedence, and reports unsupported call-graph shapes incomplete. See [ADR 0197](../../docs/adr/0197-bound-unused-private-method-analysis.md).
- Ticket 61 matches named visibility (`private :name`), public visibility reopening, and calls between private methods while preserving opt-in selection and configured enable/disable behavior. See [ADR 0198](../../docs/adr/0198-match-named-private-visibility.md).
- Ticket 61's inherited and reflective/dynamic call residual is tracked separately as [issue 122](issues/122-unused-private-method-call-graph-residuals.md); pinned Reek's detector uses context call names and `to_call` names, so each case needs measured public-contract evidence before implementation.
- Ticket 62 supports a direct class inside two nested modules, matches qualified context and grouped source lines, and applies nested-context exclusion. Deeper and wrapped declarations remain incomplete. See [ADR 0199](../../docs/adr/0199-match-nested-class-variable-context.md).
- Three-level and wrapped ClassVariable namespace residuals are tracked in [issue 123](issues/123-class-variable-deeper-and-wrapped-namespaces.md), parent 24; ticket 62 leaves them incomplete pending pinned Reek evidence.
- Ticket 63 supports direct nested class Attribute findings with per-class visibility and fully qualified exclusions. Deeper and wrapped class scopes remain in [issue 124](issues/124-attribute-deeper-and-wrapped-class-scopes.md). See [ADR 0200](../../docs/adr/0200-match-direct-nested-attribute-scope.md).
- Ticket 64 supports `InstanceVariableAssumption` in one direct nested class, keeps each class's initializer analysis separate, and applies exclusions to the qualified context. Deeper and wrapped class scopes are tracked in [issue 125](issues/125-instance-variable-assumption-deeper-and-wrapped-scopes.md). See [ADR 0201](../../docs/adr/0201-match-direct-nested-instance-variable-assumption.md).
- Ticket 65 supports direct `Class.new` assignments with one constant superclass argument, reports core-class inheritance at the assignment line, and keeps dynamic or mixed-scope construction incomplete. See [ADR 0202](../../docs/adr/0202-match-class-new-core-subclass-assumptions.md).
- Ticket 66 supports `ModuleInitialize` in one direct nested module, preserving its qualified context and declaration line; deeper or mixed module trees remain incomplete. See [ADR 0203](../../docs/adr/0203-match-nested-module-initialize-context.md).
- Ticket 67 supports `IrresponsibleModule` comment checks for one direct `Class.new` constant assignment, honors the assigned name for comment and exclusion context, and keeps dynamic forms incomplete. See [ADR 0204](../../docs/adr/0204-bound-irresponsible-module-class-new.md).
- Ticket 68 matches `LongParameterList` for methods whose bodies contain blocks, counting the enclosing method signature and leaving callback block parameters out of scope. Default and configured thresholds match Reek. See [ADR 0205](../../docs/adr/0205-match-long-parameter-list-around-block-bodies.md).
- Ticket 69 records `BooleanParameter` parity for singleton positional boolean defaults, a nonboolean control, and explicit detector disablement. Existing native behavior already matched Reek; no analyzer code change was needed. See [ADR 0206](../../docs/adr/0206-record-singleton-boolean-parameter-parity.md).
- Ticket 70 records nested-block `LongYieldList` parity at the default and configured thresholds. Existing traversal already matched Reek; the new contract protects the nested context and yield lines. See [ADR 0207](../../docs/adr/0207-record-nested-long-yield-parity.md).
- Ticket 71 supports `ControlParameter` conditionals inside one iterator block, records exact condition lines, and suppresses findings when the parameter is also used as data. Other block shapes remain incomplete. See [ADR 0208](../../docs/adr/0208-match-control-parameter-inside-one-iterator-block.md).
- Ticket 72 matches Reek's name-based `UnusedParameters` use detection through one iterator block, including same-name block parameters and captured method parameters. Multiple-block and unsupported bodies remain incomplete. See [ADR 0209](../../docs/adr/0209-match-unused-parameters-block-local-uses.md).
- Ticket 73 matches `UtilityFunction` visibility for default, `public_methods_only: true`, and explicit false with one public and one private stateless method. Unsupported class-body statements remain incomplete for the public-only setting. See [ADR 0210](../../docs/adr/0210-match-utility-function-public-method-setting.md).
- Ticket 74 records nested-branch `DuplicateMethodCall` parity and `allow_calls` behavior. Existing traversal matched Reek; compiled-CLI regression evidence protects exact lines and distinct-argument grouping. See [ADR 0211](../../docs/adr/0211-record-nested-duplicate-method-call-parity.md).
- Ticket 75 records nested-branch `ManualDispatch` parity and method-context exclusion. Existing traversal matched Reek; compiled-CLI evidence protects the guard location and unguarded clean control. See [ADR 0212](../../docs/adr/0212-record-nested-manual-dispatch-parity.md).
- Ticket 76 supports `NilCheck` occurrences inside one block, preserving exact lines and leaving safe navigation clean. Multiple-block methods remain incomplete. See [ADR 0213](../../docs/adr/0213-match-nil-check-inside-one-block.md).
- Ticket 52 completed the accepted-descriptor and adapter audit; ticket 119 moved Range/regexp value identity into the node descriptor and passed the full gate and both review axes. With generated/composed evidence from tickets 42, 43, and 118, parent ticket 22 is resolved. See [ADR 0190](../../docs/adr/0190-describe-range-and-regexp-identity.md).

- Ticket 51 matches Flay's composed begin/rescue/ensure pruning across source paths: top-level candidates select `:ensure`, class candidates retain method groups, reversed file inputs keep canonical location order, and supported groups survive beside an unsupported sibling with incomplete coverage. See [ADR 0189](../../docs/adr/0189-preserve-composed-cross-file-pruning.md); ticket 119 and parent 22 are resolved.
- Ticket 50 corrects method mass for bounded composed begin/rescue/ensure nodes with interpolated regexp/string values while preserving incomplete findings beside unsupported defaults. See [ADR 0188](../../docs/adr/0188-match-composed-exception-wrapper-mass.md); ticket 119 and parent 22 are resolved.
- Ticket 49 adds pinned composition evidence without changing the native analyzer: multi-condition case/array mass 38, loop with array/hash mass 30, identical conditional collection mass/score 26/52, and clean different-topology boundary. See [ADR 0187](../../docs/adr/0187-preserve-composed-collection-control-parity.md); ticket 119 and parent 22 are resolved.
- Ticket 43 composes parameter-shape selection with method candidate groups: differing optional defaults select independently grouped `:iter` subtrees across method candidates, including subset matches and multiple groups per method; identical parameter shapes retain `:defn`. See [ADR 0186](../../docs/adr/0186-group-composed-methods-by-flay-subtree.md).

- Ticket 118 preserves Flay's nested `:iter` group for matching parameterized blocks when composed method parameter values differ, while identical signatures retain the enclosing-method choice. Generated contracts compare both shapes against Flay and catch a focused group-selection mutation; the cold full gate passes. See [ticket 118](issues/118-composed-block-subtree-selection.md) and [ADR 0185](../../docs/adr/0185-select-nested-block-group-for-renamed-composed-methods.md).
- Ticket 48 composes optional method parameters with nested optional block parameters by subtracting the wrapper point Flay does not count in this combination. The identical case matches mass/score 44/88 and the arity boundary matches Flay's clean result. Similar renamed/default methods expose a separate nested-group selection mismatch tracked in [ticket 118](issues/118-composed-block-subtree-selection.md); parent ticket 43 remains open. See [ADR 0184](../../docs/adr/0184-compose-optional-method-and-block-mass.md).
- Issue 107 fixes runner head-of-line blocking: reap any child, attribute result by PID, then clean that worker's isolated roots. The gated test covers fast-success and fast-failure ordering while slow worker remains alive. Full check passes; see [ADR 0173](../../docs/adr/0173-reap-any-completed-check-worker.md). Ticket 108 is next; ticket 115 remains the post-change correctness handoff.
- Issue 108 passes the runner's resolved CPU-bounded `JOBS` value to shared mutation-contract precompile, while preserving the selected-contract cap, isolated temp roots, and `-O 1`. Full check passed in 398.63s with zero Flay/Reek findings. See [ADR 0174](../../docs/adr/0174-use-resolved-budget-for-contract-precompile.md). Ticket 109 is next; ticket 115 remains the post-change correctness handoff.
- Issue 109 stages the current working tree while excluding `.git`, `dist`, and generated mutation/cache outputs. The worker contract preserves dirty/untracked inputs, hidden hooks/config, and `build/fleek`; the same staging probe fell from 10.80 MB/0.36s to 5.56 MB/0.26s. See [ADR 0175](../../docs/adr/0175-stage-only-worker-inputs.md). Ticket 110 is next; ticket 115 remains the post-change correctness handoff.
- Issue 110 introduced digest-verified caching for the native-parser leaf mutation contract; see [ADR 0176](../../docs/adr/0176-cache-the-native-parser-contract.md).
- Issue 111 added the call-descriptor dependency closure and rewrite-format invalidation; see [ADR 0177](../../docs/adr/0177-cache-dependent-call-descriptor-contract.md).
- Issue 112 enables persistent reuse for all mapped mutation contracts by default, with an explicit cold-run switch. Full cold and warm checks caught identical mutation inventories; see [ADR 0178](../../docs/adr/0178-default-mapped-mutation-contract-cache.md). Ticket 113 is next; ticket 115 remains the post-change correctness handoff.
- Issue 113 maps only `Flay group ordering` to the focused mixed-group report contract, retaining the broad duplication contract in normal tests. Warm focused time fell 49% with the same precompile cost; see [ADR 0179](../../docs/adr/0179-focus-group-order-mutation-contract.md). Ticket 114 is next; ticket 115 remains the post-change correctness handoff.
- Issue 114 maps only `Flay generated descriptor support` to the existing focused range contract; the broad generated-descriptor inventory remains in ordinary tests. Direct execution fell from 10.28s to 1.13s; see [ADR 0180](../../docs/adr/0180-focus-generated-descriptor-support-contract.md). Ticket 115 is next, the post-change correctness handoff.
- Ticket 115's standards/spec review found two residual harness gaps. Ticket 116 now deterministically covers runner-resolved mutation budgets at the CheckRunner process boundary; fault injection proved missing forwarding is caught. Ticket 117 removes the global cache temp counter, with a regression for duplicate paths across cache instances. See [ADR 0181](../../docs/adr/0181-contract-runner-budget-resolution.md) and [ADR 0182](../../docs/adr/0182-instance-owned-cache-temporary-paths.md). Both blockers are resolved; ticket 115 can finish its handoff checks.
- Ticket 115 closes the harness chain: cache-disabled full check fell from 452.93s to 402.49s at JOBS=4, all 273 mutation labels remain caught, and focused medians plus warm results are recorded without promising total savings. Standards/spec blockers 116–117 were fixed and verified; feature work resumes at ticket 48, with README completion still last. See [ADR 0183](../../docs/adr/0183-harness-savings-and-correctness-handoff.md).
- Issue 106 measured the full harness baseline and focused mutation costs before optimization. ADR 0172 ranks worker-slot waiting, serial shared-contract precompile, and repeated contract compilation; staging was 0.32s for 10.6 MB and did not rank as a leading cost. Full-gate findings and limitations are recorded in [ADR 0172](../../docs/adr/0172-measure-harness-costs.md). Ticket 107 resolves first ranked cause; ticket 108 is next. Ticket 115 remains the post-change correctness handoff.

- Retro follow-ups are tracked as [issue 44: validate local ticket documents](issues/44-validate-local-ticket-documents.md) and [issue 45: honor prior authorization in ticket breakdowns](issues/45-honor-autonomous-ticket-authorization.md). Both are resolved.
- Issue 44 adds `make ticket-check` and runs its malformed-document contract in the main gate. All 54 local tickets pass. ADR 0164 records optional blocker and cross-feature reference rules.
- Issue 45 makes ticket publication authorization-aware and aligns its local template with the canonical tracker contract. ADR 0165 records the policy.
- Ticket 38 closes collection descriptors against Flay 2.14.4, with focused mutation checks. ADRs 0104, 0105, 0145, and 0166 record the node mappings and representation adjustments.
- Issue 46 narrows collection mutation contracts: the same array mutant now runs in 12.65s instead of 29.57s. ADR 0166 records the focused mapping.
- Ticket 39 verifies Flay control-flow parity through focused branch/case, loop, and exception-flow contracts. ADR 0167 records the native Prism descriptors and `when` wrapper boundary.
- Ticket 40 verifies range endpoint flags, mass, and static/interpolated regexp semantics through focused contracts. ADR 0168 records their shared descriptors and the absence of wrapper adapters.
- Ticket 41 describes method and block parameter support, identity, default, mass, and optional-count rules through a shared Prism-indexed descriptor table. Focused Flay contracts and 42 caught parameter mutations protect the rules; ADR 0169 records the preserved boundaries.
- Ticket 42 generates one bounded Flay 2.14.4 parity case per supported method-body and parameter descriptor, checking each group’s kind, mass, score, exact location order, and coverage. The inventory check makes missing/stale cases fail; focused support/mass mutations are caught. Multi-group report ordering remains covered by the existing `Flay group ordering` contract. See [ADR 0170](../../docs/adr/0170-generated-flay-descriptor-contracts.md).
- Issue 47 bounds generated analyzer fan-out at two inside isolated check workers and routes the optional-keyword-count mutant to its focused contract. Timings and full-gate evidence are recorded in [ADR 0171](../../docs/adr/0171-bound-generated-contract-work.md).

- Approved default-check behavior effort: [spec](../fleek-default-checks/spec.md), [tickets](../fleek-default-checks/issues/), and [ADR 0039](../../docs/adr/0039-default-checks-and-implicit-source-scope.md).
- Full native analyzer parity is now the implementation goal in [spec 04](specs/04-language-and-project-parity.md); issues 21–24 cover Flay candidate scopes, method/expression semantics, analysis controls, and the final shared-syntax gate. Existing default-check tickets remain the default-selection work; ADR 0037 remains historical first-release scope.
- Ticket 21 replaces arbitrary scope-depth/capacity limits with dynamically sized typed paths and iterative traversal of straight class/module chains. Public contracts match generated 64-level module/class chains, the former 21-component qualified namespace boundary, wrapped sibling-class scopes, and class/module compound scopes against Flay 2.14.4. Fixed fixtures remain for distinct semantics; more compound shapes remain under discovery. See [ADR 0097](../../docs/adr/0097-dynamic-nested-scope-storage.md), [ADR 0098](../../docs/adr/0098-nested-class-sibling-candidate-scopes.md), and [ADR 0100](../../docs/adr/0100-typed-flay-scope-paths.md); depth-specific ADRs are historical.
- Mutation checks cache immutable Flay reference results only within each disposable shard; every Fleek mutant and its full mapped CLI contract still run. See [ADR 0094](../../docs/adr/0094-cache-flay-references-during-mutation.md) for scope and measured contract-level speedup.
- Mutation contracts compile at Spinel `-O 1` after timing proved default optimization spent 23.13 s compiling the large duplication contract versus 5.86 s at `-O 1`, with both contracts passing. Track the confirmed bottleneck under [issue 26](issues/26-mutation-contract-compilation-cost.md); see [ADR 0096](../../docs/adr/0096-mutation-contract-optimization-level.md).
- Mutation harness issues 30 and 31 are resolved. Issue 31 localized the full-load `ENOENT` to cache status writes. Keeping cache paths and status text in locals fixed the observed symptom; temporary lifetime across Spinel native `File` calls is a plausible cause, not confirmed runtime behavior. Two consecutive `make check JOBS=8` runs passed all 33 workers and mutations, Flay 0, Reek 0 (290.42s and 284.45s). See [ADR 0094](../../docs/adr/0094-cache-flay-references-during-mutation.md) and [ADR 0112](../../docs/adr/0112-isolate-duplication-contract-output-files.md).
- Issue 28 removes 13 redundant qualified-path depth fixtures after timing a 42.20 s duplication contract; the retained 21-component boundary and generated 64-level chains passed in 29.41 s. See [ADR 0101](../../docs/adr/0101-prune-redundant-depth-contracts.md).
- Mutation contract compilation is shared once per run using bounded parallel Spinel batches. Runtime temp roots preserve parallel isolated contract execution. Issue 27 and ADR 0099 record the measured 44.3% full-gate improvement and all 183 caught mutations.
- Current pinned mutation benchmarks confirm 8 workers outperform 4 (171.04 s vs 240.94 s) on this 8-CPU host; a 16-worker request is capped at 8. See ADR 0103 and issue 27.
- Ticket 21 added typed dynamic scope paths so mixed nested class/module candidates retain their structural identity; paired fixtures cover module scopes inside sibling classes and reject mixed-kind class groups. See ADR 0100.
- Ticket 21 preserves verified class groups from supported sibling classes when an unsupported module or class body is also present; output remains incomplete. Paired Flay contracts and focused mutations cover these boundaries. See [ADR 0102](../../docs/adr/0102-preserve-class-groups-beside-unsupported-siblings.md).
- Ticket 22 adds array and keyword-hash literals to bounded class-method candidates; compiled CLI and Flay 2.14.4 match mass/score 40 (lines 1/7) and 62 (lines 1/8). Focused mutations cover expression acceptance and association mass. See [ADR 0104](../../docs/adr/0104-support-array-expression-method-candidates.md) and [ADR 0105](../../docs/adr/0105-support-hash-expression-method-candidates.md).
- Ticket 22 routes top-level methods through the same bounded AST candidate tree and positional-parameter rules as class methods. Calls with arguments match Flay at mass/score 16, required parameters at 14, differing required arities at 12, optional parameters with differing defaults at 52, if/else control flow at 62, local writes/identity at mass 38/16, boolean OR/AND at 34 each, conditional returns at 44, and identical array/hash expressions at mass/score 38/76 and 60/120; Ruby 4 logical-and contracts compare operand and position variants against Flay. Focused mutations independently remove boolean AND and OR support. See [ADR 0110](../../docs/adr/0110-share-method-ast-candidates.md).
- Ticket 22 adds `case`/`when` candidate support and preserves Flay's synthetic array wrapper for each `when` condition list in structural equality and mass. The compiled CLI matches a multiple-condition fixture against Flay 2.14.4 at mass/score 34 and matches its clean result for differing condition-list lengths; focused mutations cover CASE, WHEN, and wrapper mass. See [ADR 0111](../../docs/adr/0111-preserve-flay-case-condition-mass.md).
- Ticket 22 replaces fixed 128-node/256-marker method candidate arrays and the 128-statement traversal cutoff with per-candidate geometric storage. A generated 300-expression method pair now matches Flay's group mass, locations, and complete status; mutations prove both storage growth paths matter. See [ADR 0113](../../docs/adr/0113-dynamic-method-candidate-storage.md).
- Ticket 22 supports method blocks with required block parameters. A same-name method pair whose block parameter names differ matches Flay 2.14.4 as similar at mass/score 16; focused mutations cover candidate traversal, mass normalization, and parameter identity. See [ADR 0114](../../docs/adr/0114-match-block-expression-candidates.md).
- Ticket 22 shares the optional-default support rule across positional and keyword parameters, including bare receiverless calls. Flay parity contract and focused mutation pass; see [ADR 0158](../../docs/adr/0158-share-optional-default-policy.md).
- Ticket 22 now indexes every accepted method-body Prism node by type for candidate support and unconditional Flay mass. Variable reads, writes, targets, and compound assignments also use descriptor-driven name/operator identity. Differential contracts and focused mutations protect the shared paths; parent-dependent mass and other node identity still use adapters. This remains a partial migration under [ADR 0160](../../docs/adr/0160-data-driven-flay-method-translation.md).
- Ticket 36 indexes scalar identity with the node descriptors and compares integer, float, string, symbol, constant-read, and constant-path values through one comparator; booleans and nil use Prism node type. Compiled CLI cases match Flay 2.14.4, including differing float literals and constant-path parents; six focused mutations protect descriptor families. See [ADR 0162](../../docs/adr/0162-index-scalar-identity-in-descriptors.md).
- Ticket 37 describes call identity and children through shared descriptors, matches receiver/name/argument/splat/block cases against Flay 2.14.4, and leaves forwarding calls explicitly incomplete. Parameterless and parameterized block mass follow their distinct Flay adjustments. See [ADR 0163](../../docs/adr/0163-index-call-identity-and-block-mass.md).
- Ticket 22's translator work was split into [36 scalar identity](issues/36-flay-scalar-value-descriptors.md), [37 calls](issues/37-flay-call-descriptors.md), [38 collections](issues/38-flay-collection-descriptors.md), [39 control flow](issues/39-flay-control-flow-descriptors.md), [40 ranges and regular expressions](issues/40-flay-range-regexp-descriptors.md), [41 parameters](issues/41-flay-parameter-descriptors.md), [42 generated descriptor contracts](issues/42-generated-flay-descriptor-contract.md), and [43 composed parity](issues/43-composed-flay-method-parity.md). Those children, plus tickets 52, 118, and 119, now prove Ticket 22's acceptance boundary.
- Ticket 22 supports one integer argument in receiverless optional positional call defaults. The compiled CLI matches Flay 2.14.4 at mass/score 12; focused mutations protect acceptance, argument identity, mass, and the optional-keyword boundary. See [ADR 0161](../../docs/adr/0161-positional-call-default-arguments.md).
- Ticket 22 now supports top-level method `for` loops, named rest parameters, and required keyword parameters. Shared compiled-CLI contracts compare Flay kind, mass, score, locations, and coverage; focused mutations protect candidate acceptance and parameter identity/mass. The nested-scope generator builds any requested depth with `levels.times`; generated 64-level module and class scans exercise it. See ADRs 0127–0129.
- Focused mutation selection now launches at most one worker per selected unique mutation label; the prior empty-worker and checkout-copy cost dropped a one-label run from 32.30 s to 10.14 s. The full mutation suite remains the release gate. `.agents/skills/performance-bugs/SKILL.md` tracks future slow checks as bug issues and requires measured deterministic profiling; see [issue 32](issues/32-focused-mutation-execution-cost.md) and [ADR 0126](../../docs/adr/0126-focused-mutation-worker-count.md).
- Ticket 23 rejects `--mass` on Reek-only and `--reek-config` on Flay-only CLI selections before analysis. Compiled CLI contracts require empty stdout; focused mutants protect both boundaries. See [ADR 0106](../../docs/adr/0106-reject-check-inapplicable-options.md).
- Ticket 23 matches Flay `--liberal` pruning on mixed direct-method and sibling-class candidates, routes the flag away from Reek, and retains conservative behavior by default. Pinned CLI parity and focused mutations protect both modes; see [ADR 0109](../../docs/adr/0109-flay-liberal-pruning.md).
- Native combined Flay/Reek replacement; pinned Spinel compiler; Ruby 4.0 and pinned Spinel source input; standalone macOS arm64 release.
- Primary test seam: compiled CLI process. Parser feasibility uses a temporary real native probe.
- Ticket sequence and dependencies in issue bodies; summary: 01 compiler/reference harness → 02 parser → 03–08 smell/input/config/text → 09–12 duplication/combined report → 13–14 language/Rails parity → 18–19 Rails coverage → 15–17 runtime/release.
- Research notes and ADRs link from `spec.md` and project documentation.
- Ticket 17 verifies GitHub release `v0.1.0` and its retrieved arm64 archive; see [issue 17](issues/17-downloadable-release-verification.md), [ADR 0034](../../docs/adr/0034-publish-bounded-native-first-release.md), and the [release receipt](../../docs/research/native-archive-0.1.0.md). ADR 0037 accepts the explicitly incomplete Rails Flay result within first-release scope; no full-parity claim is made.
- Ticket 19 adds bounded literal-default optional positional parameters with Flay-matched mass and similarity; see [ADR 0035](../../docs/adr/0035-literal-optional-parameter-defaults.md). The pinned 25-file corpus remains incomplete.
- Ticket 19 also analyzes bounded direct methods in one simple module scope; see [ADR 0036](../../docs/adr/0036-direct-module-method-candidates.md). Rails helper coverage still has unsupported bodies and defaults.
- Ticket 20 closes the current-release synchronization gap: v0.2.0 is published and its downloaded archive and extracted CLI are verified; see [issue 20](issues/20-release-current-bounded-cli.md), [ADR 0038](../../docs/adr/0038-release-current-bounded-analyzer.md), and the [archive receipt](../../docs/research/native-archive-0.2.0.md).
- Ticket 07 imports a bounded Reek YAML subset without a YAML library; see ADR 0013 for supported keys and deliberate no-analysis exit differences.
- Ticket 08 defines stable text report v1 and explicit coverage/status fields; see ADR 0014 for layout, escaping, stream, and unsupported-format behavior.
- Ticket 09 adds bounded, separately selectable default Flay structural groups; see ADR 0016. Threshold boundaries and combined reporting remain tickets 10 and 12.
- Ticket 10 supports validated `--mass MASS`, and ticket 11 adds deterministic two-method cross-file groups and partial-input status; see ADR 0017 for the shared grammar, pruning boundary, and per-file score allocation.
- Ticket 12 combines explicitly selected Flay and Reek checks with independent exclusions and one incomplete/finding/complete outcome; see ADR 0018 for syntax boundaries, equivalent-reference parity, and deliberate exit-status normalization.
- Ticket 13 proves bounded Ruby 4 and pinned Spinel analysis, inert source processing, and reference-backed Flay extension parity; see ADR 0019 for the supported integer-`&&`/`ffi_func` shapes and separate Flay node-mass/group-score reporting.
- Ticket 14 pins the real Rails corpus and records exact initial parity; see ADR 0020. Ticket 18 closes namespaced ClassVariable parity (ADR 0021). Ticket 19 closes bounded Flay method analysis with the incomplete-corpus boundary recorded in ADR 0037.
- Ticket 19 supports bounded method candidates across simple class declarations and one simple module. Structural fingerprints retain tree nesting; unsupported partial-subtree matches fail incomplete. Contracts cover topology, partial subtrees, Rails-shaped findings, and identical methods against pinned Flay. Class-level statements and the actual 25-file Rails run remain incomplete; ADR 0037 accepts that truthful boundary for first release without a full-parity claim.
- ADRs 0024–0025 extend bounded candidate collection across simple class declarations and one-level namespace wrappers. Cross-class `:class` rejection now requires fully modeled equal-sized class bodies; unsupported callbacks retain verified `:defn` findings with incomplete status. Empty classes/modules are clean inputs, and the empty-module null-body crash is regression-tested. The pinned 25-file run reports Flay's score-48 `UsersController:51,58` group, but all sources remain partial due unsupported Rails syntax; ADR 0037 accepts this boundary for first release and forbids a full-parity claim.
- ADR 0026 supports class methods with up to eight required positional parameters and local-variable reads. Flay 2.14.4 fixture comparisons match score-48 groups across same and different arities and keep differing parameter names classified as similar; optional/rest/keyword/block parameters remain partial. The exact 25-file manifest still reports all sources partial and exits incomplete.
- ADR 0027 supports bounded `if`/`else` branches in class methods, raises combined candidate cap to 24, and preserves independent method findings alongside possible cross-class `:class` groups. Flay 2.14.4 and Fleek match mass/score 62 with ordered lines; the pinned corpus retains its score-48 controller group but remains incomplete.
- ADR 0028 adds bounded `unless` branch support in class methods, with Flay 2.14.4 parity at mass/score 62 and ordered lines. Class-level DSL calls and other unsupported Rails forms still prevent complete 25-file coverage.
- ADR 0029 adds bounded conditional `return false` support in class methods, with Flay parity at mass/score 44 and lines 2/10. ADR 0037 records the later decision that complete manifest Flay analysis is outside the accepted first-release scope.
- Post-ADR 0029 corpus receipt: Flay matches score 48 at `UsersController:51,58`; Fleek still correctly reports incomplete because all 25 Flay sources remain partial. Reek remains complete and clean.
- ADR 0030 adds local-variable assignments in class methods and preserves Flay's similar-versus-identical distinction when assigned names differ. Compound writes and class-level Rails declarations remain unsupported; full 25-file Flay coverage remains incomplete by the accepted first-release scope in ADR 0037.
- Latest pinned 25-file run: Flay reference still score 48 at `UsersController:51,58`; Reek reference clean. Fleek Reek covers 25/25, Flay covers 0/25 and exits incomplete. See current receipt in `docs/research/rails-project-parity.md`.
- ADR 0033 records ticket 15's bounded performance workaround, fresh-process cache definition, equivalent workload checks, and evidence-derived p95 targets. Reek timing uses all 25 pinned Rails Ruby files; Flay/combined timing uses a fully analyzed duplicated class-method fixture because Rails Flay coverage remains partial.

## Fog

- Native analyzer coverage starts with tickets 03–04's bounded ClassVariable slice; broader parity remains open.
- Flay/Reek repository/tag identity and locked Ruby are established; future output-parity evidence remains open.
- Ticket 02 proved only its named Ruby 4 newline-`&&` form and Spinel FFI declaration syntax; ticket 13 adds bounded ClassVariable/Flay behavior and reference parity, while broader grammar remains open.
- Real Rails corpus is pinned by ticket 14. Ticket 18 makes ClassVariable complete on all 25 Ruby files; Flay remains visibly partial on all 25 under the bounded first-release scope recorded in ADR 0037. The native archive, bounded runtime evidence, and external v0.2.0 release are verified; Developer ID signing and notarization remain out of scope. See the [archive receipt](../../docs/research/native-archive-0.2.0.md).

## Ticket 01 receipt

- Spinel 2026.09.12 resolves from tag object `00ce35bb96e489620358ffbc48791001a73778a5` to source `112bae85c1a25fc5399009a849f805bfe691426b`; Prism 1.9.0 artifact SHA-256 and executable receipt are in `docs/agents/spinel.md`.
- Reference runtime Ruby 3.4.9 arm64-darwin23; Flay 2.14.4 commit `1ec4d87f2209a3ae216aece69a4ecc8b688cd459`; Reek 6.6.0 commit `e0048db109ea13630630bf130492025cd1c786a5`; exact gems and transitive checksums in `Gemfile.lock`.
- `SPINEL=/path/to/pinned-spinel/bin/spinel make test` passed. `make mutation` caught the no-argument exit-status mutant and restored the passing build.
- `BUNDLE_PATH=/private/tmp/fleek-bundle make reference flay reek`: fixture Flay score 0; fixture Reek warnings 0; project Flay score 0; project Reek warnings 0.
- An initial manual mutation changed the no-argument return from 1 to 0; the CLI contract failed on `empty invocation status`, then passed after restore.
- Pinned Spinel `make check` passed: 3,596 tests, zero failures/errors; alloc-report, inference, and spin-e2e passed. Use Homebrew GNU Make 4.4.1 and mise Ruby 3.4.9 on PATH for its packaging and CRuby parity checks.
- Both code-review axes passed after resolving ticket metadata, accurate help text, compiler/Prism identity enforcement, and executable verifier root configuration.

## Ticket 02 receipt

- Native Prism 1.9.0 adapter compiled with pinned Spinel and selected `PM_OPTIONS_VERSION_CRUBY_4_0`; ADR 0008 records the decision and narrow syntax boundary.
- Native CLI tests verify Ruby 4 newline-leading `&&`, Spinel `ffi_func` source, comments, inert `require`, side-effect non-execution, deterministic parsing, Prism's original diagnostic and byte offset/line/byte-column, missing input errors, and explicit NUL rejection.
- Binary runs with `PATH=/usr/bin:/bin`; `otool -L build/fleek` shows only macOS `libSystem`.
- Mutation gates caught usage status, NUL acceptance, Ruby 3.3 grammar downgrade, and incorrect location attribution. `make check` passes with Flay score 0 and Reek warnings 0.

## Ticket 03 receipt

- ADR 0009 records the one-simple-class support boundary, explicit unsupported errors, status behavior, and Prism ownership cleanup.
- `--checks reek:ClassVariable` reports one plain read/write/target occurrence using the pinned Reek 6.6.0 name, context, message, line, URL, and status 2. Clean results return 0; missing selection, syntax errors, NUL, and unsupported forms return 1.
- Native tests compare identical finding and clean fixtures against unchanged Reek 6.6.0. Comments and strings containing `@@` remain clean.
- Project `make check` passes: all native CLI contracts, eight behavior mutants, fixture/project Flay score 0, and Reek 0 warnings. Full pinned Spinel `make check` passes: 3,596 tests, zero failures/errors, alloc-report, inference, and spin-e2e all green. Socket-dependent upstream tests required the approved network-enabled run; the sandboxed run was blocked by local socket restrictions.

## Ticket 04 receipt

- ADR 0010 records Reek's grouping and scope behavior plus the explicit limit for nested and reopened class/module declarations.
- Reek 6.6.0 confirmed method-body and singleton-class occurrences join the enclosing class; top-level-only class variables are ignored; nested contexts qualify names; reopenings produce separate findings.
- Native reports group reads and class-variable writes by name, retain all source lines, and sort names to match Reek. Plain, `+=`, `||=`, `&&=`, destructuring, method, and singleton-context fixtures match Reek; top-level-only source matches its clean status.
- Nested class/module scopes and reopenings remain unsupported and fail explicitly. Project `make check` passes with ten caught mutants, Flay score 0, and Reek 0 warnings.

## Ticket 05 receipt

- ADR 0011 documents sorted recursive discovery, hidden-directory exclusion, directory-symlink exclusion, file-symlink inclusion, repeated paths, and the intentional explicit directory-symlink error that prevents empty-success ambiguity.
- Explicit invalid/missing inputs fail. Mixed valid and invalid inputs retain valid findings and report incomplete coverage with failed paths and exit 1; empty scans fail.
- Reek 6.6.0 reference comparisons cover directory and repeated-path behavior. Five additional mutants cover hidden folders, directory symlinks, repeated paths, empty scans, and error precedence; all 15 project mutants are caught.

## Ticket 06 receipt

- ADR 0012 records `--stdin SOURCE [PATH...]`, required origin, valid empty source semantics, mixed-input behavior, and the no-current-directory fallback rule.
- Named stdin uses the supplied origin for findings and parse diagnostics, and its output matches file analysis for the same source and origin. Mixed stdin/path checks both sources; empty stdin reports one complete clean source.
- Mutation checks cover missing origin, wrong origin attribution, skipped stdin findings status, accidental empty-input fallback, and dropped path inputs.

## Ticket 07 receipt

- ADR 0013 records the YAML-library blocker, supported block subset, discovery and scope behavior, source suppressions, exclusions, and deliberate no-analysis status differences.
- Reference contracts cover explicit/discovered precedence, enablement, directory scope and globs, context/path exclusions, suppression comments, malformed mapping/list rejection, and stdin origin. All 27 mutants were caught; project Reek warnings and Flay score were zero.
- Pinned Spinel 2026.09.12 full check passed: 3,596 tests, alloc report, inference, and spin-e2e.

## Ticket 09 receipt

- ADR 0016 records the exact single-file/two-method grammar, Flay structural equality, default-mass scoring, deliberate exit-status difference, and explicit unsupported cases. The ticket is groundwork for combined reporting, not its completion.
- Locked Flay 2.14.4 comparisons cover renamed/changed-literal similar groups, identical groups, different structure, unsupported syntax, score and locations. Threshold boundary expansion and combined selection are tracked by tickets 10 and 12.
- Native intermediate method shapes and locations are per-analysis locals; the existing native report buffer remains the adapter's output channel. Named constants describe supported statement tags and error results.
- All project build/contracts and Flay/Reek checks pass; 36 mutations were caught across complete and focused runs. Pinned Spinel's host socket limitation remains documented in ADR 0015.

## Ticket 10 receipt

- ADR 0017 records validated `--mass MASS` support from 3 through the native integer maximum, default 16, and the lower bound that prevents unimplemented nested candidates from being silently omitted.
- Locked Flay 2.14.4 comparisons at thresholds 15, 16, and 17 match the mass-16 fixture; invalid mass values fail before analysis. Reports include group, total, and applicable single-file score contributions.
- All 39 mutants are caught, including the inclusive mass boundary, identical multiplier, and total score. The mutation harness now forces a fresh binary so timestamp granularity cannot produce false mutant survival. All project build/contracts, Flay, and Reek checks pass; both specification and standards code-review axes pass.

## Ticket 11 receipt

- ADR 0017 records why Flay drops lone top-level method files, how two supported methods are combined across files, deterministic file/line order, equal per-file score allocation, and why pruning has no effect while mass is at least 3.
- Pinned Flay 2.14.4 comparisons cover cross-file identical groups, scores, reversed input ordering, a failed requested path, and the lone-method parser boundary. Failure retains valid groups but marks coverage incomplete with exit 1.
- The full mutation suite catches all 43 mutations, including cross-file candidate collection, fail-closed nested-scope rejection, source line mapping, and order. Project contracts and build pass; Flay score 0 and Reek warnings 0. Pinned Spinel full-suite host restrictions remain recorded in ADR 0015.

## Ticket 12 receipt

- ADR 0018 records the combined selection form, independent Flay/Reek exclusions, unsupported syntax boundaries, and deliberate upstream output/status differences.
- Pinned Flay and Reek contracts verify equivalent source sets, finding identity, locations, scores/mass, status, and report ordering. Incomplete results override findings; clean and finding outcomes remain 0 and 2.
- All 45 mutation cases, project contracts/build, Flay score 0, and Reek warnings 0 pass. Specification and standards code reviews pass.

## Ticket 13 receipt

- ADR 0019 records ClassVariable support for one simple class or module, inert Spinel FFI handling, Reek's Ruby 4 parser rejection, and exact bounded Flay extension shapes; arbitrary grammar remains explicitly unsupported.
- Ruby 4 ClassVariable and suppression checks preserve source lines. Flay parity compares unchanged 2.14.4 finding kind, node mass, score, ordered locations, and exit status for similar and identical Ruby 4 groups and Spinel FFI modules; unsupported operands and non-final operators return incomplete.
- All 51 project mutations were caught. `make all test flay reek` passes with 13 contracts, Flay score 0, and Reek warnings 0; specification and standards reviews pass.

## Ticket 14 receipt

- ADR 0020 and `docs/research/rails-project-parity.md` pin the MIT/Beerware Rails 8 Tutorial corpus, 25-file Ruby manifest, settings, versions, commands, outputs, and source notice without vendoring source.
- Identical-input references report Reek ClassVariable clean and Flay score 48 at `users_controller.rb:51,58`; Fleek accurately exits incomplete. Inherited classes now pass the ClassVariable check and match Reek, caught by the dedicated mutation; two namespaced files still fail.
- Full Rails parity and release/runtime claims remain blocked by tickets 18–19. Existing code review and full gates must pass for the ticket 14 documentation and inheritance slice.

## Ticket 08 receipt

- ADR 0014 defines the versioned report fields/order, path escaping, selected versus run checks, successful/failed/excluded coverage semantics, exit status, help/version capability text, and unsupported format handling.
- The compiled CLI contract verifies findings, clean and partial reports, stdout/stderr separation, special path characters and UTF-8, repeat determinism, source order, and unsupported format failure.
- Named stdin path exclusions now appear as excluded coverage and incomplete status when they leave no analyzed source; Reek returns 0 for the same input, while Fleek follows the success-must-prove-analysis rule (ADR 0013).
- `Checks run` means analyzer invocation; parse/unsupported-source failures count as failed attempts, while pre-analysis exclusions report `none` (ADR 0014).
- Discovery-rejected paths appear with `scope=failed`; analyzer-rejected paths stay `included` and associate through path-specific diagnostics and failed coverage (ADR 0014).
- Empty scans and rejected directory symlinks keep exit 1 and their diagnostics but add no source rows/counts; mixed requests count only real sources (ADR 0014).
- All 35 project mutants were caught; the project build/contracts, Flay (0), and Reek (0) pass. Pinned Spinel `make check` completed with 3,574 pass and 22 failures on host-restricted socket tests plus an intermittent GC-root case; ADR 0015 records the limitation and required rerun on a loopback-capable host.

## Ticket 19 required-parameter receipt

- ADR 0026 records the supported required positional parameter boundary and identical-group semantics.
- Pinned Flay 2.14.4 and Fleek match parameterized Rails-shaped `:defn` groups at mass/score 48 for same and different required arities. A fixture with different formal names matches as a similar group rather than identical.
- Focused mutations reject losing required-parameter candidates and incorrectly classifying different formal names as identical. Full 25-file parity remains open.

## Ticket 19 conditional-branch receipt

- ADR 0027 records bounded `if`/`else` support and Flay's mass treatment of the else wrapper.
- Pinned Flay 2.14.4 and Fleek match the conditional class-method fixture at mass/score 62, lines 2 and 14. Mutations protect branch collection and mass.
- `unless` and other unsupported control flow remain partial; the pinned full manifest remains open.

## Ticket 19 boolean-OR receipt

- ADR 0031 records bounded Prism `OrNode` support inside class-method candidates.
- Pinned Flay 2.14.4 and Fleek match the paired fixture as similar `:defn` groups at mass/score 34, lines 2 and 12. A focused mutation protects OR support.
- Class-level Rails declarations remain unsupported, so exact-manifest completion remains open.

## Ticket 22 optional-keyword receipt

- ADR 0130 records optional keyword parameters with supported literal defaults: two mass units per keyword per method, name/default identity, and optional-count grouping parity.
- Pinned Flay 2.14.4 and Fleek match the similar group at mass/score 10 and both leave differing optional-keyword counts ungrouped. Nonliteral defaults remain incomplete in Fleek; Flay finds a mass-10 candidate. Five focused mutations protect acceptance, identity, mass, count, and rejection behavior.

## Ticket 22 post-parameter receipt

- ADR 0131 records required positional post parameters, with post names and counts affecting identical classification but adding no Flay mass.
- Pinned Flay 2.14.4 and Fleek match mass/score 10, locations, and coverage for supported signatures, including differing post names and counts. Focused mutations protect support, identity, and mass.

## Ticket 22 keyword-rest receipt

- ADR 0132 records support for named keyword-rest parameters, with names affecting identity but no mass addition; anonymous keyword-rest remains unsupported.
- Pinned Flay 2.14.4 and Fleek match the similar group at mass/score 6, with complete coverage. Focused mutations protect candidate support and name comparison.

## Ticket 22 block-parameter receipt

- ADR 0133 records named block parameters, with names affecting identity but no mass addition; anonymous block parameters remain unsupported.
- Pinned Flay 2.14.4 and Fleek match the named similar group at mass/score 6. Anonymous forms are verified as incomplete in Fleek while Flay finds an identical score-12 group. Focused mutations protect support, identity, and rejection.

## Ticket 22 yield receipt

- ADR 0134 records yield-node support through the existing recursive candidate collector.
- Pinned Flay 2.14.4 and Fleek match bare-yield mass/score 6/12 and yield-with-local-argument mass/score 8/16. A focused mutation protects candidate support.

## Ticket 22 super receipt

- ADR 0135 records support for bare and argument-bearing super expressions through the recursive candidate collector.
- Pinned Flay 2.14.4 and Fleek match bare-super mass/score 6 and `super(value)` mass/score 8. Separate focused mutations protect each Prism node kind.

## Ticket 22 next receipt

- ADR 0136 records `PM_NEXT_NODE` support in recursive method candidates.
- Pinned Flay 2.14.4 and Fleek match a `next value if value` block fixture at mass/score 24, protected by focused node-support and mass mutations.

## Ticket 22 break and redo receipt

- ADR 0137 records recursive candidate support for Prism `PM_BREAK_NODE` and `PM_REDO_NODE`.
- Pinned Flay 2.14.4 and Fleek match block fixtures at mass/score 20 (`break value if value`) and 18 (`redo if value`), protected by separate candidate mutations.

## Ticket 22 exception-flow receipt

- ADR 0138 records recursive candidate support for Prism begin, rescue, and retry nodes.
- Pinned Flay 2.14.4 and Fleek match the rescue/retry method pair at mass/score 16, protected by node-specific and retry-mass mutations.

## Ticket 22 ensure receipt

- ADR 0139 records Prism `PM_ENSURE_NODE` support in recursive method candidates.
- Pinned Flay 2.14.4 and Fleek match begin/ensure methods at mass/score 10, protected by candidate-support and mass mutations.

## Ticket 22 regular-expression receipt

- ADRs 0140 and 0141 record static and interpolated Prism regular-expression support and their identity rules in method candidates. ADR 0142 records the focused mutation-contract mapping that avoids repeated Flay work.
- Pinned Flay 2.14.4 and Fleek match static regex method pairs at mass 10 and interpolated regex pairs at mass 16. Focused mutations protect support, mass, pattern parts, and option flags.
- ADR 0143 records anonymous method block-parameter support and safe comparison of absent Prism parameter names, superseding ADR 0133's rejection boundary.
- Pinned Flay 2.14.4 and Fleek match anonymous `&` methods at mass 6 and score 12, and `&` versus `&handler` methods as similar at mass/score 6. Focused mutations protect candidate support and both identity boundaries.
- ADR 0144 extends the optional-name rule to anonymous `*` and `**` parameters, superseding the rejection boundaries in ADRs 0128 and 0132.
- Pinned Flay 2.14.4 and Fleek match anonymous rest and keyword-rest methods at mass 6/score 12, with anonymous-versus-named methods similar at mass/score 6; focused mutations protect support and identity.
- ADR 0145 records multiple-assignment support and the two-point per-`MultiWriteNode` mass adjustment needed to match Flay's RubyParser tree. Compiled CLI contracts match identical two-target methods (mass 22), target-name-only variants (similar, mass 20), identical three-target methods (mass 26), and a clean result for differing target counts; focused mutations protect candidate support, target identity, and mass.
- ADR 0146 records nested block optional-parameter support and Flay's one-point mass adjustment per optional-parameter list. Compiled CLI contracts compare one and two optional parameters, differing names and defaults, plus the clean one-versus-two boundary; focused mutations protect support, mass, and tree identity.
- ADR 0147 records local-variable operator-write support in method candidates, with two mass points per write and exact operator-token identity. Flay contracts cover identical writes, renamed-variable methods, and differing operators; focused mutations protect candidate support, mass, and operator identity.
- ADR 0148 records local-variable `&&=`/`||=` support, with two mass points per node and target-name identity. Flay contracts cover identical writes, renamed targets, and the no-group boundary between the two operators; focused mutations protect support, mass, and identity for both node types.
- ADR 0149 records class-variable reads in method candidates with ordinary Flay mass and name-sensitive identical-versus-similar classification; focused mutations protect support and identity.
- ADR 0150 records class-variable operator writes in method candidates with Flay's two-point mass adjustment and target/operator-sensitive identical-versus-similar classification; focused mutations protect support, mass, and identity.
- ADR 0151 records class-variable logical writes with Flay's two-point mass adjustment, name-sensitive classification, and separate AND/OR node identity; focused mutations protect support, mass, and identity.
- ADR 0152 records plain class-variable writes with ordinary Flay mass and name-sensitive classification; focused mutations protect support, mass, and identity.
- ADR 0153 records optional keyword constant defaults with Flay's existing two mass units and constant-name-sensitive identity; focused mutations protect acceptance and identity.
- ADR 0154 extends Flay parity to constant defaults on optional positional parameters, preserving mass and comparing constant names; it supersedes ADR 0035's literal-only boundary.
- ADR 0156 adds bare no-argument call defaults for positional optional parameters at unchanged mass, with call-name-sensitive identity and focused mutations.
- Issue 34 and ADR 0155 isolate each parallel mutation-contract compiler's Spinel temp files; all 40 contracts precompile at `JOBS=8` in about 30 seconds, retaining parallel mutation workers.
- Issue 35 and ADR 0157 exclude disposable build/mutation-* outputs from isolated worker copies. A measured 108 MB build copy fell to 3.4 MB and 0.393 s; the pinned full gate passed in 6:33.24 with 285 mutants caught, Flay 0, and Reek 0.

## Harness priority frontier — 2026-10-19

Start **106**; execute one ticket per fresh Luna context, sequentially through **115**. New numbers preserve all published references; dependency edges, not renumbering, put harness work first.

- [106: Measure reproducible harness phase costs](issues/106-measure-harness-phase-costs.md) — unblocked.
- [107: Refill check slots when any worker finishes](issues/107-refill-finished-check-slots.md) — blocked by 106.
- [108: Use the resolved worker budget for contract precompile](issues/108-inherit-precompile-worker-budget.md) — blocked by 107.
- [109: Stage only required workspace inputs for isolated workers](issues/109-exclude-unused-worker-copy-inputs.md) — blocked by 108.
- [110: Reuse one unchanged leaf contract across mutation runs](issues/110-cache-one-leaf-mutation-contract.md) — blocked by 109.
- [111: Reuse a contract with shared source dependencies](issues/111-cache-contract-dependency-closure.md) — blocked by 110.
- [112: Enable safe reuse for all mapped mutation contracts](issues/112-enable-safe-shared-contract-cache.md) — blocked by 111.
- [113: Narrow the highest-cost remaining mutation contract](issues/113-focus-highest-cost-mutation-contract.md) — blocked by 112.
- [114: Narrow the next costly independent mutation contract](issues/114-focus-next-cost-mutation-contract.md) — blocked by 113.
- [115: Verify harness savings before resuming feature work](issues/115-verify-harness-savings-and-handoff.md) — blocked by 114.

Tickets 48–105 all retain their former blockers and additionally wait for 115. Parent tickets 22/23/24/25/43 remain unchanged, with claims preserved; resume their implementation through their children only after 115. Existing closure rules still require all residual children; README parent 25 remains last. Newly discovered harness defects must block 115; newly added feature children must depend on 115 until it resolves. Do not resolve or reopen old parents merely to reorder work.

This publication changes tracker documents only; performance claims require the measurements in these tickets.

## Luna execution breakdown — 2026-10-19

### Current state and scope

Inspected HEAD `65203bccb2b774bbdcf3fc3502cc279115e77930`, local tracker, native dispatch/descriptors, contracts, and installed pinned reference source. This is a planning snapshot, not a fresh runtime or full-gate receipt. Existing uncommitted change claims ticket 43; it is preserved byte-for-byte. Parent issues are unchanged per the local to-tickets workflow. Tickets 22, 23 and 43 are claimed; 24 and 25 are open. All other existing issues across the three efforts are resolved, including 21, 42, 44–47, all default-check issues and parallel-check issue 01. Historical unresolved statements elsewhere in this map are superseded by current ticket status and this snapshot.

Progress exists: descriptors for scalars/calls/collections/control flow/ranges/regex/parameters and generated per-descriptor contracts landed. Completion remains blocked by composition and translator-closure evidence, fuzzy/legacy/path controls, bounded Reek scope/settings, unsupported UnusedPrivateMethod and full Rails proof. Existing Rails contract explicitly expects Flay incomplete and checks only Reek ClassVariable. Passing it cannot prove ticket 24. Default selection completion is not full Reek grammar/configuration parity.

### Start here

Start harness ticket 106. Complete the linear harness chain 106–115 before resuming feature children 48–105; each now explicitly depends on 115 as well as its original blockers. After 115 resolves, resume child 48 for the ticket-43 stream; 49/50 and the other previously independent children become available under their original dependencies. Choose one child and one behavior per context. Do not start another agent or alter parent claims merely because several tasks are available. Check live status and existing child Answer before claiming; a claimed child belongs to its current worker until handed off.

Every child is independently finishable. The suggested cases bound one behavior, not all grammar for that detector. Known unsupported assertions are starting evidence, not tests to delete blindly. First prove upstream accepts the case. When already green, retain existing proof and add only a missing boundary. One independent mismatch becomes one additional numbered child, linked to its parent and this map. Do not duplicate existing children. Completion/audit tickets below wait for those residual children as well as their static blockers.

### Parent acceptance and dependency rules

- **43 and 22:** 48–51 prove compositions, scope, pruning and ordering; 52 audits remaining shared-rule/adapter obligations and records closure evidence. Do not resolve either parent until its unchanged acceptance checklist and every residual translator child pass.
- **23:** 53–58 cover fuzzy, legacy, ignore/path and option interactions; 59 verifies the entire control inventory. Fuzzy/legacy depend on 22; existing path work can start earlier. No reference-tool subprocess may replace native Fleek analysis.
- **24:** 60–61 implement opt-in behavior; 62–89 give each of the 28 default detectors one narrow boundary; 90–95 cover remaining settings/config/selection/extension obligations. Census 96 publishes concrete residual gaps. Children 97–101 verify complete exact-manifest Flay and all 29 Reek detectors; 102 closes the full parity gate only after all original and newly discovered requirements pass.
- **25:** 103–105 split install proof, human behavior docs and final command/link review. Start only after all non-README work, including future gap tickets, resolves. These children never depend on parent 25, avoiding the dynamic last-ticket dependency cycle. Resolve 25 last, after its children and every other ticket resolve. Release publication is not added to this effort.

### Verified entry points and commands

Paths below are repo-relative wayfinding; child prose uses symbols/behavior so implementation can move.

- Native descriptors, candidate collection, Reek detector dispatch/settings, unsupported opt-in and source discovery: `bin/fleek.rb`.
- Per-descriptor generated comparisons: `test/duplication_generated_descriptor_contract.rb`; shared CLI comparison helpers: `test/analysis_runner.rb`; existing focused method contracts: `test/duplication_method_*_contract.rb`.
- Existing bounded Reek proof: `test/default_object_scope_contract.rb`, `test/default_argument_api_contract.rb`, `test/class_variable_contract.rb`, `test/class_variable_scope_contract.rb`; config/selection: `test/configuration_contract.rb`, `test/default_configuration_contract.rb`, `test/default_invocation_contract.rb`, `test/combined_contract.rb`.
- Existing Rails manifest and pin: `test/rails_manifest_parity_contract.rb`, `docs/research/rails-project-parity.md`; extensions: `test/language_extensions_contract.rb`. Keep corpus revision `92ce7c470bc31952d7dc51cac15e577a948e479e`, exactly 25 tracked app Ruby files and unchanged reference inputs.
- Compiler pin: `docs/agents/spinel.md`; execution rules: `AGENTS.md`; tracker rules: `docs/agents/issue-tracker.md`. Version tag object `00ce35bb96e489620358ffbc48791001a73778a5`, peeled source commit `112bae85c1a25fc5399009a849f805bfe691426b`.
- Set `SPINEL=<pinned-build>/spinel`, `SPINEL_ROOT=<pinned-build>` and `BUNDLE_PATH=<preinstalled-bundle>` as environment variables for the local setup. Run `make ticket-check` for tracker validation. Run a selected existing contract with `$SPINEL -E <contract.rb>` after building `make all` when code changes. Use exact labels from `test/mutation_contract.rb` with `FLEEK_MUTATIONS='<label>' make mutation`; never guess labels. Before a code commit run `make check` and the upstream Spinel build/test requirements in AGENTS.md. For corpus completion also run `FLEEK_RAILS_CORPUS=<pinned-corpus> make rails-manifest-parity`; missing corpus must not count as a pass.
- Docs-only breakdown: no implementation, runtime benchmarks, upstream tests or code tests. Tracker validation does not prove analyzer parity.

### Child index

Every feature child below additionally depends on harness handoff 115; original dependencies are retained.

- [48: Compose method parameters with nested blocks](issues/48-composed-parameters-and-blocks.md) — parent 43 / 22; blocked by 42; 115.
- [49: Compose collections inside branches and loops](issues/49-composed-collections-and-branches.md) — parent 43 / 22; blocked by 42; 115.
- [50: Compose exception flow with interpolated values](issues/50-composed-exceptions-and-regexp.md) — parent 43 / 22; blocked by 42; 115.
- [51: Verify composed groups across scopes and files](issues/51-composed-cross-file-pruning.md) — parent 43 / 22; blocked by 48; 49; 50; 115.
- [52: Finish descriptor and composed-method evidence](issues/52-close-method-translator-evidence.md) — parent 43 / 22; blocked by 48; 49; 50; 51; 115.
- [53: Match Flay fuzzy detection at default distance](issues/53-fuzzy-default-distance.md) — parent 23; blocked by 22; 115.
- [54: Match explicit fuzzy distance and validation](issues/54-fuzzy-distance-controls.md) — parent 23; blocked by 53; 115.
- [55: Match Flay legacy parser mode on shared syntax](issues/55-legacy-parser-semantics.md) — parent 23; blocked by 22; 115.
- [56: Match .flayignore pattern semantics](issues/56-flayignore-pattern-semantics.md) — parent 23; blocked by 115.
- [57: Match Flay path expansion and duplicate inputs](issues/57-flay-path-expansion-semantics.md) — parent 23; blocked by 115.
- [58: Verify Flay control precedence and routing](issues/58-flay-control-interactions.md) — parent 23.
- [59: Close Flay control inventory with evidence](issues/59-close-flay-controls-evidence.md) — parent 23; blocked by 53; 54; 55; 56; 57; 58; 115.
- [60: Analyze directly unused private methods](issues/60-unused-private-method-basics.md) — parent 24; blocked by 115.
- [61: Honor private-method visibility and opt-in configuration](issues/61-unused-private-method-visibility-config.md) — parent 24; blocked by 60; 115.
- [62: Match ClassVariable nested namespace contexts](issues/62-reek-class-variable-boundary.md) — parent 24; blocked by 115.
- [63: Match Attribute nested class attribute declarations](issues/63-reek-attribute-boundary.md) — parent 24; blocked by 115.
- [64: Match InstanceVariableAssumption nested class instance-variable use](issues/64-reek-instance-variable-assumption-boundary.md) — parent 24; blocked by 115.
- [65: Match SubclassedFromCoreClass Class.new inheritance](issues/65-reek-subclassed-from-core-class-boundary.md) — parent 24; blocked by 115.
- [66: Match ModuleInitialize nested module initialize methods](issues/66-reek-module-initialize-boundary.md) — parent 24; blocked by 115.
- [67: Match IrresponsibleModule Class.new comments](issues/67-reek-irresponsible-module-boundary.md) — parent 24; blocked by 115.
- [68: Match LongParameterList block parameters](issues/68-reek-long-parameter-list-boundary.md) — parent 24; blocked by 115.
- [69: Match BooleanParameter singleton method boolean defaults](issues/69-reek-boolean-parameter-boundary.md) — parent 24; blocked by 115.
- [70: Match LongYieldList nested block yields](issues/70-reek-long-yield-list-boundary.md) — parent 24; blocked by 115.
- [71: Match ControlParameter nested conditional use](issues/71-reek-control-parameter-boundary.md) — parent 24; blocked by 115.
- [72: Match UnusedParameters block-local shadowing](issues/72-reek-unused-parameters-boundary.md) — parent 24; blocked by 115.
- [73: Match UtilityFunction public_methods_only setting](issues/73-reek-utility-function-boundary.md) — parent 24; blocked by 115.
- [74: Match DuplicateMethodCall nested repeated receiver calls](issues/74-reek-duplicate-method-call-boundary.md) — parent 24; blocked by 115.
- [75: Match ManualDispatch guarded dispatch inside a branch](issues/75-reek-manual-dispatch-boundary.md) — parent 24; blocked by 115.
- [76: Match NilCheck nil checks inside blocks](issues/76-reek-nil-check-boundary.md) — parent 24; blocked by 115.
- [77: Match MissingSafeMethod singleton bang method companions](issues/77-reek-missing-safe-method-boundary.md) — parent 24; blocked by 115.
- [78: Match RepeatedConditional nested-class conditional isolation](issues/78-reek-repeated-conditional-boundary.md) — parent 24; blocked by 115.
- [79: Match NestedIterators ignored nested iterator names](issues/79-reek-nested-iterators-boundary.md) — parent 24; blocked by 115.
- [80: Match FeatureEnvy receiver calls inside blocks](issues/80-reek-feature-envy-boundary.md) — parent 24; blocked by 115.
- [81: Match DataClump singleton method parameter groups](issues/81-reek-data-clump-boundary.md) — parent 24; blocked by 115.
- [82: Match TooManyConstants nested namespace constant isolation](issues/82-reek-too-many-constants-boundary.md) — parent 24; blocked by 115.
- [83: Match TooManyInstanceVariables nested class variable isolation](issues/83-reek-too-many-instance-variables-boundary.md) — parent 24; blocked by 115.
- [84: Match TooManyMethods nested class method counts](issues/84-reek-too-many-methods-boundary.md) — parent 24; blocked by 115.
- [85: Match TooManyStatements singleton-class method bodies](issues/85-reek-too-many-statements-boundary.md) — parent 24; blocked by 115.
- [86: Match UncommunicativeMethodName nested singleton method names](issues/86-reek-uncommunicative-method-name-boundary.md) — parent 24; blocked by 115.
- [87: Match UncommunicativeModuleName qualified namespace names](issues/87-reek-uncommunicative-module-name-boundary.md) — parent 24; blocked by 115.
- [88: Match UncommunicativeParameterName block parameter names](issues/88-reek-uncommunicative-parameter-name-boundary.md) — parent 24; blocked by 115.
- [89: Match UncommunicativeVariableName block-local names](issues/89-reek-uncommunicative-variable-name-boundary.md) — parent 24; blocked by 115.
- [90: Inventory all Reek settings and remaining gaps](issues/90-reek-settings-coverage-inventory.md) — parent 24; blocked by 61; 115.
- [91: Verify Reek discovery and directory precedence](issues/91-reek-configuration-precedence.md) — parent 24; blocked by 90; 115.
- [92: Verify Reek comment suppression scope](issues/92-reek-suppression-parity.md) — parent 24; blocked by 90; 115.
- [93: Validate Reek configuration before analysis](issues/93-reek-configuration-validation.md) — parent 24; blocked by 90; 115.
- [94: Verify default, subset and combined outcomes](issues/94-combined-selection-and-outcomes.md) — parent 24; blocked by 59; 61; 90; 91; 92; 93; 115.
- [95: Separate extension evidence and prove non-execution](issues/95-extension-and-nonexecution-evidence.md) — parent 24; blocked by 52; 115.
- [96: Record exact gaps on the pinned Rails manifest](issues/96-rails-residual-gap-census.md) — parent 24; blocked by 115.
- [97: Require complete Flay analysis of pinned Rails sources](issues/97-rails-flay-completion-gate.md) — parent 24; blocked by 96; 22; 23; 115.
- [98: Verify Rails Reek object scopes results](issues/98-rails-reek-object-scopes.md) — parent 24; blocked by 96; 62; 63; 64; 65; 66; 67; 115.
- [99: Verify Rails Reek method api results](issues/99-rails-reek-method-api.md) — parent 24; blocked by 96; 60; 61; 68; 69; 70; 71; 72; 73; 115.
- [100: Verify Rails Reek calls and flow results](issues/100-rails-reek-calls-and-flow.md) — parent 24; blocked by 96; 74; 75; 76; 77; 78; 79; 80; 115.
- [101: Verify Rails Reek data size and names results](issues/101-rails-reek-data-size-and-names.md) — parent 24; blocked by 96; 81; 82; 83; 84; 85; 86; 87; 88; 89; 115.
- [102: Close shared-syntax parity only after every gap](issues/102-close-shared-syntax-parity.md) — parent 24; blocked by 22; 23; 43; 90; 91; 92; 93; 94; 95; 96; 97; 98; 99; 100; 101; 115.
- [103: Document verified release installation and first run](issues/103-readme-release-installation.md) — parent 25; blocked by 102; 115.
- [104: Explain Fleek checks, reports and limits](issues/104-readme-behavior-and-limits.md) — parent 25; blocked by 103; 115.
- [105: Verify README commands, links and final claims](issues/105-readme-final-command-link-review.md) — parent 25; blocked by 104; 115.
- [122: Complete UnusedPrivateMethod inherited and dynamic-call parity](issues/122-unused-private-method-call-graph-residuals.md) — parent 24; blocked by 61; 115.
- [123: Match deeper and wrapped ClassVariable namespace contexts](issues/123-class-variable-deeper-and-wrapped-namespaces.md) — parent 24; blocked by 62; 115.
- [124: Match Attribute in deeper and wrapped class scopes](issues/124-attribute-deeper-and-wrapped-class-scopes.md) — parent 24; blocked by 63; 115.
- [126: Support LongParameterList context overrides](issues/126-reek-long-parameter-overrides.md) — parent 24; blocked by 90 (resolved); 115 (resolved).
- [127: Prevent UnusedPrivateMethod crash on framework superclass](issues/127-unused-private-method-framework-subclass-crash.md) — parent 24; blocked by 61; 96; 115.
- [130: Analyze Rails class callback declarations for Flay](issues/130-rails-flay-class-callback-declarations.md) — resolved; parent 97; blocked by 115 (resolved).
- [131: Analyze Rails Flay visibility declarations](issues/131-rails-flay-visibility-declarations.md) — resolved; parent 97; blocked by 115 (resolved).
- [132: Analyze Rails Flay include declarations](issues/132-rails-flay-include-declarations.md) — resolved; parent 97; blocked by 115 (resolved).
- [133: Analyze empty Rails class methods for Flay](issues/133-rails-flay-empty-method-bodies.md) — parent 97; blocked by 115 (resolved).
- [134: Analyze Rails primary_abstract_class declarations for Flay](issues/134-rails-flay-primary-abstract-class.md) — resolved; parent 97; blocked by 115 (resolved).
- [135: Analyze Rails ApplicationMailer declarations for Flay](issues/135-rails-flay-mailer-declarations.md) — resolved; parent 97; blocked by 115 (resolved).
- [136: Analyze the Rails helper hash default for Flay](issues/136-rails-flay-helper-hash-default.md) — resolved; parent 97; blocked by 115 (resolved).
- [137: Analyze the Rails Relationship model declarations for Flay](issues/137-rails-flay-relationship-declarations.md) — parent 97; blocked by 115 (resolved).
- [128: Preserve per-file results after Flay timeout](issues/128-flay-per-file-timeout-continuation.md) — resolved; parent 23; blocked by 120; 115.
- [129: Avoid timeout supervisor overhead on untimed Flay runs](issues/129-flay-timeout-supervisor-overhead.md) — parent 23; resolved.
- [121: Inventory and support Flay presentation controls](issues/121-flay-presentation-controls.md) — resolved; parent 23; blocked by 58 (resolved); 115 (resolved).
