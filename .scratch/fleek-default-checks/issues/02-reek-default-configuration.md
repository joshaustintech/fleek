# 02: Reek default configuration

**Type:** task  
**Status:** resolved
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** Reek defaults honor existing configuration and exclusion behavior. Explicitly disabled default detectors appear as disabled, while enabled checks Fleek cannot run remain listed as unsupported.

**Blocked by:** 01: Default invocation and CWD scan.

- [x] Preserve existing Reek config discovery, explicit config selection, precedence, settings, and exclusions for default mode.
- [x] Honor `enabled: false` for a default detector and identify it as disabled by config.
- [x] Match pinned Reek detector enablement precedence, including opt-in detectors enabled by config and explicit `--checks` selection.
- [x] Ensure exclusions do not hide unsupported enabled defaults from coverage reporting.
- [x] Compare observable config behavior against pinned Reek 6.6.0 with real files and config.

**Evidence:** `make check` passed (Spinel 3,596 tests; Fleek 17 process contracts; 97 mutants killed; Flay 0; Reek 0). Standards and specification reviews passed. Decision recorded in [ADR 0042](../../../docs/adr/0042-configured-default-check-profile.md).
