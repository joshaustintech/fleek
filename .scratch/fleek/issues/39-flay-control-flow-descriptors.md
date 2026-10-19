# 39: Describe Flay control-flow nodes and wrappers

**What to build:** Fleek preserves Flay candidate grouping and mass for supported method control flow, including Prism nodes that need a RubyParser wrapper adapter.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 36 — Describe scalar identity in Flay method candidates.

**Status:** open  
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [ ] Express supported branch and loop node structure through shared descriptors, with narrow adapters for verified synthetic Flay nodes.
- [ ] Match `if`/`unless`/`else`, `case`/`when`, `while`/`until`/`for`, and supported return, yield, and exception-flow forms against Flay 2.14.4.
- [ ] Match parent-dependent mass, grouping, score, locations, order, subtree pruning, and complete coverage.
- [ ] Keep unsupported control-flow shapes incomplete; focused mutations detect missing node and wrapper rules.
- [ ] Record each required Prism-to-RubyParser adapter in an ADR.
