# 02: Reek default configuration

**Type:** task  
**Status:** open  
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** Reek defaults honor existing configuration and exclusion behavior. Explicitly disabled default detectors appear as disabled, while enabled checks Fleek cannot run remain listed as unsupported.

**Blocked by:** 01: Default invocation and CWD scan.

- [ ] Preserve existing Reek config discovery, explicit config selection, precedence, settings, and exclusions for default mode.
- [ ] Honor `enabled: false` for a default detector and identify it as disabled by config.
- [ ] Match pinned Reek detector enablement precedence, including opt-in detectors enabled by config and explicit `--checks` selection.
- [ ] Ensure exclusions do not hide unsupported enabled defaults from coverage reporting.
- [ ] Compare observable config behavior against pinned Reek 6.6.0 with real files and config.
