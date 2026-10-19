# 42: Generate Flay contracts for every supported descriptor

**What to build:** Every supported Prism-to-Flay descriptor has a deterministic public contract showing how Fleek and Flay classify its clean, finding, and boundary cases.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 37 — Describe Flay method calls and argument trees; 38 — Describe Flay collection and destructuring nodes; 39 — Describe Flay control-flow nodes and wrappers; 40 — Describe Flay range and regular-expression values; 41 — Describe Flay method parameters with shared rules.

**Status:** open  
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [ ] Generate bounded Ruby inputs from the supported descriptor inventory and compare the compiled CLI with unchanged Flay 2.14.4 for clean, finding, and rejected-boundary cases.
- [ ] Check group kind, mass, score, locations, ordering, and coverage for each generated case.
- [ ] Make a missing descriptor or generated case fail deterministically; focused mutations prove the contract detects missing and incorrect rules.
- [ ] Retain only fixed examples that explain a discovered mapping or uniquely protect a regression.
