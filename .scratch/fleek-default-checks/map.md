# Fleek default check behavior

## Notes

- Parent project: [Fleek](../fleek/map.md).
- Published spec: [spec.md](spec.md).
- The accepted policy is recorded in [ADR 0039](../../docs/adr/0039-default-checks-and-implicit-source-scope.md).
- Approved tickets live in [issues/](issues/), numbered in dependency order.

## Decisions-so-far

- No `--checks` selects all checks enabled by default in pinned Flay 2.14.4 and Reek 6.6.0.
- Reek 6.6.0 exposes 29 detectors; 28 are enabled by default. `UnusedPrivateMethod` is disabled by default. Flay 2.14.4 defaults to structural duplication with mass threshold 16.
- Existing config files control settings, exclusions, and Reek detector enablement according to pinned precedence; explicitly disabled detectors are shown as disabled.
- Unsupported enabled defaults are listed; supported checks still run, findings remain visible, overall status is incomplete.
- Explicit `--checks` remains a subset selector.
- No path and no `--stdin` scans the current working directory using existing recursive `.rb`, hidden-directory, and directory-symlink rules.
- Test through compiled CLI process seam; assert report, coverage, streams, and status.
- Default execution carries selection and coverage policy in a profile (ADR 0041); unsupported enabled checks force incomplete status.
- Ticket 01 is implemented and resolved; ticket 02 (Reek default configuration) is the next dependency frontier.
- `BUNDLE_PATH=<preinstalled-bundle> make flay reek` passes: Flay score 0; Reek 0 warnings.
- Approved ticket dependency chain: 01 default invocation → 02 config policy → 03–07 default detector groups → 08 complete default-profile parity. Opt-in detector behavior is covered by the full-parity spec and must not be duplicated here.

## Fog

- Enumerate exact enabled defaults from the pinned analyzer versions in the implementation contract and ensure reference cases cover them.
- This effort establishes pinned default selection and default detector coverage. Full all-detector parity, including opt-in behavior, is tracked in the parent Fleek parity specification and its issues; do not duplicate those implementation tickets here.
