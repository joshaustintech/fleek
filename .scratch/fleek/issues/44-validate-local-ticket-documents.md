# 44: Validate local ticket documents

**What to build:** Local tickets follow one consistent tracker format, and malformed ticket references are caught before the docs are committed.

**Blocked by:** None (can start immediately).

**Status:** resolved
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [x] Align the local ticket template and tracker guidance on lifecycle status, triage state, and required fields.
- [x] Add a deterministic repository check for filename/heading number mismatches, required fields, invalid triage values, missing blocker references, and dependency cycles.
- [x] Run the check against existing local tickets and correct any violations it finds.
- [x] Wire the check into the established repository gate without adding a new runtime dependency.
- [x] Prove the check fails for representative malformed tickets and passes for the current tracker.

`make ticket-check` validates 54 tickets. The public Spinel contract rejects mismatched numbering, missing required metadata, invalid triage, missing blocker references, and cycles; a disabled-triage-validation mutant is caught. Normalized the older parallel-check ticket to the current fields. ADR 0164 records the graph and compatibility rules.
