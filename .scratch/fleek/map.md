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
- Ticket 21 now reports reference-matched `:class` and `:module` candidates, including complete multi-method scopes; preserves independent method/scope groups; and orders multi-group results deterministically. Direct class candidates at file scope and in one-level namespaces, module methods in sole nested-module chains through ten modules, one class under up to eight nested modules, classes with multiple methods under relative qualified module paths through nine components, nested class chains through five levels, existing bounded direct-sibling and wrapper forms, and multiple classes under qualified module paths are covered against Flay 2.14.4; deeper paths and nested class chains remain incomplete. See [ADR 0049](../../docs/adr/0049-bounded-flay-class-groups.md), [ADR 0050](../../docs/adr/0050-flay-multiple-class-and-module-groups.md), [ADR 0051](../../docs/adr/0051-qualified-module-class-candidates.md), [ADR 0052](../../docs/adr/0052-bounded-nested-class-candidates.md), [ADR 0053](../../docs/adr/0053-multiple-classes-in-qualified-modules.md), [ADR 0054](../../docs/adr/0054-three-level-nested-class-candidates.md), [ADR 0055](../../docs/adr/0055-nested-class-sibling-candidates.md), [ADR 0056](../../docs/adr/0056-nested-class-siblings-with-one-wrapper.md), [ADR 0057](../../docs/adr/0057-multi-method-nested-sibling-wrappers.md), [ADR 0058](../../docs/adr/0058-multi-method-nested-sibling-classes.md), [ADR 0059](../../docs/adr/0059-multi-method-qualified-module-classes.md), [ADR 0060](../../docs/adr/0060-four-level-nested-class-candidates.md), [ADR 0061](../../docs/adr/0061-nine-level-nested-module-methods.md), [ADR 0062](../../docs/adr/0062-eight-component-qualified-module-classes.md), [ADR 0063](../../docs/adr/0063-nine-component-qualified-module-classes.md), [ADR 0064](../../docs/adr/0064-ten-level-nested-module-methods.md), [ADR 0065](../../docs/adr/0065-five-level-nested-class-candidates.md), and [ADR 0066](../../docs/adr/0066-eight-level-nested-module-classes.md); broader class and grammar boundaries remain open.
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
