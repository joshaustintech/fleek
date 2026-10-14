# 03: First ClassVariable finding

**What to build:** A developer explicitly selects ClassVariable and receives a real reference-equivalent finding for a supported simple class, or an honest clean/error result. Parent specification: Smell analysis and source workflow.

**Blocked by:** 02 Native parser experiment.

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] Run the real parser and detector through the native CLI for an explicit Ruby file and supported ClassVariable selection.
- [ ] One class-variable assignment yields the pinned Reek name, context, message, and location; a clean example yields no findings.
- [ ] Complete clean/finding results exit 0/2. Invalid source, unknown/unsupported selections, and omitted selection that would silently narrow defaults exit 1.
- [ ] Reject syntax/context capabilities not yet implemented instead of silently skipping them. Comments and strings alone do not count as class-variable code.
- [ ] Show checks run and completion truthfully, even before the final stable text layout is introduced.
- [ ] Execute unchanged-reference comparison, failing regression first, and mutations for omitted finding, false positive, wrong location, and wrong status; pass required gates.
