# 44: Validate local ticket documents

**What to build:** Local tickets follow one consistent tracker format, and malformed ticket references are caught before the docs are committed.

**Blocked by:** None (can start immediately).

**Status:** open  
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [ ] Align the local ticket template and tracker guidance on lifecycle status, triage state, and required fields.
- [ ] Add a deterministic repository check for filename/heading number mismatches, required fields, invalid triage values, missing blocker references, and dependency cycles.
- [ ] Run the check against existing local tickets and correct any violations it finds.
- [ ] Wire the check into the established repository gate without adding a new runtime dependency.
- [ ] Prove the check fails for representative malformed tickets and passes for the current tracker.
