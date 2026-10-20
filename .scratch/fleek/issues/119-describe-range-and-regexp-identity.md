# 119: Describe range and regexp identity in node descriptors

**What to build:** Move accepted Range and regexp value identity rules into the Prism-indexed method-body descriptor, so accepted node behavior is not split between descriptor data and node-type equality branches.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 52 — Finish descriptor and composed-method evidence.

**Status:** open
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

## Bounded cases

Describe the existing Range end-exclusion flag, static regexp pattern/options, and interpolated-regexp options/part-count identity in the node descriptor and shared equality dispatch. Keep child topology comparison, Flay mass, generated cases, and public output unchanged. Do not add syntax support or change Flay semantics.

## Starting evidence

Ticket 52 audit; ADRs 0160 and 0168; generated contracts in `test/duplication_generated_descriptor_contract.rb` and fixed range/regexp contracts.

## Acceptance criteria

- [ ] Descriptor inventory continues to match the generated public cases.
- [ ] Pinned Flay 2.14.4 and Fleek retain finding kind, identity classification, mass, score, locations, ordering, coverage, and normalized outcomes for Range and static/interpolated regexp cases.
- [ ] Focused non-equivalent mutations detect missing descriptor identity fields or dispatch.
- [ ] Full required gate and standards/spec reviews pass; Answer records exact commands and remaining links.

## Execution and stop condition

Keep this to descriptor data and equality dispatch for the three accepted node forms. Preserve current adapters and all unsupported boundaries. Use the pinned Spinel toolchain, write a failing public contract first, run focused mutations, then the full repository gate before committing. Stop when the descriptor inventory and public comparisons pass without changing findings.
