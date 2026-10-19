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
