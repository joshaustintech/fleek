# 119: Describe range and regexp identity in node descriptors

**What to build:** Move accepted Range and regexp value identity rules into the Prism-indexed method-body descriptor, so accepted node behavior is not split between descriptor data and node-type equality branches.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 52 — Finish descriptor and composed-method evidence.

**Status:** resolved
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

## Bounded cases

Describe the existing Range end-exclusion flag, static regexp pattern/options, and interpolated-regexp options/part-count identity in the node descriptor and shared equality dispatch. Keep child topology comparison, Flay mass, generated cases, and public output unchanged. Do not add syntax support or change Flay semantics.

## Starting evidence

Ticket 52 audit; ADRs 0160 and 0168; generated contracts in `test/duplication_generated_descriptor_contract.rb` and fixed range/regexp contracts.

## Acceptance criteria

- [x] Descriptor inventory continues to match the generated public cases.
- [x] Pinned Flay 2.14.4 and Fleek retain finding kind, identity classification, mass, score, locations, ordering, coverage, and normalized outcomes for Range and static/interpolated regexp cases.
- [x] Focused non-equivalent mutations detect missing descriptor identity fields or dispatch.
- [x] Full required gate and standards/spec reviews pass; Answer records exact commands and remaining links.

## Execution and stop condition

Keep this to descriptor data and equality dispatch for the three accepted node forms. Preserve current adapters and all unsupported boundaries. Use the pinned Spinel toolchain, write a failing public contract first, run focused mutations, then the full repository gate before committing. Stop when the descriptor inventory and public comparisons pass without changing findings.

## Answer

Added Range end-exclusion, static regexp pattern/options, and interpolated-regexp options/part-count identity to the Prism-indexed node descriptor. Shared equality dispatch consumes these rules; byte-string comparison is shared with string/symbol identity. The generated descriptor inventory now asserts all three identity kinds. Flay 2.14.4 report behavior is unchanged.

RED: pinned Spinel `-E test/duplication_generated_descriptor_contract.rb` failed with `generated Flay node descriptor omits RANGE identity for PM_RANGE_NODE`. GREEN: pinned range, regexp, regexp-boundary, and generated-descriptor contracts passed. Fourteen focused mutations caught descriptor support, identity, mass, pattern, and flags faults; four mutation workers passed.

Full gate: `FLEEK_DISABLE_MUTATION_CONTRACT_CACHE=true JOBS=4 make check` with Spinel 2026.09.12, Flay 2.14.4, and Reek 6.6.0 passed: 66 workers, four mutation workers, Flay score 0, Reek warnings 0. Standards review found no violations or remaining smells; spec review found no gaps or scope creep. No residual issues remain for Ticket 119; parent Ticket 22 remains open for its other acceptance criteria.
