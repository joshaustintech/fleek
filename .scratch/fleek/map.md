# Fleek

## Notes

- Canonical project specification is `spec.md`; detailed slice specifications are linked from it.
- One local Markdown issue per ticket in `issues/`, numbered globally in dependency order.
- Category `enhancement`; triage state `ready-for-agent` until completion. `Status` tracks open/claimed/resolved workflow.
- Triage comments begin with the required AI disclaimer.
- Tickets 01–14 resolved and pushed in order; ticket 14 records a real-project release blocker. Tickets 18–19 must close before runtime/archive/release tickets can pass.

## Decisions-so-far

- Native combined Flay/Reek replacement; pinned Spinel compiler; Ruby 4.0 and pinned Spinel source input; standalone macOS arm64 release.
- Primary test seam: compiled CLI process. Parser feasibility uses a temporary real native probe.
- Ticket sequence and dependencies in issue bodies; summary: 01 compiler/reference harness → 02 parser → 03–08 smell/input/config/text → 09–12 duplication/combined report → 13–14 language/Rails parity → 18–19 Rails coverage → 15–17 runtime/release.
- Research notes and ADRs link from `spec.md` and project documentation.
- Ticket 07 imports a bounded Reek YAML subset without a YAML library; see ADR 0013 for supported keys and deliberate no-analysis exit differences.
- Ticket 08 defines stable text report v1 and explicit coverage/status fields; see ADR 0014 for layout, escaping, stream, and unsupported-format behavior.
- Ticket 09 adds bounded, separately selectable default Flay structural groups; see ADR 0016. Threshold boundaries and combined reporting remain tickets 10 and 12.
- Ticket 10 supports validated `--mass MASS`, and ticket 11 adds deterministic two-method cross-file groups and partial-input status; see ADR 0017 for the shared grammar, pruning boundary, and per-file score allocation.
- Ticket 12 combines explicitly selected Flay and Reek checks with independent exclusions and one incomplete/finding/complete outcome; see ADR 0018 for syntax boundaries, equivalent-reference parity, and deliberate exit-status normalization.
- Ticket 13 proves bounded Ruby 4 and pinned Spinel analysis, inert source processing, and reference-backed Flay extension parity; see ADR 0019 for the supported integer-`&&`/`ffi_func` shapes and separate Flay node-mass/group-score reporting.
- Ticket 14 pins the real Rails corpus and records exact incomplete parity; see ADR 0020. Tickets 18–19 gate release/runtime work until namespace and class-method coverage matches references.

## Fog

- Native analyzer coverage starts with tickets 03–04's bounded ClassVariable slice; broader parity remains open.
- Flay/Reek repository/tag identity and locked Ruby are established; future output-parity evidence remains open.
- Ticket 02 proved only its named Ruby 4 newline-`&&` form and Spinel FFI declaration syntax; ticket 13 adds bounded ClassVariable/Flay behavior and reference parity, while broader grammar remains open.
- Real Rails corpus is pinned by ticket 14, but full parity is blocked: two namespaced ClassVariable inputs and 25 Flay inputs remain incomplete. Tickets 18–19 track closure. Release signing/runtime environment remains undecided.

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
