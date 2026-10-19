# 36: Describe scalar identity in Flay method candidates

**What to build:** Fleek distinguishes identical methods from similar methods when their supported scalar values or constant names differ, matching Flay 2.14.4.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** None (can start immediately).

**Status:** resolved
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [x] Express payload scalar identity rules in shared node descriptors; boolean and nil identity follows Prism node type.
- [x] Compare identical and differing integer, float, string, symbol, boolean, nil, constant-read, and constant-path values through the compiled CLI against unchanged Flay 2.14.4.
- [x] Preserve Flay mass, score, locations, ordering, and complete coverage for accepted forms; keep unsupported forms incomplete.
- [x] Focused mutations detect a missing or incorrect scalar identity rule.
- [x] Record any representation decision in an ADR.

## Answer

Implemented scalar identity metadata in the shared Prism node descriptors. Integer, float, string, symbol, constant-read, and constant-path payloads use one comparator; booleans and nil use their distinct Prism node types. Compiled CLI contracts compare matching and differing values with Flay 2.14.4, including distinct constant-path parents, and verify group kind, mass, score, ordered locations, and complete coverage. Optional defaults now use the same descriptor comparator; call-argument identity retains its focused contract.

ADR 0162 records the representation decision. Six descriptor identity mutations and focused optional-default mutations were caught. Full gate passed with pinned Spinel 2026.09.12: 49 workers, 8 mutation workers, Flay score 0, Reek 0. Standards and Spec code reviews passed.
