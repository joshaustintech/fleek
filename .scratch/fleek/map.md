# Fleek

## Notes

- Canonical project specification is `spec.md`; detailed slice specifications are linked from it.
- One local Markdown issue per ticket in `issues/`, numbered globally in dependency order.
- Category `enhancement`; triage state `ready-for-agent` until completion. `Status` tracks open/claimed/resolved workflow.
- Triage comments begin with the required AI disclaimer.
- Tickets 01–05 resolved and pushed in order; continue one passing ticket per commit.

## Decisions-so-far

- Native combined Flay/Reek replacement; pinned Spinel compiler; Ruby 4.0 and pinned Spinel source input; standalone macOS arm64 release.
- Primary test seam: compiled CLI process. Parser feasibility uses a temporary real native probe.
- Ticket sequence and dependencies in issue bodies; summary: 01 compiler/reference harness → 02 parser → 03–08 smell/input/config/text → 09–12 duplication/combined report → 13–14 language/Rails parity → 15–17 runtime/release.
- Research notes and ADRs link from `spec.md` and project documentation.

## Fog

- Native analyzer coverage starts with tickets 03–04's bounded ClassVariable slice; broader parity remains open.
- Flay/Reek repository/tag identity and locked Ruby are established; future output-parity evidence remains open.
- Ticket 02 proved only its named Ruby 4 newline-`&&` form and Spinel FFI declaration syntax. AST fidelity, broad grammar, and analyzer parity remain open.
- Real Rails corpus and release signing/runtime environment are undecided.

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
