# 01: Default invocation and CWD scan

**Type:** task  
**Status:** open  
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** A plain Fleek invocation analyzes the current working directory with pinned Flay and Reek defaults. Supported checks still report findings when other defaults are unsupported; the report names unsupported checks and stays incomplete.

**Blocked by:** None (can start immediately).

- [ ] With no `--checks`, select every check enabled by default in Flay 2.14.4 and Reek 6.6.0; keep explicit `--checks` as a named subset.
- [ ] With no path and no `--stdin`, scan CWD using recursive `.rb` discovery, skip hidden directories, reject directory symlinks, and preserve empty-scan failure behavior.
- [ ] Report selected, run, disabled, and unsupported checks; unsupported enabled defaults keep status incomplete and exit 1.
- [ ] Run supported checks and retain their findings alongside unsupported-check diagnostics.
- [ ] Verify CLI behavior through the compiled process contract, including stdout, stderr, coverage, and exit status.
