# 08: Complete default profile parity

**Type:** task  
**Status:** resolved
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** A default invocation runs every enabled pinned Reek and Flay check, with complete coverage on supported input and the same findings as the reference tools.

**Blocked by:** 02: Reek default configuration; 03: Reek object and scope checks; 04: Reek argument and method API checks; 05: Reek call and flow checks; 06: Reek data and size checks; 07: Reek naming checks.

- [x] Verify all 28 Reek defaults and Flay structural duplication are selected without `--checks`; verify opt-in detectors remain outside defaults unless pinned configuration or explicit selection enables them.
- [x] Compare findings, locations, ordering, metrics, configuration, and exclusions against pinned Flay 2.14.4 and Reek 6.6.0.
- [x] Verify a fully supported clean default run exits 0 and a fully supported run with findings exits 2.
- [x] Verify unsupported syntax remains incomplete and explicit `--checks` remains a subset.
- [x] Verify ordinary invocation scans CWD and preserves explicit path and named-stdin behavior.
