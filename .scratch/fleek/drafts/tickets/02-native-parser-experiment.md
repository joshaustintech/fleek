# 02: Native parser experiment

**What to build:** A developer can run a small standalone native probe that parses representative Ruby 4.0 and pinned Spinel source and reports original diagnostics/locations without executing source. Parent specification: Native foundation.

**Blocked by:** 01 Native CLI and reference harness.

**Status:** open
**Publication:** draft; proposed triage ready-for-agent after review.

- [ ] Select a candidate native parser from verified versioned API, grammar, and license evidence; compile a minimal adapter under the pinned compiler without changing its pin.
- [ ] Prove explicit Ruby 4.0 grammar selection and representative documented Spinel extensions; invalid or unsupported examples fail honestly. Record the exact demonstrated syntax boundary.
- [ ] Verify original byte offsets/lines, comments, length handling, ownership/destruction, and deterministic repeated parsing with actual native execution.
- [ ] Source containing requires, FFI declarations, or executable side effects is inspected without loading dependencies or executing it.
- [ ] Native linkage and a runtime without Ruby/original tools demonstrate independence; the probe reports parsing only, never that an analysis check passed.
- [ ] Record compiled/runtime evidence and parser choice; a failed experiment remains unresolved. Preserve test-first and required quality/mutation gates.
