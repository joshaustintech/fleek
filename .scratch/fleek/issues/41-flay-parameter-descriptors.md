# 41: Describe Flay method parameters with shared rules

**What to build:** Fleek matches Flay's method grouping when supported parameter names, defaults, and parameter shapes are identical or differ.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 37 — Describe Flay method calls and argument trees.

**Status:** open  
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [ ] Express supported positional, optional, post, keyword, rest, keyword-rest, block, and block-optional parameter rules through shared descriptors.
- [ ] Match parameter support, default identity, parameter mass, optional-count boundaries, and similar-versus-identical grouping against unchanged Flay 2.14.4.
- [ ] Preserve method locations, group score, order, and complete coverage for accepted forms; reject unsupported defaults explicitly.
- [ ] Focused mutations detect missing parameter rules and mismatched names, defaults, counts, or mass; record major decisions in ADRs.
