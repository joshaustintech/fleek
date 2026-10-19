# 39: Describe Flay control-flow nodes and wrappers

**What to build:** Fleek preserves Flay candidate grouping and mass for supported method control flow, including Prism nodes that need a RubyParser wrapper adapter.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 36 — Describe scalar identity in Flay method candidates.

**Status:** resolved
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [x] Express supported branch and loop node structure through shared descriptors, with narrow adapters for verified synthetic Flay nodes.
- [x] Match `if`/`unless`/`else`, `case`/`when`, `while`/`until`/`for`, and supported return, yield, and exception-flow forms against Flay 2.14.4.
- [x] Match parent-dependent mass, grouping, score, locations, order, subtree pruning, and complete coverage.
- [x] Keep unsupported control-flow shapes incomplete; focused mutations detect missing node and wrapper rules.
- [x] Record each required Prism-to-RubyParser adapter in an ADR.

## Answer

Focused compiled-CLI contracts compare branch, case, loop, return, yield, rescue/retry, and ensure behavior with pinned Flay 2.14.4, including clean coverage when `when` condition-list lengths differ. All focused control-flow mutations were caught; the full gate passed 55 workers with eight mutation workers, Flay score 0, and Reek warnings 0. ADR 0167 records the `when` wrapper adapter and focused contract boundaries.
