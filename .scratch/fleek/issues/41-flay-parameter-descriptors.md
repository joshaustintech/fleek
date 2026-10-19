# 41: Describe Flay method parameters with shared rules

**What to build:** Fleek matches Flay's method grouping when supported parameter names, defaults, and parameter shapes are identical or differ.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 37 — Describe Flay method calls and argument trees.

**Status:** resolved
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [x] Express supported positional, optional, post, keyword, rest, keyword-rest, block, and block-optional parameter rules through shared descriptors.
- [x] Match parameter support, default identity, parameter mass, optional-count boundaries, and similar-versus-identical grouping against unchanged Flay 2.14.4.
- [x] Preserve method locations, group score, order, and complete coverage for accepted forms; reject unsupported defaults explicitly.
- [x] Focused mutations detect missing parameter rules and mismatched names, defaults, counts, or mass; record major decisions in ADRs.

## Answer

Method and block parameter rules now share a Prism-indexed descriptor table. Focused compiled-CLI contracts verify Flay 2.14.4 mass, grouping, identity, optional counts, and unsupported array defaults. The method-body boundary test uses distinct bodies because shared qualifying subtrees remain explicitly incomplete under the existing partial-subtree policy. All 42 focused parameter mutants were caught with eight isolated workers. ADR 0169 records the descriptor rules and preserved positional/keyword default boundary.
