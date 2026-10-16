# 06: Reek data and size checks

**Type:** task  
**Status:** resolved
**Category:** enhancement  
**Triage:** ready-for-agent

**What to build:** Fleek reports Reek’s default data-shape and size findings with matching messages, locations, contexts, thresholds, configuration, and exclusions.

**Blocked by:** 01: Default invocation and CWD scan; 02: Reek default configuration.

- [x] Support DataClump, TooManyConstants, TooManyInstanceVariables, TooManyMethods, and TooManyStatements defaults.
- [x] Match pinned Reek 6.6.0 findings on shared supported syntax.
- [x] List unsupported syntax honestly and preserve supported findings with incomplete status.

## Answer

Added all five defaults with pinned thresholds, config exclusions, explicit selection, and bounded syntax reporting. Contracts compare fixtures against Reek 6.6.0 and mutations verify each detector remains observable. See ADR 0046.
