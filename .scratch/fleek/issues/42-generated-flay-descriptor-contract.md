# 42: Generate Flay contracts for every supported descriptor

**What to build:** Every supported Prism-to-Flay descriptor has a deterministic public contract showing how Fleek and Flay classify its clean, finding, and boundary cases.

**Part of:** Ticket 22 — Flay method and expression parity.

**Blocked by:** 37 — Describe Flay method calls and argument trees; 38 — Describe Flay collection and destructuring nodes; 39 — Describe Flay control-flow nodes and wrappers; 40 — Describe Flay range and regular-expression values; 41 — Describe Flay method parameters with shared rules.

**Status:** resolved
**Type:** task  
**Category:** enhancement  
**Triage:** ready-for-agent

- [x] Generate bounded Ruby inputs from the supported descriptor inventory and compare the compiled CLI with unchanged Flay 2.14.4 for finding cases, plus clean and rejected-boundary cases.
- [x] Check group kind, mass, score, locations, ordering, and coverage for each generated case.
- [x] Make a missing descriptor or generated case fail deterministically; focused mutations prove the contract detects missing and incorrect rules.
- [x] Retain only fixed examples that explain a discovered mapping or uniquely protect a regression.

## Answer

The generated descriptor catalog now drives one bounded two-method Ruby fixture per supported Prism node and parameter descriptor. Each fixture runs through Fleek and unchanged Flay 2.14.4, comparing group kind, mass, score, exact locations and ordering, and complete coverage. Inventory parity fails when an implementation descriptor has no generated case or a case no longer maps to an implementation descriptor. Clean and unsupported-boundary controls remain, and focused support and mass mutants are caught.

Fixed fixtures remain where they protect additional identity or boundary behavior beyond the generated catalog.

See [ADR 0170](../../../docs/adr/0170-generated-flay-descriptor-contracts.md).
