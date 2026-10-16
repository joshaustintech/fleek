# 01: Default invocation and CWD scan

**Type:** task  
**Status:** resolved
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** A plain Fleek invocation analyzes the current working directory with pinned Flay and Reek defaults. Supported checks still report findings when other defaults are unsupported; the report names unsupported checks and stays incomplete.

**Blocked by:** None (can start immediately).

- [x] With no `--checks`, select every check enabled by default in Flay 2.14.4 and Reek 6.6.0; keep explicit `--checks` as a named subset.
- [x] With no path and no `--stdin`, scan CWD using recursive `.rb` discovery, skip hidden directories, reject directory symlinks, and preserve empty-scan failure behavior.
- [x] Report selected, run, disabled, and unsupported checks; unsupported enabled defaults keep status incomplete and exit 1.
- [x] Run supported checks and retain their findings alongside unsupported-check diagnostics.
- [x] Verify CLI behavior through the compiled process contract, including stdout, stderr, coverage, and exit status.

## Answer

No `--checks` selects all 29 checks enabled by the pinned Flay and Reek defaults. Fleek runs its two implemented checks, lists 27 unsupported defaults, and forces overall status to incomplete while retaining supported findings. A plain invocation scans CWD through the existing discovery rules; the compiled-process contract covers visible Ruby sources, hidden directories, directory symlinks, empty scans, diagnostics, and exit status. Explicit named selection remains unchanged. The full gate passed with 15 process contracts, all 95 mutations caught, Flay score 0, and Reek 0 warnings. ADR 0041 records the profile and coverage policy.
